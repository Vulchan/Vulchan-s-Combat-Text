# Vulchan's Combat Text

An addon for **Azeroth Survivors** that condenses the floating combat text into a much more manageable form. No longer are we blind to the game.

## Installation

1. Close Azeroth Survivors.
2. Replace the existing `VulchansCombatText` folder in `AddOns` with this folder.
3. Launch the game and start a run.

## Testing

Type `/vct test`. The test tries to show icons for **Shadow Bolt**, **Corruption** and **Melee**.

- Real outgoing spell hits use the spell name parsed from the combat message and look up that spell in your spellbook.
- Melee uses the equipped main-hand weapon.

## Commands

| Command              | Description                     |
| -------------------- | ------------------------------- |
| `/vct on`            | Enable the addon                |
| `/vct off`           | Disable the addon               |
| `/vct test`          | Show test combat text           |
| `/vct icons on`      | Show spell icons                |
| `/vct icons off`     | Hide spell icons                |
| `/vct iconsize 22`   | Set the icon size (in pixels)   |
| `/vct reset`         | Reset all settings              |

## Damage Display

- Exact values below 1,000.
- Whole-thousand shorthand from `1k` through `999k`.
- Spell icons sit 1 pixel to the left of the rendered number and follow it as its digit count changes.

## Notes

- Standalone: does not load or alter the Survivor UI.
- Spell icons are resolved from the player's spellbook. If a spell is not in the spellbook, or the message format does not identify its source, the number stays visible without an icon.
- Incoming damage has no source spell name in the classic `COMBAT_TEXT_UPDATE` event, so it intentionally has no source icon in this version.

## Changelog

### 0.3.4
- **Change:** Spell icons now track the rendered number width dynamically instead of anchoring to the fixed-width text frame.

### 0.3.3
- **Fix:** Replaced `string.match` calls with Lua 5.0-compatible `string.find` captures.
- **Change:** Reduced icon-to-number gap from 5 pixels to 1 pixel.
