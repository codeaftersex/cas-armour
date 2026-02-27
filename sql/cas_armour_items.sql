-- =====================================================
-- CAS ARMOUR - VORP Inventory Items
-- Run this SQL on your VORP database to register
-- all 70 armor pieces + 14 crafting materials.
-- =====================================================

-- =====================================================
-- EQUIPMENT TABLE (character armor storage)
-- =====================================================
CREATE TABLE IF NOT EXISTS `cas_armour_equipment` (
  `char_identifier` VARCHAR(64) NOT NULL,
  `equipment` LONGTEXT NOT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`char_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =====================================================
-- ARMOR PIECES (70 items across 7 sets)
-- =====================================================

-- ----- WOLF HUNTER SET (10 pieces) -----
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
('wolf_skull_helm',     'Wolf Skull Helm',      1, 1, 'item_standard', 1),
('wolf_pelt_coat',      'Wolf Pelt Coat',       1, 1, 'item_standard', 1),
('wolf_fur_gloves',     'Wolf Fur Gloves',      1, 1, 'item_standard', 1),
('wolf_tracker_vest',   'Wolf Tracker Vest',    1, 1, 'item_standard', 1),
('wolf_hide_chaps',     'Wolf Hide Chaps',      1, 1, 'item_standard', 1),
('wolf_hunter_boots',   'Wolf Hunter Boots',    1, 1, 'item_standard', 1),
('wolf_hunting_belt',   'Wolf Hunting Belt',    1, 1, 'item_standard', 1),
('wolf_fang_amulet',    'Wolf Fang Amulet',     1, 1, 'item_standard', 1),
('wolf_totem_trinket',  'Wolf Totem',           1, 1, 'item_standard', 1),
('wolf_pack_charm',     'Pack Charm',           1, 1, 'item_standard', 1);

-- ----- BEAR BARBARIAN SET (10 pieces) -----
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
('bear_war_helm',         'Bear War Helm',          1, 1, 'item_standard', 1),
('bear_skull_pauldrons',  'Bear Skull Pauldrons',   1, 1, 'item_standard', 1),
('bear_hide_vest',        'Bear Hide Vest',         1, 1, 'item_standard', 1),
('bear_hide_chaps',       'Bear Hide Chaps',        1, 1, 'item_standard', 1),
('bear_tread_boots',      'Bear Tread Boots',       1, 1, 'item_standard', 1),
('bear_claw_gauntlets',   'Bear Claw Gauntlets',    1, 1, 'item_standard', 1),
('bear_war_belt',         'Bear War Belt',          1, 1, 'item_standard', 1),
('bear_bone_amulet',      'Bear Bone Amulet',       1, 1, 'item_standard', 1),
('bear_rage_totem',       'Rage Totem',             1, 1, 'item_standard', 1),
('bear_iron_charm',       'Iron Charm',             1, 1, 'item_standard', 1);

-- ----- OUTLAW DUSTER SET (10 pieces) -----
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
('outlaw_hat',              'Outlaw Hat',               1, 1, 'item_standard', 1),
('reinforced_duster_coat',  'Reinforced Duster Coat',   1, 1, 'item_standard', 1),
('outlaw_leather_vest',     'Outlaw Leather Vest',      1, 1, 'item_standard', 1),
('outlaw_riding_pants',     'Outlaw Riding Pants',      1, 1, 'item_standard', 1),
('gunslinger_boots',        'Gunslinger Boots',         1, 1, 'item_standard', 1),
('gunslinger_gloves',       'Gunslinger Gloves',        1, 1, 'item_standard', 1),
('quickdraw_belt',          'Quickdraw Belt',           1, 1, 'item_standard', 1),
('gamblers_amulet',         'Gambler\'s Amulet',        1, 1, 'item_standard', 1),
('outlaw_coin',             'Outlaw Coin',              1, 1, 'item_standard', 1),
('outlaw_lucky_card',       'Lucky Card',               1, 1, 'item_standard', 1);

-- ----- MYSTIC SCHOLAR SET (10 pieces) -----
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
('scholar_cap',           'Scholar\'s Cap',             1, 1, 'item_standard', 1),
('scholar_coat',          'Scholar\'s Weathered Coat',  1, 1, 'item_standard', 1),
('scholar_vest',          'Scholar\'s Travel Vest',     1, 1, 'item_standard', 1),
('scholar_trousers',      'Scholar\'s Trousers',        1, 1, 'item_standard', 1),
('scholar_boots',         'Scholar\'s Boots',           1, 1, 'item_standard', 1),
('scholar_gloves',        'Scholar\'s Leather Gloves',  1, 1, 'item_standard', 1),
('scholar_satchel_belt',  'Scholar\'s Satchel Belt',    1, 1, 'item_standard', 1),
('scholar_amulet',        'Mystic Amulet',              1, 1, 'item_standard', 1),
('scholar_lens',          'Runed Lens',                 1, 1, 'item_standard', 1),
('scholar_seal',          'Scholar Seal',               1, 1, 'item_standard', 1);

-- ----- SNAKE OIL SALESMAN SET (10 pieces) -----
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
('snake_oil_hat',       'Snake Oil Hat',        1, 1, 'item_standard', 1),
('snake_slick_coat',    'Slick Dealer Coat',    1, 1, 'item_standard', 1),
('snake_pattern_vest',  'Snake Pattern Vest',   1, 1, 'item_standard', 1),
('snake_hide_pants',    'Snake Hide Pants',     1, 1, 'item_standard', 1),
('snake_silent_boots',  'Silent Serpent Boots',  1, 1, 'item_standard', 1),
('snake_needle_gloves', 'Needle Gloves',        1, 1, 'item_standard', 1),
('poison_flask_belt',   'Poison Flask Belt',    1, 1, 'item_standard', 1),
('serpent_amulet',      'Serpent Amulet',       1, 1, 'item_standard', 1),
('venom_ring',          'Venom Ring',           1, 1, 'item_standard', 1),
('antidote_charm',      'Antidote Charm',       1, 1, 'item_standard', 1);

-- ----- NIGHT STALKER SET (10 pieces) -----
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
('hood_of_dusk',         'Hood of Dusk',         1, 1, 'item_standard', 1),
('shadow_cloak',         'Shadow Cloak',         1, 1, 'item_standard', 1),
('night_assassin_vest',  'Assassin Vest',        1, 1, 'item_standard', 1),
('dusk_pants',           'Dusk Pants',           1, 1, 'item_standard', 1),
('obsidian_boots',       'Obsidian Boots',       1, 1, 'item_standard', 1),
('midnight_gloves',      'Midnight Gloves',      1, 1, 'item_standard', 1),
('shadow_belt',          'Shadow Belt',          1, 1, 'item_standard', 1),
('moonstone_amulet',     'Moonstone Amulet',     1, 1, 'item_standard', 1),
('silent_token',         'Silent Token',         1, 1, 'item_standard', 1),
('assassin_mark',        'Assassin\'s Mark',     1, 1, 'item_standard', 1);

-- ----- WILD WEST LEGEND SET (10 pieces) -----
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
('frontier_hat',          'Frontier Lawman Hat',    1, 1, 'item_standard', 1),
('marshal_badge_vest',    'Marshal Badge Vest',     1, 1, 'item_standard', 1),
('deputy_leather_vest',   'Deputy Leather Vest',    1, 1, 'item_standard', 1),
('legend_trousers',       'Legend Trousers',        1, 1, 'item_standard', 1),
('ranger_spurs',          'Ranger Spurs',           1, 1, 'item_standard', 1),
('lawman_gloves',         'Lawman Gloves',          1, 1, 'item_standard', 1),
('marshal_belt',          'Marshal Belt',           1, 1, 'item_standard', 1),
('badge_amulet',          'Badge Amulet',           1, 1, 'item_standard', 1),
('legend_medal',          'Legend Medal',           1, 1, 'item_standard', 1),
('legend_token',          'Legend Token',           1, 1, 'item_standard', 1);


-- =====================================================
-- CRAFTING MATERIALS (14 items)
-- Skip if you already have these in your database.
-- =====================================================
INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`) VALUES
('wolf_pelt',       'Wolf Pelt',        5, 1, 'item_standard', 0),
('wolf_tooth',      'Wolf Tooth',      10, 1, 'item_standard', 0),
('bear_pelt',       'Bear Pelt',        5, 1, 'item_standard', 0),
('bear_bone',       'Bear Bone',       10, 1, 'item_standard', 0),
('bear_claw',       'Bear Claw',       10, 1, 'item_standard', 0),
('snake_skin',      'Snake Skin',       5, 1, 'item_standard', 0),
('dark_leather',    'Dark Leather',    10, 1, 'item_standard', 0),
('leather',         'Leather',         20, 1, 'item_standard', 0),
('leather_strips',  'Leather Strips',  20, 1, 'item_standard', 0),
('cloth',           'Cloth',           20, 1, 'item_standard', 0),
('cotton_cloth',    'Cotton Cloth',    10, 1, 'item_standard', 0),
('cloth_duster',    'Cloth Duster',     5, 1, 'item_standard', 0),
('fur',             'Fur',             10, 1, 'item_standard', 0),
('steel_plate',     'Steel Plate',     10, 1, 'item_standard', 0),
('iron_bar',        'Iron Bar',        10, 1, 'item_standard', 0),
('gold_bar',        'Gold Bar',        10, 1, 'item_standard', 0),
('gem',             'Gem',             10, 1, 'item_standard', 0);
