VULCHAN'S COMBAT TEXT 0.4.14

INSTALL
1. Close Azeroth Survivors.
2. Replace the existing VulchansCombatText folder in AddOns with this folder.
3. Launch the game and start a run.

MOVE THE COMBAT TEXT
Hold CTRL to reveal an outlined drag area fitted to the current layout. In vertical mode it is tall and narrow; in horizontal mode it is wide and shallow. Then
left-click and drag anywhere inside the outlined area. The combat text follows
as you move it. Release the mouse button to save the position. The drag area
only accepts mouse input while CTRL is held, so normal gameplay clicks are
unaffected.

LAYOUT
/vct vertical     Stack numbers vertically (default).
/vct horizontal   Arrange numbers horizontally with enough spacing to keep hits readable.

SCALING
/vct scale 50     Set overall size to 50%.
/vct scale 75     Set overall size to 75%.
/vct scale 100    Restore normal size (default).
/vct scale 125    Set overall size to 125%.
/vct scale 150    Set overall size to 150%.
/vct scale 200    Set overall size to 200%.
Scaling applies to damage numbers, spell icons, spacing, and animation distance.
The setting is saved between sessions. Valid values are 50-200.

OTHER COMMANDS
/vct on
/vct off
/vct test
/vct icons on
/vct icons off
/vct iconsize 22
/vct scale 100
/vct reset

NOTES
- This is standalone and does not load or alter Survivor UI.
- Position and layout are saved in VCTDB between sessions.
- Spell icons are resolved from the player's spellbook. If a spell is not in the
  spellbook or the message format does not identify its source, the number remains
  visible without an icon.
- Incoming damage has no source spell name in the classic COMBAT_TEXT_UPDATE event,
  so it intentionally has no source icon in this version.

0.4.0 CHANGES
- Hold CTRL and left-click-drag to reposition the combat text. Position persists.
- Added /vct horizontal and /vct vertical layout commands. Layout persists.

0.4.1 CHANGES
- Added overall scaling from 50% to 200% with /vct scale <percent>.
- Scales damage numbers, icons, spacing, and animation distance together.
- Scale is saved in VCTDB and restored automatically.


0.4.2 CHANGES
- Added a visible, large positioning area while CTRL is held.
- Players can grab anywhere inside the outlined area, not just on a number.
- Combat text now follows the drag surface live while repositioning.

0.4.5 CHANGES
- Reworked drag positioning to use the center of the drag surface as the saved anchor.
- The positioning outline is now centered on the combat text anchor, removing the confusing right-edge offset.
- Center-based coordinates allow placement across the full screen, including the left side.


0.4.10 CHANGES
- Rebuilt the drag surface to fit the combat-text footprint.
- Vertical layout uses a tall, narrow positioning box around the stacked numbers.
- Horizontal layout uses a wide, shallow positioning box around the row of numbers.
- The combat-text anchor is derived from the box's bottom-left during movement,
  keeping the numbers inside the box and preventing release-time snapping.

0.4.14 CHANGES
- Tightened the vertical positioning box into a tall, narrow column around the damage text and icons.
- Narrowed the vertical text field so the numbers fit within that column.
- Horizontal layout retains its wider positioning area.
