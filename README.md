# CAS Armour (RedM)

Slot-based equipment and armor system for RedM with NUI drag-and-drop interface. Supports both VORP and RSGCore frameworks.

## Requirements
- `vorp_core` or `rsg-core`
- `vorp_inventory` or `rsg-inventory`
- `oxmysql`

## Installation
1. Import `sql/cas_armour_equipment.sql` into your database.
2. Keep the resource folder name as `cas-armour`.
3. Add to `server.cfg`:
```
ensure oxmysql
ensure vorp_core
ensure vorp_inventory
ensure cas-armour
```

## Features

### Equipment System
- **10 equipment slots**: head, chest, vest, pants, boots, gloves, belt, amulet, trinket1, trinket2
- **Drag & drop**: Equip from inventory, unequip back to inventory
- **Metadata persistence**: Condition/durability stored per item via oxmysql

### Damage Reduction
- `armorBase` provides baseline reduction across all damage types
- Category-specific resists: `bulletResist`, `meleeResist`, `animalResist`, `fallResist`, `explosionResist`, `poisonResist`
- Formula: `reduction% = (armorBase * ArmorBaseToReduction) + categoryResist`, capped at `MaxDamageReductionPercent`

### Durability / Wear
- Taking damage reduces armor condition based on `WearPerDamage`
- When condition reaches 0, the piece breaks and is removed from the slot
- Wear is distributed to nearby slots (e.g., torso hit also wears belt/amulet)

### Set Bonuses
- 7 armor sets with 5 bonus tiers each (2pc, 4pc, 6pc, 8pc, 10pc)
- Bonus stats are NOT condition-scaled (always active while equipped)
- 10-piece bonus grants a unique passive ability per set

### Movement Speed
- `staminaCostModifier` and `weightPenalty` reduce movement speed
- Formula: `mult = 1.0 - (staminaCost * StaminaCostToMovePenalty) - weightPenalty`

### Environmental Effects
- **Cold/Heat Resistance**: Reduces core drain in extreme temperatures
- **Stamina/Deadeye Drain**: Modifies core drain rates
- **Stealth/Noise**: Reduces NPC hearing/seeing range
- **Intimidation**: Chance to make aimed NPCs surrender

### Set Passive Abilities
| Set | Passive | Effect |
|-----|---------|--------|
| Wolf | Wolf Detection Reduction | Extra NPC sense reduction |
| Bear | Bear Charge Resistance | Ragdoll immunity |
| Outlaw | Bullet Dodge Chance | 15% chance to negate bullet damage |
| Scholar | Enemy Detection Boost | Blips on hostile NPCs |
| Snake | Poison Aura | AoE damage to nearby NPCs |
| Night | Assassination Expertise | Bonus damage on unaware NPCs |
| Legend | Quickdraw Mastery | 2x intimidation + deadeye recovery |

## Crafting
- Blacksmith NPCs at configurable locations (default: Valentine, Annesburg, Rhodes)
- Uses `vorp_menu` for set/piece selection interface
- Progress bar with animation during crafting

## Configuration
All tuning values are in `shared/config.lua` under `Config.Tuning`, `Config.WeightPenalty`, `Config.ArmorPieces`, and `Config.ArmorSets`.

## NUI Callbacks
- `cas_armour:close` - Close the UI
- `cas_armour:requestData` - Request equipment/inventory data
- `cas_armour:equip` - Equip an item: `{ pieceId, itemName, itemId, targetSlot, metadata }`
- `cas_armour:unequip` - Unequip a slot: `{ slot }`
- `cas_armour:craft` - Craft a piece: `{ pieceId }`

## Exports

**Client:**
- `exports['cas-armour']:GetEquipment()`
- `exports['cas-armour']:GetStats()`
- `exports['cas-armour']:GetActivePassives()`

**Server:**
- `exports['cas-armour']:GetEquipment(source)`
