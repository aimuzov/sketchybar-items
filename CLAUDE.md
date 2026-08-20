# CLAUDE.md — sketchybar-items

## What this is

A collection of self-contained items for sketchybar on SbarLua. Not a bar configuration: each file
under `items/` adds one item to a bar the user already has, and can be copied out on its own.

The items were extracted from a personal sketchybar config. The line is what an item is worth
outside that config: anything another bar could use lives here, and what stays behind is the bar
itself — its height and position, the palette, the order the items are required in.

Most of these have no obvious equivalent elsewhere (skhd mode, SketchyVim mode, yabai window
state) or carry detail worth keeping: spaces with app glyphs, tailscale state, a caffeinate toggle
that kills its own process rather than every caffeinate on the machine. The clock and the battery
are ordinary by comparison, and they are here so that a bar can be built out of this repository
alone instead of half of it.

## Layout

```
items/            one file per item, each guarded by its own dependency check
helpers.lua       safe_exec / has / bin / has_all / has_font / wait_for_yabai / once /
                  ensure_yabai_signal
theme.lua         default palette, merged with the user's config.lua if there is one
config.example.lua  what a user config may override
tests/run.lua     loads every item against stubbed sketchybar and helpers
```

## The contract every item follows

1. `require("sketchybar")`, `require("helpers")`, and `require("theme")` when it needs colours.
2. Check its tools first, and `return false` when they are missing — **not** `nil`: a module that
   returns nil makes `require` hand back `true`, which reads as success. Returning false lets a
   config write `require("items.x")` unconditionally and still test the result. An item that
   watches nothing — `datetime` is the only one — has no check to make and always draws.
3. Declare what it needs before it can be told anything: a custom event through
   `sbar.add("event", ...)`, a yabai signal through `helpers.ensure_yabai_signal`. Both go behind
   `helpers.once`, since several items ask for the same ones.
4. Add its item, subscribe, `return` the item.

## Conventions

- macOS only, Lua 5.4+. Code and comments in English.
- Comment what the code cannot say: why an event exists, why a path is resolved rather than
  assumed, what a magic value from yabai means.
- No dependency beyond what the item watches. `jq` is listed as a dependency where a query is
  parsed with it.

## Traps already hit (do not re-discover these)

- **launchd gives sketchybar a short PATH** (`/opt/homebrew/bin`, `/opt/homebrew/sbin`, and the
  system directories). Anything installed elsewhere — the tailscale CLI in `/usr/local/bin`, tools
  under mise — is invisible to `io.popen` unless the PATH is put back. Lua cannot export into its
  own environment, so `helpers.safe_exec` prefixes every command with `PATH='…'`.
- **A module returning nil is indistinguishable from success.** See the contract above.
- **`stack-index` is 0 for an unstacked window**, so the stack badge must test for `> 0` rather than
  for a number being present.
- **yabai answers queries only once it has started**, and sketchybar usually wins the race. Items
  that query at load time call `helpers.wait_for_yabai()` first, otherwise the bar is built from
  zero spaces and stays that way until a reload.
- **App glyphs are a font, not text.** Without sketchybar-app-font installed every window renders as
  a tofu box, so `yabai_spaces` checks for the font and falls back to the space label.
- **yabai keeps duplicate signals.** Adding the same signal twice gives two of them, and the bar is
  reloaded often, so `helpers.ensure_yabai_signal` removes its label before adding it.
- **`safe_exec` collapses whitespace** on the way out (`gsub("%s+", "")`). Anything matched against
  its result has to be matched without the spaces: pmset's "AC Power" arrives as `ACPower`.

## Testing

```sh
lua tests/run.lua
```

`tests/run.lua` stubs `sketchybar` (recording what was added) and `helpers` (declaring which tools
are "installed"), then loads each item twice — with its tools and without — and asserts both
directions. Nothing real is required: no bar, no yabai, no skhd.
