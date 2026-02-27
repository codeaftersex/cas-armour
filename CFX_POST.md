# [FREE] CAS Armour - Advanced Equipment & Armor System for RedM

## Overview

**CAS Armour** is a fully featured, slot-based equipment system for RedM servers. It includes a custom NUI interface with drag-and-drop mechanics, 7 unique armor sets (70 pieces total), set bonuses with passive abilities, durability/wear mechanics, crafting stations, and deep stat-based gameplay.

Built for **VORP** and **RSGCore** frameworks with automatic detection.

---

## Features

### Equipment System
- **10 equipment slots**: Head, Chest, Vest, Pants, Boots, Gloves, Belt, Amulet, Trinket 1, Trinket 2
- **Drag & drop NUI** with inventory search and weight-class filtering
- **Cinematic camera** with depth-of-field when opening the equipment UI
- **Slot zoom camera** - clicking a slot zooms into that body region
- **Bone-connected floating slots** - equipment slots are positioned on your character's body
- **Condition/durability bars** visible on each equipped piece

### 7 Armor Sets (70 Pieces)

| Set | Specialization | Key Stats |
|-----|---------------|-----------|
| Wolf Hunter | Animal defense | 65% Animal Resist, Cold Resist, Stealth |
| Bear Barbarian | Heavy tank | 65% Bullet + 65% Melee Resist |
| Outlaw Duster | Gunslinger | 65% Bullet Resist, Deadeye bonuses |
| Mystic Scholar | Environmental | Cold/Heat Resist, Stamina efficiency |
| Snake Oil Salesman | Poison | 65% Poison Resist, Stealth |
| Night Stalker | Stealth/Assassin | Max Stealth + Noise Reduction |
| Wild West Legend | Authority | 65% Bullet Resist, Intimidation |

### Set Bonus System
Each set has **5 bonus tiers** that stack:
- **2 pieces**: Minor stat bonus
- **4 pieces**: Moderate bonus
- **6 pieces**: Strong bonus
- **8 pieces**: Major bonus
- **10 pieces**: Full set bonus + **unique passive ability**

### Unique Passive Abilities (10-Piece Bonuses)

| Set | Passive | Effect |
|-----|---------|--------|
| Wolf Hunter | Wolf Detection Reduction | NPCs have drastically reduced awareness of you |
| Bear Barbarian | Bear Charge Resistance | Immune to ragdoll effects |
| Outlaw Duster | Bullet Dodge Chance | 15% chance to completely negate bullet damage |
| Mystic Scholar | Enemy Detection Boost | Blips appear on hostile/alert NPCs nearby |
| Snake Oil Salesman | Poison Aura | Deals AoE poison damage to nearby NPCs |
| Night Stalker | Assassination Expertise | Bonus stealth + extra damage on unaware NPCs |
| Wild West Legend | Quickdraw Mastery | 2x intimidation effect + passive deadeye recovery |

### Damage Reduction
- **Formula**: `reduction% = (armorBase x multiplier) + categoryResist`
- Capped at configurable maximum (default 65%)
- Categories: Bullet, Melee, Animal, Fall, Explosion, Poison
- Damage is **reduced**, not absorbed - your health still goes down, but less

### Durability & Wear
- Taking damage reduces armor piece condition
- Wear spreads to nearby slots (torso hit also wears belt/amulet)
- When condition reaches 0, the piece **breaks** and is removed
- Condition is saved per-item via metadata

### Movement & Speed
- Heavier armor slows you down (weight penalty per piece)
- `staminaCostModifier` affects movement speed
- Configurable min/max speed multipliers

### Environmental Effects
- **Cold/Heat Resistance**: Reduces core drain in extreme temperatures
- **Stamina/Deadeye Drain**: Armor modifies core drain rates
- **Stealth/Noise**: Reduces NPC hearing and seeing range
- **Intimidation**: Chance to make aimed NPCs surrender with hands up

### Crafting System
- **Blacksmith NPC stations** at configurable locations (default: Valentine, Annesburg, Rhodes)
- NPCs with proper outfit spawns and idle animations
- **3-layer menu**: Set Selection > Piece List > Confirm/Craft
- Progress bar with animation during crafting
- 14 crafting materials included

### In-Game HUD
- Bottom-left HUD showing equipped armor pieces with condition bars
- Auto-hides when no armor is equipped
- Clean, minimal design matching RDR2 aesthetics

---

## Dependencies
- [oxmysql](https://github.com/overextended/oxmysql)
- [VORP Core](https://github.com/VORPCORE/vorp-core-lua) + [VORP Inventory](https://github.com/VORPCORE/vorp_inventory-lua) **OR** [RSGCore](https://github.com/Suspended/rsg-core) + RSG Inventory

---

## Installation

1. Download and place in your resources folder as `cas-armour`
2. Import the SQL files:
   - `sql/cas_armour_equipment.sql` - Equipment storage table
   - `sql/cas_armour_items.sql` - All 70 armor items + 14 crafting materials for VORP inventory
3. Add to your `server.cfg`:
```
ensure oxmysql
ensure vorp_core
ensure vorp_inventory
ensure cas-armour
```
4. Configure in `shared/config.lua` - all tuning values are clearly documented

---

## Configuration

Everything is configurable in `shared/config.lua`:

- **Tuning**: Damage reduction multipliers, wear rates, movement penalties, save intervals
- **Weight Penalty**: Per-piece speed penalty based on light/medium/heavy classification
- **Environment**: Cold/heat thresholds, core drain rates, resistance scaling
- **AI**: Stealth, noise, intimidation settings
- **Passives**: All 7 passive ability parameters (chance, radius, damage, etc.)
- **Crafting Stations**: NPC models, locations, blips, animations
- **Armor Pieces**: All 70 pieces with full stat customization
- **Armor Sets**: All 7 sets with 5 bonus tiers each

---

## Commands

| Command | Description |
|---------|-------------|
| `/armor` | Open the equipment UI |
| `/armorreload` | Force reload equipment data |
| `/armourtest` | Spawn a test ped that shoots at you for 15 seconds (for testing) |

---

## Exports

**Client-side:**
```lua
exports['cas-armour']:GetEquipment()     -- Returns current equipment table
exports['cas-armour']:GetStats()         -- Returns aggregated stats
exports['cas-armour']:GetActivePassives() -- Returns active passive abilities
```

**Server-side:**
```lua
exports['cas-armour']:GetEquipment(source) -- Returns player's equipment
```

---

## Technical Details

- **Framework**: Auto-detects VORP or RSGCore on startup
- **Database**: oxmysql with JSON blob storage (single row per character)
- **NUI**: HTML/JS with Tailwind CSS, jQuery UI for drag-and-drop
- **Damage System**: Event-based detection with heal-back mechanism
- **Wear Batching**: Client merges wear hits by slot, sends batch to server (reduces network traffic)
- **Performance**: Configurable poll rates, GPU-friendly NUI with `contain: content` optimization

---

## Credits

- **CAS** - Core development
- **UIforc** - NUI design

---

## Source Code

GitHub: https://github.com/codeaftersex/cas-armour

---

## License

This resource is **free and open source**. You are free to use, modify, and distribute it. Credit is appreciated but not required.
