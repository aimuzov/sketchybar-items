# sketchybar-items

Ready-made items for [sketchybar](https://github.com/FelixKratz/SketchyBar) on
[SbarLua](https://github.com/FelixKratz/SbarLua) — the ones that are hard to find elsewhere:
the current skhd mode, the SketchyVim mode, what yabai is doing with the focused window.

This is not a bar configuration. Every file under `items/` is one self-contained item that you drop
into a bar you already have.

## The items

| Item | Shows | Needs |
| --- | --- | --- |
| `items/skhd_mode` | which modal skhd mode is active, as a coloured badge | `skhd` |
| `items/svim_mode` | the SketchyVim mode, and the command line while typing one | `svim` |
| `items/keyboard_layout` | the current keyboard layout | `im-select` |
| `items/input` | layout and SketchyVim mode in one badge | `im-select` and/or `svim` |
| `items/yabai_window` | floating, zoomed, or "2 / 4" for a window in a stack | `yabai`, `jq` |
| `items/yabai_spaces` | one entry per space with the apps on it, clickable | `yabai`, `jq` |
| `items/tailscale` | whether tailscale is up, down or waiting for a login | `tailscale`, `jq` |

**An item whose tools are missing does not draw anything.** It returns `false` instead of raising,
so a config can require it unconditionally: a machine without skhd simply gets a shorter bar, not a
broken one, and not a badge stuck on its "unknown" icon.

## Install

Copy the files into your sketchybar config directory (`~/.config/sketchybar` by default):

```sh
git clone https://github.com/aimuzov/sketchybar-items /tmp/sketchybar-items
cp -R /tmp/sketchybar-items/items /tmp/sketchybar-items/helpers.lua /tmp/sketchybar-items/theme.lua \
      ~/.config/sketchybar/
```

Then require what you want, wherever you build your bar:

```lua
require("items.yabai_spaces")
require("items.skhd_mode")
require("items.yabai_window")

require("items.tailscale")
require("items.input")
```

The order of the `require` calls is the order the items appear in the bar, left to right for
`position = "left"` items and right to left for `position = "right"` ones.

## Colours

`theme.lua` carries a full palette (Catppuccin Macchiato) so the items look right with no setup at
all. To use your own, put a `config.lua` next to your `sketchybarrc`:

```lua
return {
    colors = { magenta = 0xffb4befe },
    app_font = "sketchybar-app-font",
}
```

Whatever it names is merged over the defaults; everything it leaves out keeps the default value.
See `config.example.lua`.

## Notes worth knowing

- **PATH.** launchd starts sketchybar with homebrew and the system directories only, so tools
  installed anywhere else are invisible to it — the tailscale CLI in `/usr/local/bin`, anything
  under mise. `helpers.lua` puts a fuller PATH in front of every command it runs, which is why the
  items can find these without hardcoded paths.
- **skhd and SketchyVim push, they are not polled.** Both items listen for an event. For skhd, add
  the trigger to your modes in `skhdrc`:

  ```
  :: window @ : sketchybar --trigger skhd_mode_update MODE=window
  :: default  : sketchybar --trigger skhd_mode_update MODE=
  ```

  SketchyVim triggers `svim_update` itself.
- **The keyboard layout is event-driven too.** macOS posts
  `AppleSelectedInputSourcesChangedNotification`, which sketchybar subscribes to directly; nothing
  runs on a timer.
- **App glyphs need a font.** `items/yabai_spaces` draws windows with
  [sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font). Without it installed the
  space falls back to the label yabai gave it, instead of a row of tofu boxes.

## Tests

```sh
lua tests/run.lua
```

The suite loads every item with `sketchybar` and `helpers` stubbed out, so it needs neither a
running bar nor any of the tools the items watch. It checks both directions: that an item draws
when its tools are there, and that it steps aside when they are not.

## License

[MIT](LICENSE)
