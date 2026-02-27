-- shared/config.lua
-- Slot-based equipment + armor set system (RedM / VORP / oxmysql)

Config = Config or {}

Config.Debug = true
Config.RegisterUsableItems = false -- auto-equip armor piece on item use if slot is empty

-- UI open command and keybind
Config.OpenCommand = 'armor'
Config.OpenKey = 0xD8F73058 -- U key (INPUT_OPEN_JOURNAL)

-- Cinematic camera: full-body view when UI opens
Config.CinematicCam = {
  enabled = true,
  distance = 6.0,
  height = -0.05,
  offsetRight = 0.2,
  fov = 20.0,
  transitionIn = 600,
  transitionOut = 400,
  freezePlayer = true,
  dof = {
    enabled = true,
    nearDof = 0.5,
    farDof = 3.8,
    strength = 1.0,
  },
}

-- Slot-zoom camera: clicking a slot zooms into that body region
Config.SlotCamZoom = {
  enabled = true,
  transitionMs = 800,
  returnMs = 600,
  dist = 1.0,
  fov = 28.0,
  offsetRight = 0.08,
  overrides = {
    head   = { dist = 0.8, fov = 25 },
    boots  = { dist = 1.2, fov = 32 },
    gloves = { dist = 0.9, fov = 26 },
  },
}

-- Bone-to-slot mapping for RPG-style equipment screen lines
-- bone_id values from rdr3_discoveries/boneNames/mp_male__boneNames.lua
-- side: "left" = slot rendered on screen left, "right" = screen right
Config.SlotBoneMap = {
  head     = { bone = 21030, side = "left"  },  -- skel_head
  chest    = { bone = 14414, side = "left"  },  -- skel_spine4
  gloves   = { bone = 34606, side = "left"  },  -- skel_l_hand
  belt     = { bone = 31227, side = "left"  },  -- MH_BeltRoot
  boots    = { bone = 45454, side = "left"  },  -- skel_l_foot
  amulet   = { bone = 14283, side = "right" },  -- SKEL_Neck0
  vest     = { bone = 27792, side = "right" },  -- MH_Chest
  pants    = { bone = 4186,  side = "right" },  -- RB_R_KneeFront
  trinket1 = { bone = 29881, side = "right" },  -- MH_R_Wrist
  trinket2 = { bone = 63187, side = "right" },  -- PH_Satchel
}

-- Equipment slots (must match NUI layout)
Config.Slots = {
  'head',
  'chest',
  'vest',
  'pants',
  'boots',
  'gloves',
  'belt',
  'amulet',
  'trinket1',
  'trinket2',
}

-- Tuning: core gameplay balance knobs
Config.Tuning = {
  ArmorBaseToReduction = 1.0, -- multiplier: 1 armorBase point = ~1% baseline damage reduction
  MaxDamageReductionPercent = 65, -- hard cap on total damage reduction from all sources

  WearPerDamage = 0.45, -- condition loss per 1 HP of incoming damage, split across equipped pieces
  MaxWearPerHit = 25, -- cap on condition loss from a single hit

  StaminaCostToMovePenalty = 0.005, -- 1 staminaCostModifier = 0.5% movement speed penalty
  MinMoveMultiplier = 0.78, -- slowest possible movement speed multiplier
  MaxMoveMultiplier = 1.05, -- fastest possible movement speed multiplier

  AllowSwap = true, -- equipping into an occupied slot auto-unequips the old piece
}

-- Additional movement penalty based on armor weight class
Config.WeightPenalty = {
  light = 0.02,
  medium = 0.05,
  heavy = 0.10,
}

-- Environmental temperature: cold/heat drain cores, resisted by coldResist/heatResist
Config.Environment = Config.Environment or {
  enabled = true,

  coldThreshold = 0.0, -- temperature below this triggers cold stress
  heatThreshold = 30.0, -- temperature above this triggers heat stress

  coldRange = 25.0, -- degrees below threshold for stress to reach 1.0
  heatRange = 15.0, -- degrees above threshold for stress to reach 1.0

  baseStaminaCoreDrainPerSec = 0.14, -- core points lost per second at max stress
  healthCoreDrainShare = 0.35, -- health drain as fraction of stamina drain (0..1)

  ResistPointToStressReduction = 0.03, -- each resist point reduces stress by 3%
}

-- Core drain modifiers: positive = drains faster, negative = drains slower
Config.CoreDrain = Config.CoreDrain or {
  pollMs = 250,
  staminaPointToRefund = 0.06,
  staminaPointToExtraDrain = 0.06,
  deadeyePointToRefund = 0.08,
  deadeyePointToExtraDrain = 0.08,
}

-- AI interaction: stealth/noise adjust NPC hearing and seeing ranges
Config.AI = Config.AI or {
  enabled = true,

  refreshMs = 1000,
  resetAfterMs = 5500,

  stealthAuraRadius = 45.0,
  baseHearingRange = 55.0,
  baseSeeingRange = 85.0,

  -- sense multiplier = 1 - ((stealthModifier + -noiseModifier) * perPoint)
  stealthPointToSenseReduction = 0.02,
  minSenseMultiplier = 0.45,
  maxSenseMultiplier = 1.25,

  intimidation = {
    enabled = true,
    radius = 15.0,
    baseChance = 0.06,
    chancePerPoint = 0.03,
    cooldownMs = 6000,
    handsUpDurationMs = 6500,
  },
}

-- Set passive effect tuning (10-piece set bonuses)
Config.Passives = {
  wolf_detection_reduction = {
    extraSenseMultiplier = 0.55,
    minSenseOverride = 0.20,
  },
  bear_charge_resistance = {
    disableRagdoll = true,
  },
  bullet_dodge_chance = {
    chance = 0.15, -- 15% chance to fully negate bullet damage
  },
  enemy_detection_boost = {
    radius = 80.0, -- blip hostile NPCs within this range
    refreshMs = 2000,
  },
  poison_aura = {
    radius = 5.0, -- AoE radius around player
    damage = 3, -- damage per tick to nearby NPCs
    intervalMs = 3000,
  },
  assassination_expertise = {
    extraSenseMultiplier = 0.40,
    minSenseOverride = 0.15,
    stealthBonusDamage = 15, -- flat bonus damage on unaware NPCs
  },
  quickdraw_mastery = {
    intimidationMultiplier = 2.0,
    deadeyeRecovery = 1,
    deadeyeRecoveryMs = 2000,
    deadeyeRecoveryCap = 90,
  },
}

-- Pieces with slot='trinket' can go into either trinket1 or trinket2
Config.MultiSlotAliases = {
  trinket = { 'trinket1', 'trinket2' },
}

-- Implemented stat keys:
--   armorBase, *Resist (bullet/melee/animal/cold/heat/fall/poison/explosion)
--   staminaCostModifier, deadeyeDrainModifier, stealthModifier, noiseModifier, intimidation

-- Armor Pieces
Config.ArmorPieces = {

  -- Wolf Set (Light-Medium) - Animal/cold specialist
  wolf_skull_helm = {
    name = 'Wolf Skull Helm',
    description = "A fearsome helm crafted from a wolf's skull. Lightweight and intimidating.",
    itemName = 'wolf_skull_helm',
    slot = 'head',
    weight = 'light',
    set = 'wolf_set',
    stats = {
      armorBase = 2,
      animalResist = 4,
      coldResist = 2,
      intimidation = 1,
    },
    condition = 40,
    maxCondition = 40,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'wolf_pelt', amount = 1 },
        { item = 'wolf_tooth', amount = 4 },
        { item = 'leather_strips', amount = 2 },
      },
    },
  },

  wolf_pelt_coat = {
    name = 'Wolf Pelt Coat',
    description = 'A thick coat made from wolf pelts. Provides excellent protection against the cold and animals.',
    itemName = 'wolf_pelt_coat',
    slot = 'chest',
    weight = 'medium',
    set = 'wolf_set',
    stats = {
      armorBase = 3,
      animalResist = 6,
      bulletResist = 2,
      coldResist = 4,
      stealthModifier = -1,
      staminaCostModifier = 2,
    },
    condition = 60,
    maxCondition = 60,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'wolf_pelt', amount = 3 },
        { item = 'leather', amount = 4 },
        { item = 'cotton_cloth', amount = 2 },
      },
    },
  },

  wolf_fur_gloves = {
    name = 'Wolf Fur Gloves',
    description = 'Warm gloves lined with wolf fur. Perfect for handling weapons in cold weather.',
    itemName = 'wolf_fur_gloves',
    slot = 'gloves',
    weight = 'light',
    set = 'wolf_set',
    stats = {
      armorBase = 1,
      animalResist = 3,
      coldResist = 3,
      stealthModifier = 2,
    },
    condition = 35,
    maxCondition = 35,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'wolf_pelt', amount = 1 },
        { item = 'leather_strips', amount = 3 },
      },
    },
  },

  -- Bear Barbarian Set (Heavy) - Tank
  bear_skull_pauldrons = {
    name = 'Bear Skull Pauldrons',
    description = "Imposing shoulder armor crafted from a grizzly bear's bones and skull.",
    itemName = 'bear_skull_pauldrons',
    slot = 'chest',
    weight = 'heavy',
    set = 'bear_barbarian',
    stats = {
      armorBase = 5,
      bulletResist = 5,
      meleeResist = 5,
      fallResist = 3,
      staminaCostModifier = 3,
    },
    condition = 80,
    maxCondition = 80,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'bear_pelt', amount = 2 },
        { item = 'bear_bone', amount = 4 },
        { item = 'leather', amount = 3 },
      },
    },
  },

  bear_hide_chaps = {
    name = 'Bear Hide Chaps',
    description = 'Heavy leg armor lined with thick bear hide for maximum protection.',
    itemName = 'bear_hide_chaps',
    slot = 'pants',
    weight = 'heavy',
    set = 'bear_barbarian',
    stats = {
      armorBase = 3,
      bulletResist = 4,
      meleeResist = 4,
      fallResist = 4,
      staminaCostModifier = 2,
    },
    condition = 60,
    maxCondition = 60,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'bear_pelt', amount = 1 },
        { item = 'leather', amount = 2 },
      },
    },
  },

  bear_claw_gauntlets = {
    name = 'Bear Claw Gauntlets',
    description = 'Brutish gauntlets adorned with the claws of a mighty bear.',
    itemName = 'bear_claw_gauntlets',
    slot = 'gloves',
    weight = 'heavy',
    set = 'bear_barbarian',
    stats = {
      armorBase = 2,
      bulletResist = 3,
      meleeResist = 5,
      staminaCostModifier = 2,
    },
    condition = 55,
    maxCondition = 55,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'bear_pelt', amount = 1 },
        { item = 'bear_claw', amount = 3 },
        { item = 'leather_strips', amount = 2 },
      },
    },
  },

  -- Outlaw Duster Set (Light) - Bullet specialist
  reinforced_duster_coat = {
    name = 'Reinforced Duster Coat',
    description = 'A tactical duster coat with hidden armor plating, favored by quick-draw gunslingers.',
    itemName = 'reinforced_duster_coat',
    slot = 'chest',
    weight = 'light',
    set = 'outlaw_duster',
    stats = {
      armorBase = 3,
      bulletResist = 8,
      stealthModifier = 2,
      deadeyeDrainModifier = -1,
    },
    condition = 45,
    maxCondition = 45,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'cloth_duster', amount = 1 },
        { item = 'steel_plate', amount = 2 },
        { item = 'leather', amount = 1 },
      },
    },
  },

  outlaw_leather_vest = {
    name = 'Outlaw Leather Vest',
    description = 'A sleek leather vest with concealed pockets and reinforced seams.',
    itemName = 'outlaw_leather_vest',
    slot = 'vest',
    weight = 'light',
    set = 'outlaw_duster',
    stats = {
      armorBase = 2,
      bulletResist = 6,
      stealthModifier = 2,
    },
    condition = 40,
    maxCondition = 40,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'leather', amount = 2 },
        { item = 'leather_strips', amount = 3 },
      },
    },
  },

  gunslinger_boots = {
    name = 'Gunslinger Boots',
    description = 'Lightweight, nimble boots for quick movements and faster draw times.',
    itemName = 'gunslinger_boots',
    slot = 'boots',
    weight = 'light',
    set = 'outlaw_duster',
    stats = {
      armorBase = 1,
      bulletResist = 4,
      stealthModifier = 2,
    },
    condition = 35,
    maxCondition = 35,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'leather', amount = 1 },
        { item = 'leather_strips', amount = 2 },
      },
    },
  },

  -- Mystic Scholar Set (Medium) - Cold/Heat specialist
  scholar_coat = {
    name = "Scholar's Weathered Coat",
    description = 'An old but well-crafted coat lined with protective furs, worn by travelers and scholars.',
    itemName = 'scholar_coat',
    slot = 'chest',
    weight = 'medium',
    set = 'mystic_scholar',
    stats = {
      armorBase = 3,
      coldResist = 8,
      heatResist = 6,
      bulletResist = 1,
      staminaCostModifier = 1,
    },
    condition = 50,
    maxCondition = 50,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'cloth', amount = 3 },
        { item = 'fur', amount = 2 },
        { item = 'leather', amount = 1 },
      },
    },
  },

  scholar_gloves = {
    name = "Scholar's Leather Gloves",
    description = 'Fine leather gloves providing dexterity and protection for precise work.',
    itemName = 'scholar_gloves',
    slot = 'gloves',
    weight = 'medium',
    set = 'mystic_scholar',
    stats = {
      armorBase = 1,
      coldResist = 4,
      heatResist = 3,
    },
    condition = 35,
    maxCondition = 35,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'leather', amount = 1 },
        { item = 'leather_strips', amount = 2 },
      },
    },
  },

  scholar_amulet = {
    name = 'Mystic Amulet',
    description = 'An ornate amulet imbued with arcane knowledge, granting heightened perception.',
    itemName = 'scholar_amulet',
    slot = 'amulet',
    weight = 'light',
    set = 'mystic_scholar',
    stats = {
      armorBase = 1,
      coldResist = 5,
      heatResist = 4,
    },
    condition = 30,
    maxCondition = 30,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'gold_bar', amount = 1 },
        { item = 'gem', amount = 2 },
        { item = 'cloth', amount = 1 },
      },
    },
  },

  -- Snake Oil Salesman Set (Light) - Poison specialist
  snake_pattern_vest = {
    name = 'Snake Pattern Vest',
    description = 'A garish vest covered in serpent patterns, worn by those who deal in poisons and deception.',
    itemName = 'snake_pattern_vest',
    slot = 'vest',
    weight = 'light',
    set = 'snake_oil_salesman',
    stats = {
      armorBase = 1,
      poisonResist = 6,
      stealthModifier = 3,
      animalResist = 2,
    },
    condition = 38,
    maxCondition = 38,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'cloth', amount = 2 },
        { item = 'snake_skin', amount = 2 },
        { item = 'leather_strips', amount = 1 },
      },
    },
  },

  poison_flask_belt = {
    name = 'Poison Flask Belt',
    description = 'A specialized belt with hidden compartments for vials of toxic concoctions.',
    itemName = 'poison_flask_belt',
    slot = 'belt',
    weight = 'light',
    set = 'snake_oil_salesman',
    stats = {
      poisonResist = 5,
      stealthModifier = 1,
      animalResist = 1,
    },
    condition = 32,
    maxCondition = 32,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'leather', amount = 1 },
        { item = 'snake_skin', amount = 1 },
        { item = 'gold_bar', amount = 1 },
      },
    },
  },

  serpent_amulet = {
    name = 'Serpent Amulet',
    description = 'An ornate amulet shaped like a coiled serpent, granting resistance to venoms.',
    itemName = 'serpent_amulet',
    slot = 'amulet',
    weight = 'light',
    set = 'snake_oil_salesman',
    stats = {
      poisonResist = 5,
      stealthModifier = 1,
      animalResist = 2,
    },
    condition = 28,
    maxCondition = 28,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'snake_skin', amount = 2 },
        { item = 'gold_bar', amount = 1 },
      },
    },
  },

  -- Night Stalker Set (Light) - Stealth specialist
  shadow_cloak = {
    name = 'Shadow Cloak',
    description = 'A dark, flowing cloak that seems to absorb light itself. Favored by those who move in darkness.',
    itemName = 'shadow_cloak',
    slot = 'chest',
    weight = 'light',
    set = 'night_stalker',
    stats = {
      armorBase = 2,
      bulletResist = 3,
      stealthModifier = 6,
      noiseModifier = -5,
    },
    condition = 42,
    maxCondition = 42,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'cloth', amount = 3 },
        { item = 'dark_leather', amount = 2 },
      },
    },
  },

  obsidian_boots = {
    name = 'Obsidian Boots',
    description = 'Silent, jet-black boots that leave barely a trace. Perfect for sneaking.',
    itemName = 'obsidian_boots',
    slot = 'boots',
    weight = 'light',
    set = 'night_stalker',
    stats = {
      armorBase = 1,
      bulletResist = 2,
      stealthModifier = 5,
      noiseModifier = -5,
    },
    condition = 35,
    maxCondition = 35,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'dark_leather', amount = 1 },
        { item = 'leather_strips', amount = 2 },
      },
    },
  },

  midnight_gloves = {
    name = 'Midnight Gloves',
    description = 'Thin, black gloves for precise work without leaving fingerprints.',
    itemName = 'midnight_gloves',
    slot = 'gloves',
    weight = 'light',
    set = 'night_stalker',
    stats = {
      stealthModifier = 5,
      noiseModifier = -3,
    },
    condition = 30,
    maxCondition = 30,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'dark_leather', amount = 1 },
        { item = 'leather_strips', amount = 1 },
      },
    },
  },

  -- Wild West Legend Set (Medium) - Bullet/Authority
  marshal_badge_vest = {
    name = 'Marshal Badge Vest',
    description = 'A reinforced vest bearing an official badge. Symbol of law and order in the frontier.',
    itemName = 'marshal_badge_vest',
    slot = 'chest',
    weight = 'medium',
    set = 'wild_west_legend',
    stats = {
      armorBase = 3,
      bulletResist = 8,
      meleeResist = 1,
      staminaCostModifier = -1,
      intimidation = 3,
    },
    condition = 55,
    maxCondition = 55,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'leather', amount = 2 },
        { item = 'steel_plate', amount = 2 },
        { item = 'gold_bar', amount = 1 },
      },
    },
  },

  frontier_hat = {
    name = 'Frontier Lawman Hat',
    description = 'A distinctive wide-brimmed hat worn by frontier law enforcers.',
    itemName = 'frontier_hat',
    slot = 'head',
    weight = 'light',
    set = 'wild_west_legend',
    stats = {
      armorBase = 2,
      bulletResist = 4,
    },
    condition = 40,
    maxCondition = 40,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'cloth', amount = 2 },
        { item = 'leather', amount = 1 },
      },
    },
  },

  ranger_spurs = {
    name = 'Ranger Spurs',
    description = 'Heavy, authoritative spurs worn by those who patrol vast territories.',
    itemName = 'ranger_spurs',
    slot = 'boots',
    weight = 'medium',
    set = 'wild_west_legend',
    stats = {
      armorBase = 2,
      bulletResist = 4,
    },
    condition = 45,
    maxCondition = 45,
    crafting = {
      enabled = true,
      requirements = {
        { item = 'leather', amount = 1 },
        { item = 'iron_bar', amount = 2 },
      },
    },
  },
}

-- Wolf Set additional pieces (7 remaining)
Config.ArmorPieces.wolf_tracker_vest = {
  name = 'Wolf Tracker Vest',
  description = 'A rugged vest for trackers. Part of the Wolf Hunter set.',
  itemName = 'wolf_tracker_vest',
  slot = 'vest',
  weight = 'light',
  set = 'wolf_set',
  stats = { armorBase = 2, animalResist = 3, coldResist = 2, stealthModifier = 1 },
  condition = 38, maxCondition = 38,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 2 }, { item = 'leather_strips', amount = 2 },
  }},
}

Config.ArmorPieces.wolf_hide_chaps = {
  name = 'Wolf Hide Chaps',
  description = 'Warm chaps reinforced with wolf hide. Part of the Wolf Hunter set.',
  itemName = 'wolf_hide_chaps',
  slot = 'pants',
  weight = 'medium',
  set = 'wolf_set',
  stats = { armorBase = 2, animalResist = 3, coldResist = 3, staminaCostModifier = 1 },
  condition = 50, maxCondition = 50,
  crafting = { enabled = true, requirements = {
    { item = 'wolf_pelt', amount = 2 }, { item = 'leather', amount = 2 },
  }},
}

Config.ArmorPieces.wolf_hunter_boots = {
  name = 'Wolf Hunter Boots',
  description = 'Quiet boots made for snow and forest trails. Part of the Wolf Hunter set.',
  itemName = 'wolf_hunter_boots',
  slot = 'boots',
  weight = 'light',
  set = 'wolf_set',
  stats = { armorBase = 1, animalResist = 2, coldResist = 2, stealthModifier = 2, noiseModifier = -2 },
  condition = 40, maxCondition = 40,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 1 }, { item = 'leather_strips', amount = 2 },
  }},
}

Config.ArmorPieces.wolf_hunting_belt = {
  name = 'Wolf Hunting Belt',
  description = 'A belt with hooks and pouches for long hunts. Part of the Wolf Hunter set.',
  itemName = 'wolf_hunting_belt',
  slot = 'belt',
  weight = 'light',
  set = 'wolf_set',
  stats = { armorBase = 1, animalResist = 2, coldResist = 1 },
  condition = 35, maxCondition = 35,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 1 }, { item = 'leather_strips', amount = 2 },
  }},
}

Config.ArmorPieces.wolf_fang_amulet = {
  name = 'Wolf Fang Amulet',
  description = 'A fang talisman that steadies your breath. Part of the Wolf Hunter set.',
  itemName = 'wolf_fang_amulet',
  slot = 'amulet',
  weight = 'light',
  set = 'wolf_set',
  stats = { armorBase = 1, animalResist = 3, coldResist = 2 },
  condition = 30, maxCondition = 30,
  crafting = { enabled = true, requirements = {
    { item = 'wolf_tooth', amount = 4 }, { item = 'gold_bar', amount = 1 },
  }},
}

Config.ArmorPieces.wolf_totem_trinket = {
  name = 'Wolf Totem',
  description = 'A small totem bound with leather. Part of the Wolf Hunter set.',
  itemName = 'wolf_totem_trinket',
  slot = 'trinket1',
  weight = 'light',
  set = 'wolf_set',
  stats = { animalResist = 2, coldResist = 1, stealthModifier = 2 },
  condition = 28, maxCondition = 28,
  crafting = { enabled = true, requirements = {
    { item = 'cloth', amount = 1 }, { item = 'leather_strips', amount = 2 },
  }},
}

Config.ArmorPieces.wolf_pack_charm = {
  name = 'Pack Charm',
  description = 'A charm that reminds you to move as one. Part of the Wolf Hunter set.',
  itemName = 'wolf_pack_charm',
  slot = 'trinket2',
  weight = 'light',
  set = 'wolf_set',
  stats = { stealthModifier = 1, staminaCostModifier = -1, intimidation = 1 },
  condition = 28, maxCondition = 28,
  crafting = { enabled = true, requirements = {
    { item = 'wolf_tooth', amount = 2 }, { item = 'cloth', amount = 1 },
  }},
}

-- Bear Barbarian Set additional pieces (7 remaining)
Config.ArmorPieces.bear_war_helm = {
  name = 'Bear War Helm',
  description = 'A brutal helm built to intimidate. Part of the Bear Barbarian set.',
  itemName = 'bear_war_helm',
  slot = 'head',
  weight = 'heavy',
  set = 'bear_barbarian',
  stats = { armorBase = 3, bulletResist = 3, meleeResist = 3, intimidation = 2 },
  condition = 70, maxCondition = 70,
  crafting = { enabled = true, requirements = {
    { item = 'bear_bone', amount = 3 }, { item = 'leather', amount = 2 },
  }},
}

Config.ArmorPieces.bear_hide_vest = {
  name = 'Bear Hide Vest',
  description = 'Thick hide vest for close combat. Part of the Bear Barbarian set.',
  itemName = 'bear_hide_vest',
  slot = 'vest',
  weight = 'heavy',
  set = 'bear_barbarian',
  stats = { armorBase = 3, bulletResist = 3, meleeResist = 3 },
  condition = 60, maxCondition = 60,
  crafting = { enabled = true, requirements = {
    { item = 'bear_pelt', amount = 1 }, { item = 'leather', amount = 2 },
  }},
}

Config.ArmorPieces.bear_tread_boots = {
  name = 'Bear Tread Boots',
  description = 'Heavy boots that grip rock and mud. Part of the Bear Barbarian set.',
  itemName = 'bear_tread_boots',
  slot = 'boots',
  weight = 'heavy',
  set = 'bear_barbarian',
  stats = { armorBase = 2, bulletResist = 2, meleeResist = 2, fallResist = 3 },
  condition = 60, maxCondition = 60,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 2 }, { item = 'bear_claw', amount = 1 },
  }},
}

Config.ArmorPieces.bear_war_belt = {
  name = 'Bear War Belt',
  description = 'A reinforced belt that supports heavy gear. Part of the Bear Barbarian set.',
  itemName = 'bear_war_belt',
  slot = 'belt',
  weight = 'heavy',
  set = 'bear_barbarian',
  stats = { armorBase = 1, bulletResist = 2, meleeResist = 1, staminaCostModifier = -1 },
  condition = 55, maxCondition = 55,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 2 }, { item = 'leather_strips', amount = 2 },
  }},
}

Config.ArmorPieces.bear_bone_amulet = {
  name = 'Bear Bone Amulet',
  description = 'Bonework charm that hardens your resolve. Part of the Bear Barbarian set.',
  itemName = 'bear_bone_amulet',
  slot = 'amulet',
  weight = 'light',
  set = 'bear_barbarian',
  stats = { armorBase = 1, bulletResist = 1, meleeResist = 2, fallResist = 2 },
  condition = 35, maxCondition = 35,
  crafting = { enabled = true, requirements = {
    { item = 'bear_bone', amount = 2 }, { item = 'gold_bar', amount = 1 },
  }},
}

Config.ArmorPieces.bear_rage_totem = {
  name = 'Rage Totem',
  description = 'A carved token of pure aggression. Part of the Bear Barbarian set.',
  itemName = 'bear_rage_totem',
  slot = 'trinket1',
  weight = 'light',
  set = 'bear_barbarian',
  stats = { bulletResist = 1, staminaCostModifier = -2, intimidation = 2 },
  condition = 30, maxCondition = 30,
  crafting = { enabled = true, requirements = {
    { item = 'bear_claw', amount = 2 }, { item = 'cloth', amount = 1 },
  }},
}

Config.ArmorPieces.bear_iron_charm = {
  name = 'Iron Charm',
  description = 'A crude charm that wards pain. Part of the Bear Barbarian set.',
  itemName = 'bear_iron_charm',
  slot = 'trinket2',
  weight = 'light',
  set = 'bear_barbarian',
  stats = { bulletResist = 1 },
  condition = 30, maxCondition = 30,
  crafting = { enabled = true, requirements = {
    { item = 'iron_bar', amount = 1 }, { item = 'leather_strips', amount = 1 },
  }},
}

-- Outlaw Duster Set additional pieces (7 remaining)
Config.ArmorPieces.outlaw_hat = {
  name = 'Outlaw Hat',
  description = 'A sharp hat for a sharper draw. Part of the Outlaw Duster set.',
  itemName = 'outlaw_hat',
  slot = 'head',
  weight = 'light',
  set = 'outlaw_duster',
  stats = { armorBase = 1, bulletResist = 4, stealthModifier = 2 },
  condition = 40, maxCondition = 40,
  crafting = { enabled = true, requirements = {
    { item = 'cloth', amount = 2 }, { item = 'leather', amount = 1 },
  }},
}

Config.ArmorPieces.outlaw_riding_pants = {
  name = 'Outlaw Riding Pants',
  description = 'Flexible pants for fast movement. Part of the Outlaw Duster set.',
  itemName = 'outlaw_riding_pants',
  slot = 'pants',
  weight = 'light',
  set = 'outlaw_duster',
  stats = { armorBase = 1, bulletResist = 5, stealthModifier = 1 },
  condition = 45, maxCondition = 45,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 1 }, { item = 'cloth', amount = 2 },
  }},
}

Config.ArmorPieces.gunslinger_gloves = {
  name = 'Gunslinger Gloves',
  description = 'Grip and control, nothing else. Part of the Outlaw Duster set.',
  itemName = 'gunslinger_gloves',
  slot = 'gloves',
  weight = 'light',
  set = 'outlaw_duster',
  stats = { armorBase = 1, bulletResist = 3, stealthModifier = 1, deadeyeDrainModifier = -1 },
  condition = 35, maxCondition = 35,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 1 }, { item = 'leather_strips', amount = 2 },
  }},
}

Config.ArmorPieces.quickdraw_belt = {
  name = 'Quickdraw Belt',
  description = 'Balanced belt for speed and stability. Part of the Outlaw Duster set.',
  itemName = 'quickdraw_belt',
  slot = 'belt',
  weight = 'light',
  set = 'outlaw_duster',
  stats = { armorBase = 1, bulletResist = 3, deadeyeDrainModifier = -1 },
  condition = 38, maxCondition = 38,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 1 }, { item = 'steel_plate', amount = 1 },
  }},
}

Config.ArmorPieces.gamblers_amulet = {
  name = "Gambler's Amulet",
  description = 'Luck is a tool like any other. Part of the Outlaw Duster set.',
  itemName = 'gamblers_amulet',
  slot = 'amulet',
  weight = 'light',
  set = 'outlaw_duster',
  stats = { bulletResist = 2, stealthModifier = 1, deadeyeDrainModifier = -1 },
  condition = 30, maxCondition = 30,
  crafting = { enabled = true, requirements = {
    { item = 'gold_bar', amount = 1 }, { item = 'gem', amount = 1 },
  }},
}

Config.ArmorPieces.outlaw_coin = {
  name = 'Outlaw Coin',
  description = 'A weighted coin that feels "right" in your palm. Part of the Outlaw Duster set.',
  itemName = 'outlaw_coin',
  slot = 'trinket1',
  weight = 'light',
  set = 'outlaw_duster',
  stats = { bulletResist = 1, stealthModifier = 1 },
  condition = 28, maxCondition = 28,
  crafting = { enabled = true, requirements = {
    { item = 'gold_bar', amount = 1 }, { item = 'cloth', amount = 1 },
  }},
}

Config.ArmorPieces.outlaw_lucky_card = {
  name = 'Lucky Card',
  description = 'A marked card that never seems to lose. Part of the Outlaw Duster set.',
  itemName = 'outlaw_lucky_card',
  slot = 'trinket2',
  weight = 'light',
  set = 'outlaw_duster',
  stats = { deadeyeDrainModifier = -1 },
  condition = 28, maxCondition = 28,
  crafting = { enabled = true, requirements = {
    { item = 'cloth', amount = 1 }, { item = 'leather_strips', amount = 1 },
  }},
}

-- Mystic Scholar Set additional pieces (7 remaining)
Config.ArmorPieces.scholar_cap = {
  name = "Scholar's Cap",
  description = 'Simple headwear for long journeys. Part of the Mystic Scholar set.',
  itemName = 'scholar_cap',
  slot = 'head',
  weight = 'light',
  set = 'mystic_scholar',
  stats = { armorBase = 1, coldResist = 3, heatResist = 3 },
  condition = 35, maxCondition = 35,
  crafting = { enabled = true, requirements = {
    { item = 'cloth', amount = 2 }, { item = 'leather_strips', amount = 1 },
  }},
}

Config.ArmorPieces.scholar_vest = {
  name = "Scholar's Travel Vest",
  description = 'A vest with inner lining and pockets. Part of the Mystic Scholar set.',
  itemName = 'scholar_vest',
  slot = 'vest',
  weight = 'medium',
  set = 'mystic_scholar',
  stats = { armorBase = 2, coldResist = 4, heatResist = 3 },
  condition = 45, maxCondition = 45,
  crafting = { enabled = true, requirements = {
    { item = 'cloth', amount = 2 }, { item = 'leather', amount = 1 },
  }},
}

Config.ArmorPieces.scholar_trousers = {
  name = "Scholar's Trousers",
  description = 'Comfortable trousers for travel. Part of the Mystic Scholar set.',
  itemName = 'scholar_trousers',
  slot = 'pants',
  weight = 'medium',
  set = 'mystic_scholar',
  stats = { armorBase = 2, coldResist = 4, heatResist = 3 },
  condition = 45, maxCondition = 45,
  crafting = { enabled = true, requirements = {
    { item = 'cloth', amount = 2 }, { item = 'leather_strips', amount = 2 },
  }},
}

Config.ArmorPieces.scholar_boots = {
  name = "Scholar's Boots",
  description = 'Weathered boots built for distance. Part of the Mystic Scholar set.',
  itemName = 'scholar_boots',
  slot = 'boots',
  weight = 'medium',
  set = 'mystic_scholar',
  stats = { armorBase = 1, coldResist = 3, heatResist = 3 },
  condition = 45, maxCondition = 45,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 1 }, { item = 'leather_strips', amount = 2 },
  }},
}

Config.ArmorPieces.scholar_satchel_belt = {
  name = "Scholar's Satchel Belt",
  description = 'A belt with a small satchel for notes. Part of the Mystic Scholar set.',
  itemName = 'scholar_satchel_belt',
  slot = 'belt',
  weight = 'light',
  set = 'mystic_scholar',
  stats = { armorBase = 1, coldResist = 2, heatResist = 2, stealthModifier = 1 },
  condition = 35, maxCondition = 35,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 1 }, { item = 'cloth', amount = 1 },
  }},
}

Config.ArmorPieces.scholar_lens = {
  name = 'Runed Lens',
  description = 'A lens etched with symbols. Part of the Mystic Scholar set.',
  itemName = 'scholar_lens',
  slot = 'trinket1',
  weight = 'light',
  set = 'mystic_scholar',
  stats = { coldResist = 3, heatResist = 2, stealthModifier = 1 },
  condition = 28, maxCondition = 28,
  crafting = { enabled = true, requirements = {
    { item = 'gem', amount = 1 }, { item = 'gold_bar', amount = 1 },
  }},
}

Config.ArmorPieces.scholar_seal = {
  name = 'Scholar Seal',
  description = 'A wax seal pressed into metal. Part of the Mystic Scholar set.',
  itemName = 'scholar_seal',
  slot = 'trinket2',
  weight = 'light',
  set = 'mystic_scholar',
  stats = { armorBase = 1, coldResist = 2, heatResist = 2 },
  condition = 28, maxCondition = 28,
  crafting = { enabled = true, requirements = {
    { item = 'gold_bar', amount = 1 }, { item = 'cloth', amount = 1 },
  }},
}

-- Snake Oil Salesman Set additional pieces (7 remaining)
Config.ArmorPieces.snake_oil_hat = {
  name = 'Snake Oil Hat',
  description = 'A flashy hat for a slippery dealer. Part of the Snake Oil Salesman set.',
  itemName = 'snake_oil_hat',
  slot = 'head',
  weight = 'light',
  set = 'snake_oil_salesman',
  stats = { armorBase = 1, poisonResist = 4, stealthModifier = 2 },
  condition = 35, maxCondition = 35,
  crafting = { enabled = true, requirements = {
    { item = 'cloth', amount = 2 }, { item = 'snake_skin', amount = 1 },
  }},
}

Config.ArmorPieces.snake_slick_coat = {
  name = 'Slick Dealer Coat',
  description = 'A coat lined with treated leather. Part of the Snake Oil Salesman set.',
  itemName = 'snake_slick_coat',
  slot = 'chest',
  weight = 'light',
  set = 'snake_oil_salesman',
  stats = { armorBase = 2, poisonResist = 5, bulletResist = 2, stealthModifier = 2 },
  condition = 45, maxCondition = 45,
  crafting = { enabled = true, requirements = {
    { item = 'cloth', amount = 2 }, { item = 'leather', amount = 2 }, { item = 'snake_skin', amount = 1 },
  }},
}

Config.ArmorPieces.snake_hide_pants = {
  name = 'Snake Hide Pants',
  description = 'Treated hide pants, surprisingly quiet. Part of the Snake Oil Salesman set.',
  itemName = 'snake_hide_pants',
  slot = 'pants',
  weight = 'light',
  set = 'snake_oil_salesman',
  stats = { armorBase = 1, poisonResist = 5, stealthModifier = 2 },
  condition = 42, maxCondition = 42,
  crafting = { enabled = true, requirements = {
    { item = 'snake_skin', amount = 2 }, { item = 'leather_strips', amount = 2 },
  }},
}

Config.ArmorPieces.snake_silent_boots = {
  name = 'Silent Serpent Boots',
  description = 'Boots that soften every step. Part of the Snake Oil Salesman set.',
  itemName = 'snake_silent_boots',
  slot = 'boots',
  weight = 'light',
  set = 'snake_oil_salesman',
  stats = { armorBase = 1, poisonResist = 4, stealthModifier = 2, noiseModifier = -2 },
  condition = 38, maxCondition = 38,
  crafting = { enabled = true, requirements = {
    { item = 'snake_skin', amount = 1 }, { item = 'leather', amount = 1 },
  }},
}

Config.ArmorPieces.snake_needle_gloves = {
  name = 'Needle Gloves',
  description = 'Thin gloves for delicate, dangerous work. Part of the Snake Oil Salesman set.',
  itemName = 'snake_needle_gloves',
  slot = 'gloves',
  weight = 'light',
  set = 'snake_oil_salesman',
  stats = { poisonResist = 5, stealthModifier = 2 },
  condition = 32, maxCondition = 32,
  crafting = { enabled = true, requirements = {
    { item = 'leather_strips', amount = 2 }, { item = 'snake_skin', amount = 1 },
  }},
}

Config.ArmorPieces.venom_ring = {
  name = 'Venom Ring',
  description = 'A ring that reeks of old poisons. Part of the Snake Oil Salesman set.',
  itemName = 'venom_ring',
  slot = 'trinket1',
  weight = 'light',
  set = 'snake_oil_salesman',
  stats = { poisonResist = 4, animalResist = 1 },
  condition = 28, maxCondition = 28,
  crafting = { enabled = true, requirements = {
    { item = 'gold_bar', amount = 1 }, { item = 'snake_skin', amount = 1 },
  }},
}

Config.ArmorPieces.antidote_charm = {
  name = 'Antidote Charm',
  description = 'A charm for surviving your own tricks. Part of the Snake Oil Salesman set.',
  itemName = 'antidote_charm',
  slot = 'trinket2',
  weight = 'light',
  set = 'snake_oil_salesman',
  stats = { poisonResist = 3 },
  condition = 28, maxCondition = 28,
  crafting = { enabled = true, requirements = {
    { item = 'gold_bar', amount = 1 }, { item = 'cloth', amount = 1 },
  }},
}

-- Night Stalker Set additional pieces (7 remaining)
Config.ArmorPieces.hood_of_dusk = {
  name = 'Hood of Dusk',
  description = 'A hood that blends into darkness. Part of the Night Stalker set.',
  itemName = 'hood_of_dusk',
  slot = 'head',
  weight = 'light',
  set = 'night_stalker',
  stats = { armorBase = 1, stealthModifier = 5, noiseModifier = -3 },
  condition = 35, maxCondition = 35,
  crafting = { enabled = true, requirements = {
    { item = 'cloth', amount = 2 }, { item = 'dark_leather', amount = 1 },
  }},
}

Config.ArmorPieces.night_assassin_vest = {
  name = 'Assassin Vest',
  description = 'A vest stitched for silence. Part of the Night Stalker set.',
  itemName = 'night_assassin_vest',
  slot = 'vest',
  weight = 'light',
  set = 'night_stalker',
  stats = { armorBase = 1, bulletResist = 2, stealthModifier = 4, noiseModifier = -3 },
  condition = 40, maxCondition = 40,
  crafting = { enabled = true, requirements = {
    { item = 'dark_leather', amount = 2 }, { item = 'cloth', amount = 1 },
  }},
}

Config.ArmorPieces.dusk_pants = {
  name = 'Dusk Pants',
  description = 'Dark pants that reduce sound and shine. Part of the Night Stalker set.',
  itemName = 'dusk_pants',
  slot = 'pants',
  weight = 'light',
  set = 'night_stalker',
  stats = { armorBase = 1, stealthModifier = 4, noiseModifier = -3 },
  condition = 40, maxCondition = 40,
  crafting = { enabled = true, requirements = {
    { item = 'dark_leather', amount = 1 }, { item = 'cloth', amount = 2 },
  }},
}

Config.ArmorPieces.shadow_belt = {
  name = 'Shadow Belt',
  description = 'A belt that keeps your tools quiet. Part of the Night Stalker set.',
  itemName = 'shadow_belt',
  slot = 'belt',
  weight = 'light',
  set = 'night_stalker',
  stats = { armorBase = 1, stealthModifier = 3, noiseModifier = -2 },
  condition = 35, maxCondition = 35,
  crafting = { enabled = true, requirements = {
    { item = 'dark_leather', amount = 1 }, { item = 'leather_strips', amount = 2 },
  }},
}

Config.ArmorPieces.moonstone_amulet = {
  name = 'Moonstone Amulet',
  description = 'Cold stone, calm hands. Part of the Night Stalker set.',
  itemName = 'moonstone_amulet',
  slot = 'amulet',
  weight = 'light',
  set = 'night_stalker',
  stats = { bulletResist = 2, stealthModifier = 2 },
  condition = 30, maxCondition = 30,
  crafting = { enabled = true, requirements = {
    { item = 'gem', amount = 1 }, { item = 'gold_bar', amount = 1 },
  }},
}

Config.ArmorPieces.silent_token = {
  name = 'Silent Token',
  description = 'A token that rewards patience. Part of the Night Stalker set.',
  itemName = 'silent_token',
  slot = 'trinket1',
  weight = 'light',
  set = 'night_stalker',
  stats = { stealthModifier = 2, noiseModifier = -2 },
  condition = 28, maxCondition = 28,
  crafting = { enabled = true, requirements = {
    { item = 'cloth', amount = 1 }, { item = 'dark_leather', amount = 1 },
  }},
}

Config.ArmorPieces.assassin_mark = {
  name = "Assassin's Mark",
  description = 'A small mark of membership. Part of the Night Stalker set.',
  itemName = 'assassin_mark',
  slot = 'trinket2',
  weight = 'light',
  set = 'night_stalker',
  stats = { stealthModifier = 2, noiseModifier = -1 },
  condition = 28, maxCondition = 28,
  crafting = { enabled = true, requirements = {
    { item = 'dark_leather', amount = 1 }, { item = 'leather_strips', amount = 1 },
  }},
}

-- Wild West Legend Set additional pieces (7 remaining)
Config.ArmorPieces.deputy_leather_vest = {
  name = 'Deputy Leather Vest',
  description = 'A tidy vest worn by lawmen. Part of the Wild West Legend set.',
  itemName = 'deputy_leather_vest',
  slot = 'vest',
  weight = 'medium',
  set = 'wild_west_legend',
  stats = { armorBase = 2, bulletResist = 6, meleeResist = 1, intimidation = 1 },
  condition = 50, maxCondition = 50,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 2 }, { item = 'steel_plate', amount = 1 },
  }},
}

Config.ArmorPieces.legend_trousers = {
  name = 'Legend Trousers',
  description = 'Hard-wearing trousers for long patrols. Part of the Wild West Legend set.',
  itemName = 'legend_trousers',
  slot = 'pants',
  weight = 'medium',
  set = 'wild_west_legend',
  stats = { armorBase = 2, bulletResist = 5 },
  condition = 55, maxCondition = 55,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 1 }, { item = 'cloth', amount = 2 },
  }},
}

Config.ArmorPieces.lawman_gloves = {
  name = 'Lawman Gloves',
  description = 'Sturdy gloves for steady hands. Part of the Wild West Legend set.',
  itemName = 'lawman_gloves',
  slot = 'gloves',
  weight = 'medium',
  set = 'wild_west_legend',
  stats = { armorBase = 1, bulletResist = 3, intimidation = 1 },
  condition = 45, maxCondition = 45,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 1 }, { item = 'leather_strips', amount = 2 },
  }},
}

Config.ArmorPieces.marshal_belt = {
  name = 'Marshal Belt',
  description = 'A belt that carries authority and steel. Part of the Wild West Legend set.',
  itemName = 'marshal_belt',
  slot = 'belt',
  weight = 'medium',
  set = 'wild_west_legend',
  stats = { armorBase = 1, bulletResist = 3, staminaCostModifier = -1 },
  condition = 50, maxCondition = 50,
  crafting = { enabled = true, requirements = {
    { item = 'leather', amount = 2 }, { item = 'steel_plate', amount = 1 },
  }},
}

Config.ArmorPieces.badge_amulet = {
  name = 'Badge Amulet',
  description = 'A badge worn close to the heart. Part of the Wild West Legend set.',
  itemName = 'badge_amulet',
  slot = 'amulet',
  weight = 'light',
  set = 'wild_west_legend',
  stats = { armorBase = 1, bulletResist = 4, meleeResist = 1, intimidation = 2 },
  condition = 35, maxCondition = 35,
  crafting = { enabled = true, requirements = {
    { item = 'gold_bar', amount = 1 }, { item = 'steel_plate', amount = 1 },
  }},
}

Config.ArmorPieces.legend_medal = {
  name = 'Legend Medal',
  description = 'A medal for deeds that echo. Part of the Wild West Legend set.',
  itemName = 'legend_medal',
  slot = 'trinket1',
  weight = 'light',
  set = 'wild_west_legend',
  stats = { bulletResist = 2, intimidation = 2 },
  condition = 30, maxCondition = 30,
  crafting = { enabled = true, requirements = {
    { item = 'gold_bar', amount = 1 }, { item = 'gem', amount = 1 },
  }},
}

Config.ArmorPieces.legend_token = {
  name = 'Legend Token',
  description = 'A token passed between legends. Part of the Wild West Legend set.',
  itemName = 'legend_token',
  slot = 'trinket2',
  weight = 'light',
  set = 'wild_west_legend',
  stats = { bulletResist = 1, staminaCostModifier = -1 },
  condition = 30, maxCondition = 30,
  crafting = { enabled = true, requirements = {
    { item = 'gold_bar', amount = 1 }, { item = 'cloth', amount = 1 },
  }},
}


-- Armor Sets: bonuses at 2/4/6/8 piece thresholds, 10-piece grants a passive ability
Config.ArmorSets = {
  wolf_set = {
    name = 'Wolf Hunter',
    description = 'Armor crafted from wolf pelts, favored by trackers and hunters.',
    icon = '🐺',
    image = 'assets/setresim/wolf_set.png',
    pieces = {
      'wolf_skull_helm', 'wolf_pelt_coat', 'wolf_tracker_vest', 'wolf_hide_chaps', 'wolf_hunter_boots',
      'wolf_fur_gloves', 'wolf_hunting_belt', 'wolf_fang_amulet', 'wolf_totem_trinket', 'wolf_pack_charm',
    },
    bonuses = {
      ["2"]  = { name = 'Pack Mentality', description = "The wolf's spirit strengthens you.", stats = { animalResist = 4, coldResist = 2 } },
      ["4"]  = { name = 'Tracker Instinct', description = 'You read the wild like a map.', stats = { animalResist = 6, coldResist = 3, stealthModifier = 2 } },
      ["6"]  = { name = 'Relentless Hunt', description = 'You keep moving through pain and cold.', stats = { armorBase = 2, bulletResist = 4, staminaCostModifier = -2 } },
      ["8"]  = { name = 'Winter Alpha', description = 'Cold no longer slows you.', stats = { armorBase = 2, animalResist = 5, coldResist = 4, noiseModifier = -3 } },
      ["10"] = { name = 'Alpha Predator', description = 'You move like the pack leader.', stats = { armorBase = 2, animalResist = 3, stealthModifier = 4 }, passive = 'wolf_detection_reduction' },
    },
  },

  bear_barbarian = {
    name = 'Bear Barbarian',
    description = 'Crude but brutally effective armor forged from a grizzly bear.',
    icon = '🐻',
    image = 'assets/setresim/bear_barbarian.png',
    pieces = {
      'bear_war_helm', 'bear_skull_pauldrons', 'bear_hide_vest', 'bear_hide_chaps', 'bear_tread_boots',
      'bear_claw_gauntlets', 'bear_war_belt', 'bear_bone_amulet', 'bear_rage_totem', 'bear_iron_charm',
    },
    bonuses = {
      ["2"]  = { name = 'Berserker Blood', description = 'Your blood runs wild and fierce.', stats = { bulletResist = 4, meleeResist = 3 } },
      ["4"]  = { name = 'Hide of the Grizzly', description = 'Your stance becomes unshakable.', stats = { armorBase = 2, bulletResist = 4, meleeResist = 4, fallResist = 4 } },
      ["6"]  = { name = 'Bonebreaker', description = 'You trade speed for power.', stats = { bulletResist = 4, meleeResist = 4, staminaCostModifier = -2 } },
      ["8"]  = { name = 'Mountain-Worn', description = 'You resist impact and recoil.', stats = { armorBase = 2, bulletResist = 2, meleeResist = 2, fallResist = 6 } },
      ["10"] = { name = 'Grizzly Might', description = 'You strike with the fury of a charging bear.', stats = { armorBase = 1, bulletResist = 1, meleeResist = 2, staminaCostModifier = -4 }, passive = 'bear_charge_resistance' },
    },
  },

  outlaw_duster = {
    name = 'Outlaw Duster',
    description = 'The attire of a quick-draw gunslinger. Lightweight and tactical.',
    icon = '🔫',
    image = 'assets/setresim/outlaw_duster.png',
    pieces = {
      'outlaw_hat', 'reinforced_duster_coat', 'outlaw_leather_vest', 'outlaw_riding_pants', 'gunslinger_boots',
      'gunslinger_gloves', 'quickdraw_belt', 'gamblers_amulet', 'outlaw_coin', 'outlaw_lucky_card',
    },
    bonuses = {
      ["2"]  = { name = 'Quick Draw', description = 'Your reflexes sharpen like a drawn blade.', stats = { bulletResist = 4, stealthModifier = 2 } },
      ["4"]  = { name = 'Deadeye Rhythm', description = 'You waste less focus under pressure.', stats = { bulletResist = 5, deadeyeDrainModifier = -2 } },
      ["6"]  = { name = "Gunslinger's Pace", description = 'You stay light on your feet.', stats = { armorBase = 1, bulletResist = 3, stealthModifier = 2 } },
      ["8"]  = { name = 'Duster Tactics', description = 'Plating and timing keep you alive.', stats = { armorBase = 1, bulletResist = 2, deadeyeDrainModifier = -2 } },
      ["10"] = { name = "Gunslinger's Edge", description = 'You move like the wind and strike like lightning.', stats = { armorBase = 1, bulletResist = 2, stealthModifier = 3 }, passive = 'bullet_dodge_chance' },
    },
  },

  mystic_scholar = {
    name = 'Mystic Scholar',
    description = 'Attire of an educated wanderer, imbued with protective enchantments.',
    icon = '📚',
    image = 'assets/setresim/mystic_scholar.png',
    pieces = {
      'scholar_cap', 'scholar_coat', 'scholar_vest', 'scholar_trousers', 'scholar_boots',
      'scholar_gloves', 'scholar_satchel_belt', 'scholar_amulet', 'scholar_lens', 'scholar_seal',
    },
    bonuses = {
      ["2"]  = { name = 'Knowledge is Power', description = 'You gain understanding of the elements.', stats = { coldResist = 4, heatResist = 3 } },
      ["4"]  = { name = 'Weathered Wisdom', description = 'You endure climates with ease.', stats = { armorBase = 1, coldResist = 5, heatResist = 4 } },
      ["6"]  = { name = 'Prepared Traveler', description = 'Your kit works with you, not against you.', stats = { armorBase = 1, bulletResist = 3, staminaCostModifier = -2 } },
      ["8"]  = { name = 'Arcane Lining', description = 'Your robes deflect misfortune.', stats = { armorBase = 1, coldResist = 6, heatResist = 5 } },
      ["10"] = { name = 'Mystical Insight', description = 'Your perception pierces through deception.', stats = { armorBase = 1, coldResist = 5, heatResist = 4, staminaCostModifier = -3 }, passive = 'enemy_detection_boost' },
    },
  },

  snake_oil_salesman = {
    name = 'Snake Oil Salesman',
    description = 'Deceptive attire favored by charlatans and poison dealers.',
    icon = '🐍',
    image = 'assets/setresim/snake_oil_salesman.png',
    pieces = {
      'snake_oil_hat', 'snake_slick_coat', 'snake_pattern_vest', 'snake_hide_pants', 'snake_silent_boots',
      'snake_needle_gloves', 'poison_flask_belt', 'serpent_amulet', 'venom_ring', 'antidote_charm',
    },
    bonuses = {
      ["2"]  = { name = "Serpent's Cunning", description = 'Your deception becomes harder to see through.', stats = { poisonResist = 2, stealthModifier = 2 } },
      ["4"]  = { name = 'Toxic Tolerance', description = 'You resist venoms and suspicion.', stats = { poisonResist = 3, stealthModifier = 2, animalResist = 2 } },
      ["6"]  = { name = 'Hidden Vials', description = 'Your kit supports your craft.', stats = { armorBase = 1, poisonResist = 2, bulletResist = 2 } },
      ["8"]  = { name = 'Venomproof', description = 'Poisons barely bite anymore.', stats = { armorBase = 1, poisonResist = 2, bulletResist = 1, stealthModifier = 2 } },
      ["10"] = { name = 'Venomous Presence', description = 'Invisible and deadly.', stats = { armorBase = 1, poisonResist = 1, stealthModifier = 2 }, passive = 'poison_aura' },
    },
  },

  night_stalker = {
    name = 'Night Stalker',
    description = 'The garb of assassins and shadow hunters. Darkness is your sanctuary.',
    icon = '🌙',
    image = 'assets/setresim/night_stalker.png',
    pieces = {
      'hood_of_dusk', 'shadow_cloak', 'night_assassin_vest', 'dusk_pants', 'obsidian_boots',
      'midnight_gloves', 'shadow_belt', 'moonstone_amulet', 'silent_token', 'assassin_mark',
    },
    bonuses = {
      ["2"]  = { name = 'Fade Into Shadow', description = 'You become harder to spot in the darkness.', stats = { stealthModifier = 5, noiseModifier = -3 } },
      ["4"]  = { name = 'Quiet Footfall', description = 'Your movement is almost silent.', stats = { stealthModifier = 6, noiseModifier = -4, bulletResist = 2 } },
      ["6"]  = { name = 'Cold Precision', description = 'You spend less effort to stay lethal.', stats = { armorBase = 1, stealthModifier = 7, noiseModifier = -3 } },
      ["8"]  = { name = 'Shadow Armor', description = 'Darkness protects you.', stats = { bulletResist = 4, stealthModifier = 6, noiseModifier = -3 } },
      ["10"] = { name = 'Silent Executioner', description = 'Strike without a trace.', stats = { armorBase = 1, bulletResist = 2, stealthModifier = 4, noiseModifier = -2 }, passive = 'assassination_expertise' },
    },
  },

  wild_west_legend = {
    name = 'Wild West Legend',
    description = 'The iconic outfit of frontier lawmen and legendary gunslingers.',
    icon = '🤠',
    image = 'assets/setresim/wild_west_legend.png',
    pieces = {
      'frontier_hat', 'marshal_badge_vest', 'deputy_leather_vest', 'legend_trousers', 'ranger_spurs',
      'lawman_gloves', 'marshal_belt', 'badge_amulet', 'legend_medal', 'legend_token',
    },
    bonuses = {
      ["2"]  = { name = 'Law of the Land', description = 'Respect flows from your presence.', stats = { armorBase = 1, bulletResist = 2, intimidation = 1 } },
      ["4"]  = { name = 'Frontier Authority', description = 'People hesitate to challenge you.', stats = { armorBase = 1, bulletResist = 2, meleeResist = 2, intimidation = 2 } },
      ["6"]  = { name = 'Steady Aim', description = 'You waste less energy in a fight.', stats = { armorBase = 1, bulletResist = 1, meleeResist = 1, staminaCostModifier = -1 } },
      ["8"]  = { name = 'Wanted Name', description = 'Your reputation protects you.', stats = { armorBase = 1, bulletResist = 1, meleeResist = 1, intimidation = 3 } },
      ["10"] = { name = 'Legendary Gunslinger', description = 'Feared and revered across the frontier.', stats = { bulletResist = 1, intimidation = 4 }, passive = 'quickdraw_mastery' },
    },
  },
}
