// Renders a scene page frame by frame into a silent H.264 MP4.
// The page must define a global render(seconds) function.
//
// Build:  swiftc -O tools/render-video.swift -o /tmp/render-video
// Run:    /tmp/render-video assets/draft-and-defense.html assets/draft-and-defense.mp4 18 [30]
import AVFoundation
import Cocoa
import WebKit

let args = CommandLine.arguments
guard args.count >= 4, let seconds = Double(args[3]) else {
    print("usage: render-video <scene.html> <out.mp4> <seconds> [fps]")
    exit(2)
}
let htmlPath = args[1]
let outPath = args[2]
let fps = args.count > 4 ? Int(args[4]) ?? 30 : 30
let width = 1920, height = 1080

final class Renderer: NSObject, WKNavigationDelegate {
    let web: WKWebView
    let window: NSWindow
    let total: Int
    var frame = 0
    var writer: AVAssetWriter!
    var input: AVAssetWriterInput!
    var adaptor: AVAssetWriterInputPixelBufferAdaptor!

    init(total: Int) {
        self.total = total
        web = WKWebView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                          styleMask: [.borderless], backing: .buffered, defer: false)
        super.init()
        window.contentView = web
        window.alphaValue = 0.01
        window.ignoresMouseEvents = true
        window.orderFrontRegardless()
        web.navigationDelegate = self
    }

    func start() {
        let url = URL(fileURLWithPath: htmlPath)
        web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        setUpWriter()
        renderNext()
    }

    func setUpWriter() {
        let url = URL(fileURLWithPath: outPath)
        try? FileManager.default.removeItem(at: url)
        writer = try! AVAssetWriter(outputURL: url, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            ],
        ]
        input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
        ])
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
    }

    func renderNext() {
        if frame >= total { finish(); return }
        let t = Double(frame) / Double(fps)
        web.evaluateJavaScript("render(\(t)); 1") { _, error in
            if let error = error { print("render(\(t)) failed: \(error)"); exit(1) }
            let config = WKSnapshotConfiguration()
            config.rect = NSRect(x: 0, y: 0, width: width, height: height)
            config.afterScreenUpdates = true
            self.web.takeSnapshot(with: config) { image, error in
                guard let image = image else { print("snapshot failed: \(String(describing: error))"); exit(1) }
                self.append(image)
                self.frame += 1
                if self.frame % 90 == 0 { print("frame \(self.frame) of \(self.total)") }
                DispatchQueue.main.async { self.renderNext() }
            }
        }
    }

    func append(_ image: NSImage) {
        while !input.isReadyForMoreMediaData { RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.005)) }
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
        guard let pb = buffer else { print("no pixel buffer"); exit(1) }
        CVPixelBufferLockBaseAddress(pb, [])
        let ctx = CGContext(data: CVPixelBufferGetBaseAddress(pb), width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(pb), space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        var rect = CGRect(x: 0, y: 0, width: width, height: height)
        let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(pb, [])
        adaptor.append(pb, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: CMTimeScale(fps)))
    }

    func finish() {
        input.markAsFinished()
        writer.finishWriting {
            print("wrote \(outPath): \(self.total) frames, status \(self.writer.status.rawValue)")
            if let error = self.writer.error { print(error) }
            exit(self.writer.status == .completed ? 0 : 1)
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let renderer = Renderer(total: Int(seconds * Double(fps)))
renderer.start()
app.run()
