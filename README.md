# Multi Codex Pets

Multi Codex Pets is a small macOS menu bar app for showing more than one
Codex-compatible pet at the same time.

It is standalone: it does not modify Codex, patch Codex, or copy Codex app
files into this repo.

## What It Does

- Shows multiple floating, draggable pets at once.
- Lets you choose exactly which pets are visible from a menu bar checklist.
- Shows small preview images in the pet checklist.
- Can slowly roam visible pets around the screen and bounce them off edges.
- Can show Codex's built-in pets when the Codex app is installed locally.
- Can load your custom pet packages from `${CODEX_HOME:-$HOME/.codex}/pets`.
- Supports the Codex pet atlas contract: `1536x1872`, `8 x 9`, `192x208` cells.
- Ships with no pet art, telemetry, networking, or user-specific data.

## Requirements

- macOS 14 or newer.
- Xcode Command Line Tools or a Swift toolchain.
- Codex installed locally if you want the built-in Codex pets.

## Quick Start

```bash
git clone <repo-url>
cd multi-codex-pets
./script/build_and_run.sh
```

The app appears in the macOS menu bar. Use `Visible Pets` to choose which pets
are shown, `Walk Around` to let them roam, `Animation` to pick an animation
state, and `Scale` to resize them.

The run script builds a local app bundle at `dist/MultiCodexPets.app` and starts
it. `dist/` and Swift build output are ignored by git.

Useful commands:

```bash
swift test
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
```

## Built-In Codex Pets

The app asks macOS where `com.openai.codex` is installed. If you need to point
it somewhere else, set:

```bash
CODEX_APP_PATH=/path/to/Codex.app ./script/build_and_run.sh
```

Codex's built-in pet spritesheets are read from your local Codex app at runtime.
They are not copied into this repository and are not licensed by this project.

## Custom Pets

Each pet package should live in its own folder:

```text
~/.codex/pets/my-pet/
  pet.json
  spritesheet.webp
```

Example manifest:

```json
{
  "id": "my-pet",
  "displayName": "My Pet",
  "description": "A tiny companion.",
  "spritesheetPath": "spritesheet.webp"
}
```

The spritesheet must be PNG or WebP and exactly `1536x1872`.

To use a different Codex home directory:

```bash
CODEX_HOME=/path/to/codex-home ./script/build_and_run.sh
```

## Privacy

This app has no networking, telemetry, or bundled user data. It only reads local
pet packages from your Codex home directory and, when available, local
spritesheets from your installed Codex app.

## Development

Before opening a pull request, run:

```bash
swift format --in-place --recursive Package.swift Sources Tests
swift test
./script/build_and_run.sh --verify
```

Do not commit generated build output, app bundles, personal pet assets, or
Codex app assets.

## License

MIT. See `LICENSE`.
