# Audio Visualizer (Omarchy shell plugin)

Animated sound bars in the Omarchy bar, driven by [cava](https://github.com/karlstav/cava).

- Moves with whatever PipeWire is playing: music (MPD/rmpc), YouTube in the
  browser, anything.
- cava runs only while a media player reports that it is playing (MPRIS) and
  shell animations are on (`omarchy toggle animations`); otherwise the widget
  hides (or shows dim bars with `hideWhenIdle: false`).
- Click opens rmpc (`omarchy-launch-or-focus-tui rmpc`); right-click opens its
  settings in the Spotify Downloader panel's Settings tab.

Looks like YASB's cava widget: flat bars (or a smooth wave) at 60 fps, filled
with a loudness gradient from the current Omarchy theme (bright cyan → blue →
bright magenta), updating when the theme changes.

Settings (`shell.json` widget entry or the settings panel): `style`
(`bars`, `bars_mirrored`, `waves`, `waves_mirrored`), `bars` (default 10),
`barWidth` (4), `barSpacing` (2), `height` (% of the bar, 60), `gradient`
(true), `colors` (custom `#quiet,#mid,#loud`), `hideWhenIdle` (true).

Requires `cava` (`omarchy pkg add cava`).

## Install

```bash
omarchy pkg add cava
omarchy plugin add https://github.com/specialkapa/omarchy-visualizer.git --enable --yes
```

Then add `"specialkapa.visualizer"` to a bar section in `~/.config/omarchy/shell.json`
(next to the media widget looks best).

MIT licensed. See [LICENSE](LICENSE).

Tests: `node tests/logic.test.cjs`
