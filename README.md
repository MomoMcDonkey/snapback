<!-- Replace YOUR_USERNAME in the demo button with your itch.io username. -->

# Snapback

**One boomerang. Three coins. Find your angle.**

A small pixel-art puzzle game about lining up the perfect throw. Pull back, follow the dotted trajectory, and use ricochets to collect every coin while avoiding lava.

[![Play the demo](https://img.shields.io/badge/PLAY_THE_DEMO-FA5C5C?style=for-the-badge&logo=itchdotio&logoColor=white)](https://YOUR_USERNAME.itch.io/snapback)

*Play in your browser—no download required.*

## Gameplay

Collect all **three coins** to clear a level. Each level has a one-throw solution, but finding the right angle and power is the challenge.

- **10 levels** with increasingly tricky routes.
- **Dotted aiming preview** to plan your throw.
- **Stone blocks** for extra bank shots.
- **Lava hazards** that reset the current level.
- **Selectable costumes** with a saved outfit choice.

<!-- Add a screenshot or GIF here after saving it in your repository:
![Snapback gameplay](docs/gameplay.gif)
-->

## Controls

| Action | Control |
| --- | --- |
| Aim and charge | Click the boomerang and drag |
| Throw | Release the mouse button |
| Return to the home screen | Escape or the back button |
| Change costume | Costume button on the home screen |

The boomerang launches opposite your pull direction. While charging, it cannot collect coins or take lava damage. Collecting the final coin secures the win immediately.

## Run locally

1. Download or clone this repository.
2. Open **Godot 4.6.1** and import `project.godot`.
3. Press **F5** to start from the home screen.

## Project layout

```text
assets/             Sprites and fonts
scenes/             Game, menus, HUD, and reusable objects
scenes/levels/      Individual level layouts
scripts/            Gameplay and UI scripts
project.godot       Godot project configuration
export_presets.cfg  Web export preset
```

## Build for the web

1. Install the matching Godot export templates.
2. Open **Project → Export → itch.io Web**.
3. Export a release build as `index.html` into an empty folder.
4. ZIP that folder's contents and upload it to itch.io as an HTML game.

## Credits

- **Game and artwork:** YOUR_NAME
- **Fonts and other third-party assets:** ADD_AUTHORS_AND_LICENSES

## License

YOUR_LICENSE_HERE

<!-- Replace the license placeholder with your chosen terms and add a LICENSE file. -->
