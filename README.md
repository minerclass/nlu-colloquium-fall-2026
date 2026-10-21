# Pedagogical Friction: Fall 2026 Doctoral Colloquium

A 15-minute HTML presentation for the Student and Alumni Research Presentations session of the NLU Teaching and
Learning Fall 2026 Doctoral Colloquium (Saturday, November 7, 2026, 2:30 to 4:00 PM, Room 463). Slides are due
to the session moderator by Monday, November 2.

The study is approved as exempt by the NLU IRB (protocol ER01884). The deck reports research in progress and no
findings. It contains no participant information and no recruitment request.

## Files

| Path | What it is |
|---|---|
| `index.html` | The deck. Open it in Chrome, Edge, or Safari. No build step |
| `assets/draft-and-defense.mp4` | Intro clip, 18 seconds, no audio: a doctoral student, an AI draft, and a defense question |
| `assets/twenty-eight-essays.mp4` | Teacher clip, 18 seconds, no audio: a teacher redesigns a task, and the system makes room |
| `assets/*.html` | The scene sources for each clip. Open one with `#seconds` (for example `#9.5`) to preview a moment |
| `tools/render-video.swift` | Renders a scene page frame by frame into an MP4 with WebKit and AVFoundation |
| `private/` (not in Git) | Speaker notes (`speaker-notes.js`) and a printable notes page (`speaker-notes.html`). Kept local on purpose |

Keep `assets/` beside `index.html` when you copy or zip the folder. Leave `private/` out of any zip you send to someone else. The people, essays, and messages in the clips
are illustrations, not study data.

## Presenter controls

| Key | Action |
|---|---|
| Right arrow, Space, Page Down | Next build, then next slide |
| Left arrow, Page Up | Back one build or slide |
| `A` | Show every build on the current slide |
| `N` | Speaker notes, with a target time per slide. Notes load only from a local copy (a file on this computer or localhost); the published site shows a short placeholder instead |
| `O` | Slide overview |
| `F` | Fullscreen |
| `T` / Shift+`T` | Start or pause the 15-minute timer / reset it. It turns gold at 13:00 and red at 15:00 |
| `Esc` | Close notes, overview, or the video player |

Slides 3, 4, 5, 6, and 8 have click-to-open panels. The title slide plays both clips, and slide 6 replays the
teacher clip. Print (Cmd+P) lays out one slide per landscape page with every build shown.

## Re-render a clip

```sh
swiftc -O tools/render-video.swift -o /tmp/render-video
/tmp/render-video assets/draft-and-defense.html assets/draft-and-defense.mp4 18 30
```

## Sources

Wording for the purpose, research questions, framework, and contributions comes from the defended Chapters 1 to 3
proposal (August 13, 2026). Participant limits come from the IRB-approved packet. The reference slide entries were
checked with `apa-agent/verify_references.py` on October 21, 2026: 4 DOIs, 0 errors, 0 warnings.
