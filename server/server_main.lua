
local function dprint(...)
  if not Config.Debug then return end
  print('^3[cas-armour]^7', ...)
end

local BoneIdSlotMap = {
  [33869] = 'gloves',
  [4126]  = 'gloves',
  [34606] = 'gloves',
  [22798] = 'gloves',
  [53675] = 'gloves',
  [54187] = 'gloves',
  [49600] = 'gloves',
  [29881] = 'gloves',
  [38989] = 'gloves',
  [9246]  = 'gloves',
  [37709] = 'gloves',
  [7966]  = 'gloves',

  [45454] = 'boots',
  [33646] = 'boots',
  [65245] = 'boots',
  [35502] = 'boots',
  [43312] = 'boots',
  [55120] = 'boots',
  [38142] = 'boots',
  [2718]  = 'boots',
  [10710] = 'boots',
  [40453] = 'boots',
  [54157] = 'boots',

  [65478] = 'pants',
  [6884]  = 'pants',
  [58630] = 'pants',
  [60844] = 'pants',
  [41287] = 'pants',
  [21568] = 'pants',

  [53684] = 'torso',
  [27792] = 'torso',
  [6757]  = 'torso',
  [6758]  = 'torso',
  [14410] = 'torso',
  [14411] = 'torso',
  [14412] = 'torso',
  [56200] = 'torso',

  [21030] = 'head',
  [27981] = 'head',
  [57278] = 'head',
}

local BoneIndexSlotMap = {
  [201] = 'gloves',
  [299] = 'gloves',
  [200] = 'gloves',
  [298] = 'gloves',
  [199] = 'gloves',
  [297] = 'gloves',

  [3]  = 'boots',
  [34] = 'boots',
  [4]  = 'boots',
  [35] = 'boots',
  [5]  = 'boots',
  [36] = 'boots',
  [40] = 'boots',
  [9]  = 'boots',

  [2]  = 'pants',
  [33] = 'pants',
  [97] = 'pants',
  [110]= 'pants',

  [131] = 'torso',
  [132] = 'torso',
  [133] = 'torso',
  [134] = 'torso',
  [1]   = 'torso',

  [144] = 'head',
  [166] = 'head',
}

local function ResolveWearSlotFromPayload(payload, slots)
  local boneId = tonumber(payload.boneId or 0) or 0
  local slotKey = (boneId ~= 0) and BoneIdSlotMap[boneId] or nil

  if not slotKey then
    local boneIndex = tonumber(payload.boneIndex or 0) or 0
    if boneIndex ~= 0 then
      slotKey = BoneIndexSlotMap[boneIndex]
    end
  end

  if not slotKey and type(payload.boneCandidates) == 'table' then
    for _, v in ipairs(payload.boneCandidates) do
      local n = tonumber(v or 0) or 0
      if n ~= 0 then
        slotKey = BoneIdSlotMap[n] or BoneIndexSlotMap[n]
        if slotKey then break end
      end
    end
  end

  if slotKey == 'torso' then
    if slots['vest'] and slots['vest'].pieceId then
      return 'vest'
    end
    return 'chest'
  end

  return slotKey
end

local function IsPositiveResult(res)
  if res == true then return true end
  if type(res) == 'number' then return res > 0 end
  if type(res) == 'string' then
    local s = string.lower(res)
    return s == 'true' or s == '1' or s == 'ok' or s == 'success'
  end
  return false
end

local function InventoryHasItemId(src, itemId)
  if not itemId then return false end
  local inv = FW.GetInventoryItems(src)
  for _, it in ipairs(inv or {}) do
    local id = it.id
    if tonumber(id) and tonumber(id) == tonumber(itemId) then
      return true
    end
  end
  return false
end

local function GetCharacterId(src)
  if ServerState.charIdBySource[src] then return ServerState.charIdBySource[src] end

  local charId = FW.GetCharacterId(src)
  if not charId then return nil end

  ServerState.charIdBySource[src] = charId
  return charId
end

local function DefaultEquipment()
  return { slots = {} }
end

local function DBFetchEquipment(charId)
  local rows = MySQL.query.await('SELECT equipment FROM cas_armour_equipment WHERE char_identifier = ? LIMIT 1', { charId })
  if rows and rows[1] and rows[1].equipment then
    local ok, decoded = pcall(json.decode, rows[1].equipment)
    if ok and type(decoded) == 'table' then
      decoded.slots = decoded.slots or {}
      return decoded
    end
  end
  return DefaultEquipment()
end

local function DBSaveEquipment(charId, equipment)
  equipment = equipment or DefaultEquipment()
  equipment.slots = equipment.slots or {}

  local encoded = json.encode(equipment)

  MySQL.update.await([[
    INSERT INTO cas_armour_equipment (char_identifier, equipment)
    VALUES (?, ?)
    ON DUPLICATE KEY UPDATE equipment = VALUES(equipment), updated_at = CURRENT_TIMESTAMP
  ]], { charId, encoded })
end

local function BuildItemMetadata(pieceId, condition, maxCondition)
  return {
    casArmour = {
      pieceId = pieceId,
      condition = Shared.Round(condition or 0),
      maxCondition = Shared.Round(maxCondition or 0),
    }
  }
end

local function FilterArmorItems(inv)
  local out = {}
  for _, it in ipairs(inv or {}) do
    if it and it.name and Config.ArmorPieces[it.name] then
      table.insert(out, {
        id = it.id,
        name = it.name,
        label = it.label,
        desc = it.desc,
        count = it.count or 1,
        metadata = it.metadata or {},
        percentage = it.percentage,
      })
    end
  end
  return out
end

local function SyncToClient(src, openUi)
  local charId = GetCharacterId(src)
  if not charId then
    FW.Notify(src, 'Character not ready yet. Try again in a moment.')
    return
  end

  local equipment = ServerState.equipmentBySource[src] or DefaultEquipment()
  local inv = FilterArmorItems(FW.GetInventoryItems(src))

  TriggerClientEvent('cas-armour:client:setData', src, {
    equipment = equipment,
    inventory = inv,
    openUi = openUi == true,
  })
end

local function SyncEquipmentToClient(src)
  local equipment = ServerState.equipmentBySource[src] or DefaultEquipment()
  TriggerClientEvent('cas-armour:client:updateEquipment', src, { equipment = equipment })
end

local function EnsureLoaded(src)
  if ServerState.equipmentBySource[src] then return true end
  local charId = GetCharacterId(src)
  if not charId then return false end
  ServerState.equipmentBySource[src] = DBFetchEquipment(charId)
  return true
end

local function ResolveTargetSlot(piece, requestedSlot, equipment)
  if requestedSlot and requestedSlot ~= '' then
    return requestedSlot
  end

  local slot = piece.slot
  if Config.MultiSlotAliases[slot] then
    for _, s in ipairs(Config.MultiSlotAliases[slot]) do
      if not (equipment.slots and equipment.slots[s] and equipment.slots[s].pieceId) then
        return s
      end
    end
    return nil
  end

  return slot
end

local function SlotCompatible(piece, targetSlot)
  if not targetSlot or targetSlot == '' then return false end

  if piece.slot == targetSlot then return true end

  local alias = Config.MultiSlotAliases[piece.slot]
  if alias then
    for _, s in ipairs(alias) do
      if s == targetSlot then return true end
    end
  end

  return false
end

local function UnequipSlotInternal(src, equipment, slot)
  local s = equipment.slots[slot]
  if not s or not s.pieceId then return true end

  local pieceId = s.pieceId
  local piece = Config.ArmorPieces[pieceId]
  if not piece then
    equipment.slots[slot] = nil
    return true
  end

  local metadata = BuildItemMetadata(pieceId, s.condition or piece.condition or 0, s.maxCondition or piece.maxCondition or 0)

  if not FW.CanCarryItem(src, piece.itemName, 1) then
    return false, 'Inventory full. Cannot unequip.'
  end

  FW.AddItem(src, piece.itemName, 1, metadata)
  equipment.slots[slot] = nil
  return true
end

local function HandleEquip(src, data)
  if type(data) ~= 'table' then return end
  if not EnsureLoaded(src) then
    FW.Notify(src, 'Character not ready yet.')
    return
  end

  local equipment = ServerState.equipmentBySource[src]
  local pieceId = data.pieceId or data.itemName
  if not pieceId or not Config.ArmorPieces[pieceId] then
    FW.Notify(src, 'Invalid armor piece.')
    return
  end

  local piece = Config.ArmorPieces[pieceId]

  local targetSlot = ResolveTargetSlot(piece, data.targetSlot, equipment)
  if not targetSlot or not SlotCompatible(piece, targetSlot) then
    FW.Notify(src, 'Wrong slot for this item.')
    return
  end

  if equipment.slots[targetSlot] and equipment.slots[targetSlot].pieceId then
    if not Config.Tuning.AllowSwap then
      FW.Notify(src, 'Slot is occupied.')
      return
    end

    local ok, err = UnequipSlotInternal(src, equipment, targetSlot)
    if not ok then
      FW.Notify(src, err or 'Cannot swap items.')
      return
    end
  end

  local removedOk = false
  local itemIdNum = tonumber(data.itemId)

  if itemIdNum then
    local r = FW.SubItemById(src, itemIdNum, 1)
    if IsPositiveResult(r) then
      removedOk = true
    elseif r == false then
      local r2 = FW.SubItem(src, piece.itemName, 1, {})
      if r2 ~= false then
        removedOk = true
      else
        removedOk = not InventoryHasItemId(src, itemIdNum)
      end
    else
      local r3 = FW.SubItem(src, piece.itemName, 1, data.metadata or {})
      if r3 == false then
        r3 = FW.SubItem(src, piece.itemName, 1, {})
      end
      removedOk = (r3 ~= false)
    end
  else
    local r4 = FW.SubItem(src, piece.itemName, 1, data.metadata or {})
    if r4 == false then
      r4 = FW.SubItem(src, piece.itemName, 1, {})
    end
    removedOk = (r4 ~= false)
  end
  dprint('Removed item result:', removedOk)
  if not removedOk then
    FW.Notify(src, 'Could not remove item from inventory.')
    SyncToClient(src, false)
    return
  end

  local cond = piece.condition
  local maxC = piece.maxCondition

  if data.metadata and type(data.metadata) == 'table' then
    local meta = data.metadata.casArmour or data.metadata
    if meta and type(meta) == 'table' then
      if meta.condition then cond = tonumber(meta.condition) or cond end
      if meta.maxCondition then maxC = tonumber(meta.maxCondition) or maxC end
    end
  end

  equipment.slots[targetSlot] = {
    pieceId = pieceId,
    condition = Shared.Round(cond or 0),
    maxCondition = Shared.Round(maxC or 0),
  }

  local charId = GetCharacterId(src)
  local okSave, saveErr = pcall(DBSaveEquipment, charId, equipment)
  if not okSave then
    FW.AddItem(src, piece.itemName, 1, BuildItemMetadata(pieceId, cond, maxC))
    equipment.slots[targetSlot] = nil
    FW.Notify(src, 'Equip failed (DB). Item was returned to inventory.')
  end

  SyncToClient(src, false)
end

local function HandleUnequip(src, data)
  if type(data) ~= 'table' then return end
  if not EnsureLoaded(src) then return end

  local slot = data.slot
  if not slot or slot == '' then return end

  local equipment = ServerState.equipmentBySource[src]
  if not equipment.slots[slot] or not equipment.slots[slot].pieceId then
    FW.Notify(src, 'Slot is empty.')
    return
  end

  local ok, err = UnequipSlotInternal(src, equipment, slot)
  if not ok then
    FW.Notify(src, err or 'Cannot unequip.')
    return
  end

  local charId = GetCharacterId(src)
  DBSaveEquipment(charId, equipment)
  SyncToClient(src, false)
end

local WearLinkedSlots = {
  chest = {
    { slot = 'amulet',   w = 0.45 },
    { slot = 'trinket1', w = 0.30 },
    { slot = 'trinket2', w = 0.30 },
    { slot = 'belt',     w = 0.20 },
  },
  vest = {
    { slot = 'amulet',   w = 0.45 },
    { slot = 'trinket1', w = 0.30 },
    { slot = 'trinket2', w = 0.30 },
    { slot = 'belt',     w = 0.20 },
  },

  pants = {
    { slot = 'belt', w = 0.60 },
  },
}

local function ApplyWearOneSlot(slots, slotName, loss, broken)
  local s = slots[slotName]
  if not (s and s.pieceId) then return end

  local piece = Config.ArmorPieces[s.pieceId]
  if not piece then return end

  local maxC = tonumber(s.maxCondition or piece.maxCondition or 0) or 0
  local c    = tonumber(s.condition or 0) or 0

  c = c - loss

  if c <= 0 then
    table.insert(broken, { slot = slotName, pieceId = s.pieceId })
    slots[slotName] = nil
  else
    slots[slotName].condition = Shared.Round(Shared.Clamp(c, 0, maxC))
  end
end

local function ApplyWearForTargetSlot(slots, targetSlot, wearTotal, broken)
  if not targetSlot or targetSlot == '' then return end
  wearTotal = tonumber(wearTotal or 0) or 0
  if wearTotal <= 0 then return end

  local targets = {
    { slot = targetSlot, w = 1.00 }
  }

  local linked = WearLinkedSlots[targetSlot]
  if linked then
    for _, t in ipairs(linked) do
      table.insert(targets, t)
    end
  end

  local totalW = 0.0
  for _, t in ipairs(targets) do
    local s = slots[t.slot]
    if s and s.pieceId then
      totalW = totalW + (tonumber(t.w) or 1.0)
    end
  end

  if totalW <= 0 then return end

  for _, t in ipairs(targets) do
    local s = slots[t.slot]
    if s and s.pieceId then
      local w = tonumber(t.w) or 1.0
      local loss = wearTotal * (w / totalW)
      ApplyWearOneSlot(slots, t.slot, loss, broken)
    end
  end
end

local function MaybeSaveWear(src, charId, equipment, force)
  if not charId then return end
  local now = GetGameTimer()
  local interval = (Config.Tuning and Config.Tuning.DbSaveIntervalMs) or 2500
  local last = ServerState.lastDbSaveAt[src] or 0

  if force or (now - last >= interval) then
    DBSaveEquipment(charId, equipment)
    ServerState.lastDbSaveAt[src] = now
    ServerState.dirtyWear[src] = false
  else
    ServerState.dirtyWear[src] = true
  end
end

local function HandleWear(src, payload)
  if type(payload) ~= 'table' then return end
  if not EnsureLoaded(src) then return end

  local now = GetGameTimer()
  local last = ServerState.lastWearAt[src] or 0
  if now - last < 40 then return end
  ServerState.lastWearAt[src] = now

  local dmg = tonumber(payload.damage or 0) or 0
  if dmg <= 0 then return end

  local wearTotal = dmg * (Config.Tuning.WearPerDamage or 0.45)
  wearTotal = Shared.Clamp(wearTotal, 0, Config.Tuning.MaxWearPerHit or 25)
  if wearTotal <= 0 then return end

  local equipment = ServerState.equipmentBySource[src]
  local slots = equipment.slots or {}

  local targetSlot = ResolveWearSlotFromPayload(payload, slots)
  if not targetSlot then return end

  local broken = {}
  ApplyWearForTargetSlot(slots, targetSlot, wearTotal, broken)

  equipment.slots = slots

  local charId = GetCharacterId(src)
  MaybeSaveWear(src, charId, equipment, (#broken > 0))

  if #broken > 0 then
    for _, b in ipairs(broken) do
      local p = Config.ArmorPieces[b.pieceId]
      FW.Notify(src, ('%s broke!'):format(p and p.name or b.pieceId))
    end
  end

  SyncEquipmentToClient(src)
end

local function HandleWearBatch(src, payload)
  if type(payload) ~= 'table' or type(payload.merged) ~= 'table' then return end
  if not EnsureLoaded(src) then return end

  local equipment = ServerState.equipmentBySource[src]
  local slots = equipment.slots or {}
  local broken = {}
  local any = false

  for slotName, agg in pairs(payload.merged) do
    if type(slotName) == 'string' and type(agg) == 'table' then
      local lossSum = tonumber(agg.loss or 0) or 0
      local hits = tonumber(agg.hits or 1) or 1
      if hits < 1 then hits = 1 end

      if lossSum > 0 then
        local per = lossSum / hits
        for i = 1, hits do
          local chunk = per
          if i == hits then
            chunk = lossSum - (per * (hits - 1))
          end
          chunk = tonumber(chunk) or 0
          if chunk > 0 then
            ApplyWearForTargetSlot(slots, slotName, chunk, broken)
            any = true
          end
        end
      end
    end
  end

  if not any then return end

  equipment.slots = slots

  local charId = GetCharacterId(src)
  MaybeSaveWear(src, charId, equipment, (#broken > 0) or (payload.forceSave == true))

  if #broken > 0 then
    for _, b in ipairs(broken) do
      local p = Config.ArmorPieces[b.pieceId]
      FW.Notify(src, ('%s broke!'):format(p and p.name or b.pieceId))
    end
  end

  SyncEquipmentToClient(src)
end

CreateThread(function()
  while true do
    local interval = (Config.Tuning and Config.Tuning.DbSaveIntervalMs) or 2500
    Wait(interval)

    local now = GetGameTimer()
    for src, dirty in pairs(ServerState.dirtyWear) do
      if dirty then
        local last = ServerState.lastDbSaveAt[src] or 0
        if now - last >= interval then
          local charId = GetCharacterId(src)
          local equipment = ServerState.equipmentBySource[src]
          if charId and equipment then
            DBSaveEquipment(charId, equipment)
            ServerState.lastDbSaveAt[src] = now
            ServerState.dirtyWear[src] = false
          end
        end
      end
    end
  end
end)

local function HandleCraft(src, data)
  if type(data) ~= 'table' then return end
  if not EnsureLoaded(src) then return end

  local pieceId = data.pieceId
  local piece = pieceId and Config.ArmorPieces[pieceId] or nil
  if not piece or not piece.crafting or not piece.crafting.enabled then
    FW.Notify(src, 'This item cannot be crafted.')
    return
  end

  local inv = FW.GetInventoryItems(src)
  local counts = {}
  for _, it in ipairs(inv) do
    counts[it.name] = (counts[it.name] or 0) + (it.count or 1)
  end

  for _, req in ipairs(piece.crafting.requirements or {}) do
    if (counts[req.item] or 0) < (req.amount or 1) then
      FW.Notify(src, ('Missing: %sx %s'):format(req.amount or 1, req.item))
      return
    end
  end

  local removed = {}
  for _, req in ipairs(piece.crafting.requirements or {}) do
    FW.SubItem(src, req.item, req.amount or 1, {})
    table.insert(removed, req)
  end

  if not FW.CanCarryItem(src, piece.itemName, 1) then
    for _, req in ipairs(removed) do
      FW.AddItem(src, req.item, req.amount or 1, {})
    end
    FW.Notify(src, 'Inventory full. Craft failed.')
    return
  end

  FW.AddItem(src, piece.itemName, 1, BuildItemMetadata(pieceId, piece.condition, piece.maxCondition))
  FW.Notify(src, ('Crafted: %s'):format(piece.name or pieceId))
  SyncToClient(src, false)
end

RegisterNetEvent('cas-armour:server:loadEquipment', function()
  local src = source
  local charId = GetCharacterId(src)
  if not charId then return end

  ServerState.equipmentBySource[src] = DBFetchEquipment(charId)
  SyncToClient(src, false)
end)

RegisterNetEvent('cas-armour:server:requestData', function()
  local src = source
  if not EnsureLoaded(src) then
    FW.Notify(src, 'Character not ready yet.')
    return
  end
  SyncToClient(src, false)
end)

RegisterNetEvent('cas-armour:server:equip', function(data)
  HandleEquip(source, data)
end)

RegisterNetEvent('cas-armour:server:unequip', function(data)
  HandleUnequip(source, data)
end)

RegisterNetEvent('cas-armour:server:wear', function(payload)
  HandleWear(source, payload)
end)

RegisterNetEvent('cas-armour:server:wearBatch', function(payload)
  HandleWearBatch(source, payload)
end)

RegisterNetEvent('cas-armour:server:craft', function(data)
  HandleCraft(source, data)
end)

CreateThread(function()
  FW.WaitReady()

  if not Config.RegisterUsableItems then return end

  for pieceId, piece in pairs(Config.ArmorPieces) do
    FW.RegisterUsableItem(piece.itemName, function(data)
      local src = data.source
      HandleEquip(src, {
        pieceId = pieceId,
        itemName = piece.itemName,
        itemId = data.id,
        targetSlot = piece.slot,
        metadata = data.metadata or {},
      })
    end)
  end

  dprint('Usable items registered for', Framework.Name)
end)

AddEventHandler('playerDropped', function()
  local src = source

  if ServerState.dirtyWear and ServerState.dirtyWear[src] then
    local charId = ServerState.charIdBySource[src] or GetCharacterId(src)
    local equipment = ServerState.equipmentBySource[src]
    if charId and equipment then
      DBSaveEquipment(charId, equipment)
    end
    ServerState.dirtyWear[src] = false
  end
  ServerState.equipmentBySource[src] = nil
  ServerState.charIdBySource[src] = nil
  ServerState.lastWearAt[src] = nil
end)

exports('GetEquipment', function(src)
  if not EnsureLoaded(src) then return DefaultEquipment() end
  return ServerState.equipmentBySource[src]
end)
