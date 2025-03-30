# BAR_Debug_Developer_Widget
BAR_Debug_Developer_Widget

## Overview

The Developer Debug Menu Widget is a powerful tool for game developers working with the Spring Engine, specifically designed to aid in debugging and testing various game scenarios. This widget allows you to dynamically spawn units, manipulate game states, and set up complex unit formations with ease.

## Features

- **Spawn Units:** Quickly spawn predefined units at a location on the map.
- **Cheat Controls:** Easily toggle cheats such as god mode, no cost, and no fog of war.
- **Formation Tools:** Position units in strategic formations like circle, pizza, W, and diamond.
- **Dynamic Configuration:** Adjust parameters like formation size, angle, and direction dynamically.
- **Interactive UI:** A clickable menu for activating/deactivating features and commands.

## Installation

1. Download the widget file.
2. Place it in your Spring `LuaUI/Widgets` directory.
3. Enable the widget from the Spring game interface under `LuaUI Widgets`.

## Usage

Upon loading the widget, you will see a menu on the right side of your game screen. Each button in the menu corresponds to a feature or functionality:

- **Cheat:** Toggle cheat mode on/off.
- **No Cost:** Toggle free unit spawning (no resources needed).
- **God Mode:** Toggle invulnerability for units.
- **No Fog:** Toggle visibility of the entire map.
- **Spawn Level 10 Commander:** Click on the map to place a level 10 commander.
- **Spawn Advanced Construction Vehicle:** Click on the map to place an advanced construction vehicle.
- **Circle Formation:** Select units and place them in a circle at a clicked location.
- **Pizza Formation:** Select units to form a 'pizza slice' formation.
- **W Formation:** Arrange selected units in a 'W' shape.
- **Diamond Formation:** Setup a diamond formation ideal for flanking maneuvers.

### Key Commands

- **M:** Toggle visibility of the debug menu.
- **ESC:** Cancel the current spawn or formation setup.
- **Q/E:** Rotate the formation left/right (active during formation setups).
- **F:** Toggle filling sides of the pizza slice (active during pizza formation setup).

### Example Use Cases

- **Testing Unit Behaviors:** Quickly spawn units to test interaction and AI behaviors.
- **Scenario Setup:** Easily setup complex battle scenarios for testing game balance and unit effectiveness.
- **Debugging:** Use the cheat modes to isolate issues in game mechanics or unit properties.

## Development

This widget is open-source and can be modified or extended. Developers are encouraged to contribute to its development by submitting pull requests with improvements or bug fixes.

## Version History

- **3.1:** Latest release with extended formation options and UI improvements.
- **Earlier versions:** Basic spawn and cheat functionalities.

## License

This widget is released under the GNU General Public License v2.0 or later. It is free to be used, modified, and distributed according to the terms of the GPL.

## Contact

For bugs, features, or general inquiries, please contact the author:
- **Name:** Justin H.
- **Email:** justinshagerty@gmail.com


Enjoy enhancing your game development and testing process with the Developer Debug Menu Widget!