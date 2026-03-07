
local function dprint(...)
  if not Config.Debug then return end
  print('^3[cas-armour]^7', ...)
end

local CORE_HEALTH  = 0
local CORE_STAMINA = 1
local CORE_DEADEYE = 2

local function GetCoreValue(ped, coreIndex)
  local ok, v = pcall(function()
    return Citizen.InvokeNative(0x36731AC041289BB1, ped, coreIndex)
  end)
  if ok and type(v) == 'number' then return v end
  return nil
end

local function SetCoreValue(ped, coreIndex, value)
  if type(value) ~= 'number' then return end
  value = Shared.Clamp(value, 0, 100)
  value = Shared.Round(value)
  pcall(function()
    Citizen.InvokeNative(0xC6258F41D86676E0, ped, coreIndex, value)
  end)
end

local function GetAmbientTemperature(ped)
  local c = GetEntityCoords(ped)
  local ok, t = pcall(GetTemperatureAtCoords, c.x, c.y, c.z)
  if ok and type(t) == 'number' then
    dprint(('Temperature: %.1f'):format(t))
    return t
  end
  return nil
end

local ArmourCam = nil
local ArmourCamActive = false

local ZoomCam = nil
local IsZoomed = false

local function v3(x,y,z) return vector3(x+0.0, y+0.0, z+0.0) end
local function v3add(a,b) return v3(a.x+b.x, a.y+b.y, a.z+b.z) end
local function v3mul(a,s) return v3(a.x*s, a.y*s, a.z*s) end

local function StartArmourCam()
  if not Config.CinematicCam or not Config.CinematicCam.enabled then return end
  if ArmourCamActive then return end

  local ped = PlayerPedId()
  if not ped or ped == 0 or not DoesEntityExist(ped) then return end

  ClearPedTasks(ped)

  local coords = GetEntityCoords(ped)
  local fwd = GetEntityForwardVector(ped)
  local right = v3(-fwd.y, fwd.x, 0.0)

  local dist = Config.CinematicCam.distance or 2.4
  local height = Config.CinematicCam.height or 0.5
  local side = Config.CinematicCam.offsetRight or 0.2

  local camPos = v3add(coords, v3add(v3mul(fwd, dist), v3add(v3mul(right, side), v3(0.0, 0.0, height))))

  local lookAt = v3add(coords, v3(0.0, 0.0, height))

  ArmourCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0, (Config.CinematicCam.fov or 36.0), false, 0)

  TaskTurnPedToFaceCoord(ped, camPos.x, camPos.y, camPos.z, 600)

  PointCamAtCoord(ArmourCam, lookAt.x, lookAt.y, lookAt.z)

  local dof = Config.CinematicCam.dof
  if dof and dof.enabled then
    Citizen.InvokeNative(0xCC23AA1A7CBFE840, true, true, dof.nearDof or 0.5, dof.farDof or 3.8, dof.strength or 1.0, 0.0)
  end

  SetCamActive(ArmourCam, true)
  RenderScriptCams(true, true, (Config.CinematicCam.transitionIn or 600), true, true)

  ArmourCamActive = true

  if Config.CinematicCam.freezePlayer then
    CreateThread(function()
      Wait(750)
      if ArmourCamActive then
        local p = PlayerPedId()
        if p and p ~= 0 and DoesEntityExist(p) then
          FreezeEntityPosition(p, true)
        end
      end
    end)
  end
end

local function StopArmourCam()
  if not Config.CinematicCam or not Config.CinematicCam.enabled then return end

  local ped = PlayerPedId()

  if ZoomCam and DoesCamExist(ZoomCam) then
    DestroyCam(ZoomCam, false)
  end
  ZoomCam = nil
  IsZoomed = false

  if ArmourCamActive then
    local dof = Config.CinematicCam.dof
    if dof and dof.enabled then
      Citizen.InvokeNative(0xCC23AA1A7CBFE840, false, false, 0.0, 0.0, 0.0, 0.0)
    end

    RenderScriptCams(false, true, (Config.CinematicCam.transitionOut or 400), true, true)
    if ArmourCam then
      DestroyCam(ArmourCam, false)
      ArmourCam = nil
    end
    ArmourCamActive = false
  end

  if ped and ped ~= 0 and DoesEntityExist(ped) then
    if Config.CinematicCam.freezePlayer then
      FreezeEntityPosition(ped, false)
    end
    ClearPedTasks(ped)
  end
end

local _zoomDestroyTimer = nil

local function FocusSlotCam(slotName)
  local cfg = Config.SlotCamZoom
  if not cfg or not cfg.enabled then return end
  if not ArmourCamActive then return end

  local boneInfo = Config.SlotBoneMap and Config.SlotBoneMap[slotName]
  if not boneInfo then return end

  local ped = PlayerPedId()
  if not ped or ped == 0 or not DoesEntityExist(ped) then return end

  local ov = (cfg.overrides and cfg.overrides[slotName]) or {}
  local dist = ov.dist or cfg.dist or 1.0
  local fov = ov.fov or cfg.fov or 28.0
  local offsetRight = ov.offsetRight or cfg.offsetRight or 0.08
  local transMs = cfg.transitionMs or 800

  local boneCoords = GetPedBoneCoords(ped, boneInfo.bone, 0.0, 0.0, 0.0)
  local fwd = GetEntityForwardVector(ped)
  local right = v3(-fwd.y, fwd.x, 0.0)

  local camPos = v3add(boneCoords, v3add(v3mul(fwd, dist), v3mul(right, offsetRight)))

  local newCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0, fov, false, 0)
  PointCamAtCoord(newCam, boneCoords.x, boneCoords.y, boneCoords.z)

  local fromCam = (IsZoomed and ZoomCam) and ZoomCam or ArmourCam
  if fromCam and DoesCamExist(fromCam) then
    SetCamActiveWithInterp(newCam, fromCam, transMs, 1, 1)
  else
    SetCamActive(newCam, true)
  end

  local oldZoom = ZoomCam
  if oldZoom and DoesCamExist(oldZoom) then
    if _zoomDestroyTimer then
      DestroyCam(oldZoom, false)
    end
  end

  ZoomCam = newCam
  IsZoomed = true

  _zoomDestroyTimer = true
  CreateThread(function()
    Wait(transMs + 100)
    if oldZoom and DoesCamExist(oldZoom) and oldZoom ~= ZoomCam then
      DestroyCam(oldZoom, false)
    end
    _zoomDestroyTimer = nil
  end)

  dprint(('FocusSlotCam: slot=%s bone=%.0f dist=%.2f fov=%.1f'):format(slotName, boneInfo.bone, dist, fov))
end

local function ResetSlotCam()
  local cfg = Config.SlotCamZoom
  if not cfg or not cfg.enabled then return end
  if not IsZoomed or not ZoomCam then return end
  if not ArmourCam or not DoesCamExist(ArmourCam) then return end

  local returnMs = cfg.returnMs or 600
  SetCamActiveWithInterp(ArmourCam, ZoomCam, returnMs, 1, 1)

  local oldZoom = ZoomCam
  ZoomCam = nil
  IsZoomed = false

  CreateThread(function()
    Wait(returnMs + 100)
    if oldZoom and DoesCamExist(oldZoom) then
      DestroyCam(oldZoom, false)
    end
  end)

  dprint('ResetSlotCam: returned to full body')
end

local function GetBoneScreenPositions()
  local ped = PlayerPedId()
  if not ped or ped == 0 or not DoesEntityExist(ped) then return nil end

  local boneMap = Config.SlotBoneMap
  if not boneMap then return nil end

  local positions = {}
  for slotName, info in pairs(boneMap) do
    local boneCoords = GetPedBoneCoords(ped, info.bone, 0.0, 0.0, 0.0)
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(boneCoords.x, boneCoords.y, boneCoords.z)
    if onScreen then
      positions[slotName] = { x = sx, y = sy, side = info.side }
    else
      positions[slotName] = { x = 0.5, y = 0.5, side = info.side }
    end
  end

  return positions
end

local function SendBonePositionsToNui()
  CreateThread(function()
    Wait(950)
    local positions = GetBoneScreenPositions()
    if positions then
      SendNUIMessage({
        action = 'cas_armour:bonePositions',
        positions = positions
      })
      dprint('Bone positions sent to NUI')
    end
  end)
end

local function NuiFocus(enable)
  ClientState.isUiOpen = enable
  SetNuiFocus(enable, enable)
  if enable then
    StartArmourCam()
    SendBonePositionsToNui()
  else
    StopArmourCam()
  end
end

local function SendStateToNui(extra)
  local uiEquipment = {}
  if ClientState.equipment and ClientState.equipment.slots then
    for _, slotName in ipairs(Config.Slots) do
      local s = ClientState.equipment.slots[slotName]
      if s and s.pieceId then
        local piece = Config.ArmorPieces[s.pieceId]
        uiEquipment[slotName] = {
          itemName = (piece and piece.itemName) or s.pieceId,
          pieceId = s.pieceId,
          condition = s.condition,
          maxCondition = s.maxCondition,
        }
      end
    end
  end

local p = {
    config = {
      slots = Config.Slots,

      armorPieces = Config.ArmorPieces,
      armorSets = Config.ArmorSets,

      pieces = Config.ArmorPieces,
      sets = Config.ArmorSets,
    },
    equipment = uiEquipment,
    inventory = (ClientState.isUiOpen and (ClientState.inventory or {})) or nil,
    stats = ClientState.stats or {},
    activeSetBonuses = ClientState.activeSetBonuses or {},
    activePassives = ClientState.activePassives or {},
  }

  if extra and type(extra) == 'table' then
    for k, v in pairs(extra) do p[k] = v end
  end

  SendNUIMessage({
    action = 'cas_armour:setState',
    payload = p
  })
end

local function QueueStateToNui(extra)
  ClientState.nuiDirty = true
  ClientState.nuiDirtyAt = GetGameTimer()
  ClientState.nuiPendingExtra = extra
end

CreateThread(function()
  while true do
    local interval = (Config.Tuning and Config.Tuning.NuiSyncIntervalMs) or 150
    Wait(interval)

    if ClientState.nuiDirty then
      ClientState.nuiDirty = false
      local extra = ClientState.nuiPendingExtra
      ClientState.nuiPendingExtra = nil
      SendStateToNui(extra)
      ClientState.lastNuiSentAt = GetGameTimer()
    end
  end
end)

local function HasAnyArmourEquipped()
  if ClientState.equipment and ClientState.equipment.slots then
    for _, slot in ipairs(Config.Slots) do
      local s = ClientState.equipment.slots[slot]
      if s and s.pieceId then return true end
    end
  end
  return false
end

local function ApplyMovementFromStats(stats)
  if not HasAnyArmourEquipped() then
    ClientState.moveMultTarget = nil
    dprint('moveMult target=nil (no armour) -> default blend 3.0')
    return 0.0
  end

  local mult = Shared.ComputeMoveMultiplier(stats)
  if type(mult) ~= 'number' then mult = 1.0 end

  mult = Shared.Clamp(mult, Config.Tuning.MinMoveMultiplier or 0.78, Config.Tuning.MaxMoveMultiplier or 1.05)

  ClientState.moveMultTarget = mult
  dprint(('moveMult target=%.3f equipped=true'):format(mult))
  return mult
end

CreateThread(function()
  while true do
    Wait(0)

    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then
      goto continue
    end

    local mult = ClientState.moveMultTarget
    if mult and mult < 1.0 then
      SetPedMaxMoveBlendRatio(ped, 3.0 * mult)
    end

    ::continue::
  end
end)

local function HasPassive(name)
  local passives = ClientState.activePassives
  if not passives then return false end
  for _, p in ipairs(passives) do
    if p.passive == name then return true end
  end
  return false
end

local PassiveState = {
  bearRagdollDisabled = false,
  enemyBlips = {},
}

local BASE_MAX_HP = nil
local ARMOR_BUFFER = 0

local function CaptureBaseMaxHp()
  if BASE_MAX_HP then return BASE_MAX_HP end
  local ped = PlayerPedId()
  if ped and ped ~= 0 and DoesEntityExist(ped) then
    local mhp = GetEntityMaxHealth(ped)
    if mhp and mhp > 0 then BASE_MAX_HP = mhp end
  end
  if not BASE_MAX_HP or BASE_MAX_HP <= 0 then BASE_MAX_HP = 200 end
  return BASE_MAX_HP
end

local function RecalcArmorBuffer()
  if ARMOR_BUFFER > 0 then
    local ped = PlayerPedId()
    if ped ~= 0 and DoesEntityExist(ped) then
      local baseMax = CaptureBaseMaxHp()
      local hp = GetEntityHealth(ped)
      local oldMax = baseMax + ARMOR_BUFFER
      local ratio = (hp > 0) and (hp / math.max(1, oldMax)) or 0
      ClientState.ignoreSelfHeal = true
      SetEntityMaxHealth(ped, baseMax)
      if hp > 0 then
        SetEntityHealth(ped, math.max(1, Shared.Round(ratio * baseMax)))
      end
      ClientState.ignoreSelfHeal = false
      ARMOR_BUFFER = 0
      dprint('armor buffer removed (system disabled)')
    end
  end
end

CreateThread(function()
  local lastStamina, lastDeadeye = nil, nil
  local carryStamina, carryDeadeye = 0.0, 0.0

  while true do
    local pollMs = (Config.CoreDrain and Config.CoreDrain.pollMs) or 250
    Wait(pollMs)

    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then
      lastStamina, lastDeadeye = nil, nil
      goto continue
    end

    local stats = ClientState.stats or {}
    local staminaMod = tonumber(stats.staminaCostModifier or 0) or 0
    local deadeyeMod = tonumber(stats.deadeyeDrainModifier or 0) or 0

    local stam = GetCoreValue(ped, CORE_STAMINA)
    local dead = GetCoreValue(ped, CORE_DEADEYE)

    if stam and lastStamina then
      local delta = lastStamina - stam
      if delta > 0.01 and staminaMod ~= 0 then
        local refundPerPoint = (Config.CoreDrain and Config.CoreDrain.staminaPointToRefund) or 0.06
        local extraPerPoint  = (Config.CoreDrain and Config.CoreDrain.staminaPointToExtraDrain) or 0.06

        if staminaMod < 0 then
          carryStamina = carryStamina + (delta * (-staminaMod) * refundPerPoint)
        else
          carryStamina = carryStamina - (delta * (staminaMod) * extraPerPoint)
        end

        if math.abs(carryStamina) >= 0.5 then
          SetCoreValue(ped, CORE_STAMINA, stam + carryStamina)
          carryStamina = 0.0
          stam = GetCoreValue(ped, CORE_STAMINA) or stam
        end
      end
    end

    if dead and lastDeadeye then
      local delta = lastDeadeye - dead
      if delta > 0.01 and deadeyeMod ~= 0 then
        local refundPerPoint = (Config.CoreDrain and Config.CoreDrain.deadeyePointToRefund) or 0.08
        local extraPerPoint  = (Config.CoreDrain and Config.CoreDrain.deadeyePointToExtraDrain) or 0.08

        if deadeyeMod < 0 then
          carryDeadeye = carryDeadeye + (delta * (-deadeyeMod) * refundPerPoint)
        else
          carryDeadeye = carryDeadeye - (delta * (deadeyeMod) * extraPerPoint)
        end

        if math.abs(carryDeadeye) >= 0.5 then
          SetCoreValue(ped, CORE_DEADEYE, dead + carryDeadeye)
          carryDeadeye = 0.0
          dead = GetCoreValue(ped, CORE_DEADEYE) or dead
        end
      end
    end

    lastStamina = stam
    lastDeadeye = dead

    ::continue::
  end
end)

CreateThread(function()
  local carryStam, carryHp = 0.0, 0.0

  while true do
    Wait(1000)

    local env = Config.Environment or {}
    if env.enabled == false then goto continue end

    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then goto continue end

    local temp = GetAmbientTemperature(ped)
    if type(temp) ~= 'number' then goto continue end

    local stats = ClientState.stats or {}
    local coldRes = tonumber(stats.coldResist or 0) or 0
    local heatRes = tonumber(stats.heatResist or 0) or 0

    local coldTh  = tonumber(env.coldThreshold or 0.0) or 0.0
    local heatTh  = tonumber(env.heatThreshold or 30.0) or 30.0
    local coldRg  = tonumber(env.coldRange or 25.0) or 25.0
    local heatRg  = tonumber(env.heatRange or 15.0) or 15.0

    local coldStress = 0.0
    local heatStress = 0.0
    if temp < coldTh then
      coldStress = (coldTh - temp) / math.max(1.0, coldRg)
    elseif temp > heatTh then
      heatStress = (temp - heatTh) / math.max(1.0, heatRg)
    end

    coldStress = Shared.Clamp(coldStress, 0.0, 2.0)
    heatStress = Shared.Clamp(heatStress, 0.0, 2.0)

    local resistFactor = tonumber(env.ResistPointToStressReduction or 0.03) or 0.03
    if coldStress > 0 then
      coldStress = coldStress * (1.0 - (coldRes * resistFactor))
      if coldStress < 0 then coldStress = 0 end
    end
    if heatStress > 0 then
      heatStress = heatStress * (1.0 - (heatRes * resistFactor))
      if heatStress < 0 then heatStress = 0 end
    end

    local stress = math.max(coldStress, heatStress)
    if stress <= 0 then goto continue end

    local baseDrain = tonumber(env.baseStaminaCoreDrainPerSec or 0.14) or 0.14
    local hpShare   = tonumber(env.healthCoreDrainShare or 0.35) or 0.35

    local drain = baseDrain * stress
    local drainHp = drain * hpShare

    local stam = GetCoreValue(ped, CORE_STAMINA)
    local hp   = GetCoreValue(ped, CORE_HEALTH)
    if not stam or not hp then goto continue end

    carryStam = carryStam - drain
    carryHp   = carryHp - drainHp

    if math.abs(carryStam) >= 0.5 then
      SetCoreValue(ped, CORE_STAMINA, stam + carryStam)
      carryStam = 0.0
    end
    if math.abs(carryHp) >= 0.5 then
      SetCoreValue(ped, CORE_HEALTH, hp + carryHp)
      carryHp = 0.0
    end

    ::continue::
  end
end)

CreateThread(function()
  local touched = {}

  while true do
    local ai = Config.AI or {}
    local refresh = tonumber(ai.refreshMs or 1000) or 1000
    Wait(refresh)

    local now = GetGameTimer()

    local ped = PlayerPedId()
    local stats = ClientState.stats or {}

    local stealth = tonumber(stats.stealthModifier or 0) or 0
    local noise   = tonumber(stats.noiseModifier or 0) or 0
    local score = stealth + (-noise)

    if ai.enabled ~= false and score ~= 0 and ped ~= 0 and DoesEntityExist(ped) and GetGamePool then
      local radius = tonumber(ai.stealthAuraRadius or 45.0) or 45.0
      local baseHear = tonumber(ai.baseHearingRange or 55.0) or 55.0
      local baseSee  = tonumber(ai.baseSeeingRange or 85.0) or 85.0
      local perPoint = tonumber(ai.stealthPointToSenseReduction or 0.02) or 0.02
      local minM     = tonumber(ai.minSenseMultiplier or 0.45) or 0.45
      local maxM     = tonumber(ai.maxSenseMultiplier or 1.25) or 1.25

      local m = 1.0 - (score * perPoint)

      local effectiveMinM = minM
      if HasPassive('wolf_detection_reduction') then
        local cfg_p = Config.Passives and Config.Passives.wolf_detection_reduction
        m = m * (cfg_p and cfg_p.extraSenseMultiplier or 0.55)
        effectiveMinM = (cfg_p and cfg_p.minSenseOverride) or 0.20
      end
      if HasPassive('assassination_expertise') then
        local cfg_p = Config.Passives and Config.Passives.assassination_expertise
        m = m * (cfg_p and cfg_p.extraSenseMultiplier or 0.40)
        effectiveMinM = math.min(effectiveMinM, (cfg_p and cfg_p.minSenseOverride) or 0.15)
      end

      m = Shared.Clamp(m, effectiveMinM, maxM)

      local pcoords = GetEntityCoords(ped)
      local pool = GetGamePool('CPed')
      for _, npc in ipairs(pool) do
        if npc and npc ~= ped and DoesEntityExist(npc) and IsEntityAPed(npc) and not IsPedAPlayer(npc) and not IsEntityDead(npc) then
          local dist = #(pcoords - GetEntityCoords(npc))
          if dist <= radius then
            if SetPedHearingRange then pcall(function() SetPedHearingRange(npc, baseHear * m) end) end
            if SetPedSeeingRange then pcall(function() SetPedSeeingRange(npc, baseSee * m) end) end
            touched[npc] = now
          end
        end
      end
    end

    local resetAfter = tonumber((Config.AI and Config.AI.resetAfterMs) or 5500) or 5500
    local baseHear = tonumber((Config.AI and Config.AI.baseHearingRange) or 55.0) or 55.0
    local baseSee  = tonumber((Config.AI and Config.AI.baseSeeingRange) or 85.0) or 85.0

    for npc, ts in pairs(touched) do
      if (not DoesEntityExist(npc)) or (now - (ts or 0) > resetAfter) then
        if DoesEntityExist(npc) then
          if SetPedHearingRange then pcall(function() SetPedHearingRange(npc, baseHear) end) end
          if SetPedSeeingRange then pcall(function() SetPedSeeingRange(npc, baseSee) end) end
        end
        touched[npc] = nil
      end
    end
  end
end)

CreateThread(function()
  local cooldown = {}

  while true do
    Wait(200)

    local ai = (Config.AI and Config.AI.intimidation) or {}
    if ai.enabled == false then goto continue end

    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then goto continue end

    local stats = ClientState.stats or {}
    local points = tonumber(stats.intimidation or 0) or 0
    if points <= 0 then goto continue end

    local aiming, target = false, 0
    if GetEntityPlayerIsFreeAimingAt then
      aiming, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
    end
    if not aiming or not target or target == 0 or not DoesEntityExist(target) or not IsEntityAPed(target) then goto continue end
    if IsPedAPlayer(target) or not IsPedHuman(target) or IsEntityDead(target) then goto continue end

    local radius = tonumber(ai.radius or 15.0) or 15.0
    local dist = #(GetEntityCoords(ped) - GetEntityCoords(target))
    if dist > radius then goto continue end

    local now = GetGameTimer()
    local nextOk = cooldown[target] or 0
    if now < nextOk then goto continue end

    local chance = (tonumber(ai.baseChance or 0.06) or 0.06) + (points * (tonumber(ai.chancePerPoint or 0.03) or 0.03))
    if HasPassive('quickdraw_mastery') then
      local cfg_p = Config.Passives and Config.Passives.quickdraw_mastery
      chance = chance * (cfg_p and cfg_p.intimidationMultiplier or 2.0)
    end
    if chance > 0.85 then chance = 0.85 end

    if math.random() < chance then
      local dur = tonumber(ai.handsUpDurationMs or 6500) or 6500
      if TaskHandsUp then
        pcall(function() TaskHandsUp(target, dur, ped, -1, true) end)
      elseif TaskReact then
        pcall(function() TaskReact(target, ped) end)
      elseif TaskSmartFleePed then
        pcall(function() TaskSmartFleePed(target, ped, 80.0, dur, false, false) end)
      end

      local cd = tonumber(ai.cooldownMs or 6000) or 6000
      cooldown[target] = now + cd
    end

    ::continue::
  end
end)

RegisterNetEvent('cas-armour:client:applyPoisonTick', function(rawDmg)
  local ped = PlayerPedId()
  if ped == 0 or not DoesEntityExist(ped) then return end
  local dmg = tonumber(rawDmg or 0) or 0
  if dmg <= 0 then return end

  local reductionPct = Shared.ComputeDamageReductionPercent(ClientState.stats, 'poison')
  if reductionPct <= 0 then return end

  local hpNow = GetEntityHealth(ped)
  local heal = dmg * (reductionPct / 100.0)
  heal = Shared.Clamp(heal, 0, dmg)
  if heal <= 0.5 then return end

  ClientState.ignoreSelfHeal = true
  SetEntityHealth(ped, hpNow + Shared.Round(heal))
  ClientState.ignoreSelfHeal = false
end)

CreateThread(function()
  while true do
    Wait(500)
    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then goto continue end

    local active = HasPassive('bear_charge_resistance')
    local cfg_p = Config.Passives and Config.Passives.bear_charge_resistance

    if active and (cfg_p and cfg_p.disableRagdoll ~= false) then
      if not PassiveState.bearRagdollDisabled then
        pcall(function() SetPedCanRagdoll(ped, false) end)
        PassiveState.bearRagdollDisabled = true
        dprint('bear_charge_resistance: ragdoll disabled')
      end
    elseif PassiveState.bearRagdollDisabled then
      pcall(function() SetPedCanRagdoll(ped, true) end)
      PassiveState.bearRagdollDisabled = false
      dprint('bear_charge_resistance: ragdoll re-enabled')
    end

    ::continue::
  end
end)

CreateThread(function()
  while true do
    local cfg_p = Config.Passives and Config.Passives.enemy_detection_boost
    local refreshMs = (cfg_p and cfg_p.refreshMs) or 2000
    Wait(refreshMs)

    if not HasPassive('enemy_detection_boost') then
      for npc, blip in pairs(PassiveState.enemyBlips) do
        pcall(function() if DoesBlipExist(blip) then RemoveBlip(blip) end end)
      end
      PassiveState.enemyBlips = {}
      goto continue
    end

    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then goto continue end

    local radius = (cfg_p and cfg_p.radius) or 80.0
    local pcoords = GetEntityCoords(ped)
    local seen = {}

    if GetGamePool then
      local pool = GetGamePool('CPed')
      for _, npc in ipairs(pool) do
        if npc ~= ped and DoesEntityExist(npc) and IsEntityAPed(npc) and not IsPedAPlayer(npc) and not IsEntityDead(npc) then
          local dist = #(pcoords - GetEntityCoords(npc))
          if dist <= radius then
            local hostile = IsPedInCombat(npc, false)
            if not hostile and GetPedAlertness then
              local ok3, a = pcall(function() return GetPedAlertness(npc) end)
              hostile = ok3 and type(a) == 'number' and a >= 2
            end

            if hostile then
              seen[npc] = true
              if not PassiveState.enemyBlips[npc] then
                local ok4, blip = pcall(function() return AddBlipForEntity(npc) end)
                if ok4 and blip and blip ~= 0 then
                  pcall(function() SetBlipSprite(blip, 1, true) end)
                  PassiveState.enemyBlips[npc] = blip
                end
              end
            end
          end
        end
      end
    end

    for npc, blip in pairs(PassiveState.enemyBlips) do
      if not seen[npc] then
        pcall(function() if DoesBlipExist(blip) then RemoveBlip(blip) end end)
        PassiveState.enemyBlips[npc] = nil
      end
    end

    ::continue::
  end
end)

CreateThread(function()
  while true do
    local cfg_p = Config.Passives and Config.Passives.poison_aura
    local intervalMs = (cfg_p and cfg_p.intervalMs) or 3000
    Wait(intervalMs)

    if not HasPassive('poison_aura') then goto continue end

    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then goto continue end

    local radius = (cfg_p and cfg_p.radius) or 5.0
    local dmg = (cfg_p and cfg_p.damage) or 3
    local pcoords = GetEntityCoords(ped)

    if GetGamePool then
      local pool = GetGamePool('CPed')
      for _, npc in ipairs(pool) do
        if npc ~= ped and DoesEntityExist(npc) and IsEntityAPed(npc) and not IsPedAPlayer(npc) and not IsEntityDead(npc) then
          local dist = #(pcoords - GetEntityCoords(npc))
          if dist <= radius then
            pcall(function() ApplyDamageToPed(npc, dmg, false) end)
          end
        end
      end
    end

    ::continue::
  end
end)

CreateThread(function()
  while true do
    local cfg_p = Config.Passives and Config.Passives.quickdraw_mastery
    local recoveryMs = (cfg_p and cfg_p.deadeyeRecoveryMs) or 2000
    Wait(recoveryMs)

    if not HasPassive('quickdraw_mastery') then goto continue end

    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then goto continue end

    local recovery = (cfg_p and cfg_p.deadeyeRecovery) or 1
    local cap = (cfg_p and cfg_p.deadeyeRecoveryCap) or 90
    local dead = GetCoreValue(ped, CORE_DEADEYE)
    if dead and dead < cap then
      SetCoreValue(ped, CORE_DEADEYE, math.min(cap, dead + recovery))
    end

    ::continue::
  end
end)

local function Recompute()
  ClientState.stats, ClientState.activeSetBonuses, ClientState.activePassives = Shared.ComputeAggregatedStats(ClientState.equipment)
  ApplyMovementFromStats(ClientState.stats)
  RecalcArmorBuffer()
  QueueStateToNui()
end

RegisterNUICallback('cas_armour:nuiReady', function(_, cb)
  ClientState.nuiReady = true
  dprint('NUI ready signal received')
  cb({ ok = true })
end)

CreateThread(function()
  local attempts = 0
  while not ClientState.nuiReady do
    Wait(1000)
    attempts = attempts + 1
    SendNUIMessage({ action = 'cas_armour:ping' })
    dprint(('NUI ping attempt %d'):format(attempts))
  end
  dprint('NUI ready confirmed after ' .. attempts .. ' ping(s)')
end)

RegisterCommand(Config.OpenCommand, function()
  if not ClientState.nuiReady then
    TriggerEvent('chat:addMessage', { args = { '^3[ARMOR]^7', 'UI is still loading, please wait...' } })
    return
  end

  if not ClientState.isUiOpen then
    SendStateToNui()
    NuiFocus(true)
    SendNUIMessage({ action = 'cas_armour:open' })
  else
    SendNUIMessage({ action = 'cas_armour:close' })
  end
end, false)

RegisterCommand('armorreload', function()
  TriggerServerEvent('cas-armour:server:loadEquipment')
end, false)

CreateThread(function()
  while true do
    Wait(0)
    if ClientState.nuiReady and Config.OpenKey and IsControlJustPressed(0, Config.OpenKey) then
      ExecuteCommand(Config.OpenCommand)
    end
  end
end)

RegisterNUICallback('cas_armour:close', function(_, cb)
  NuiFocus(false)
  cb({ ok = true })
end)

RegisterNUICallback('cas_armour:requestData', function(_, cb)
  TriggerServerEvent('cas-armour:server:requestData')
  cb({ ok = true })
end)

RegisterNUICallback('cas_armour:equip', function(data, cb)
  TriggerServerEvent('cas-armour:server:equip', data)
  cb({ ok = true })
end)

RegisterNUICallback('cas_armour:unequip', function(data, cb)
  TriggerServerEvent('cas-armour:server:unequip', data)
  cb({ ok = true })
end)

RegisterNUICallback('cas_armour:craft', function(data, cb)
  TriggerServerEvent('cas-armour:server:craft', data)
  cb({ ok = true })
end)

RegisterNUICallback('slotFocus', function(data, cb)
  if data and data.slot then
    FocusSlotCam(data.slot)
  end
  cb('ok')
end)

RegisterNUICallback('slotReset', function(_, cb)
  ResetSlotCam()
  cb('ok')
end)

RegisterNetEvent('cas-armour:client:setData', function(payload)
  if type(payload) ~= 'table' then return end

  ClientState.equipment = payload.equipment or { slots = {} }
  ClientState.inventory = payload.inventory or {}

  Recompute()
end)

RegisterNetEvent('cas-armour:client:updateEquipment', function(payload)
  if type(payload) ~= 'table' then return end
  ClientState.equipment = payload.equipment or { slots = {} }
  Recompute()
end)

RegisterNetEvent('cas-armour:client:notify', function(msg)
  if msg and msg ~= '' then
    TriggerEvent('chat:addMessage', { args = { '^3[ARMOR]^7', msg } })
  end
end)

local POISON_AMMO = {
  [GetHashKey('AMMO_ARROW_POISON')] = true,
  [GetHashKey('AMMO_THROWING_KNIVES_POISON')] = true,
  [GetHashKey('AMMO_POISON')] = true,
}

local EXPLOSIVE_WEAPONS = {
  [GetHashKey('WEAPON_THROWN_DYNAMITE')] = true,
  [GetHashKey('WEAPON_THROWN_DYNAMITE_VOLATILE')] = true,
  [GetHashKey('WEAPON_THROWN_MOLOTOV')] = true,
  [GetHashKey('WEAPON_THROWN_MOLOTOV_VOLATILE')] = true,
  [GetHashKey('WEAPON_THROWN_STICKYBOMB')] = true,
}

local function ClassifyDamage(culprit, weaponHash, ammoHash)
  if ammoHash and ammoHash ~= 0 and POISON_AMMO[ammoHash] then
    return 'poison'
  end

  if weaponHash and weaponHash ~= 0 and EXPLOSIVE_WEAPONS[weaponHash] then
    return 'explosion'
  end

  if culprit and culprit ~= 0 and DoesEntityExist(culprit) then
    if IsEntityAPed(culprit) then
      if not IsPedHuman(culprit) then
        return 'animal'
      end
      if weaponHash == 0 then return 'melee' end
      local unarmed = GetHashKey('WEAPON_UNARMED')
      if weaponHash == unarmed then return 'melee' end
      return 'bullet'
    end
  end

  if IsPedFalling(PlayerPedId()) or IsPedRagdoll(PlayerPedId()) then
    return 'fall'
  end

  return 'generic'
end

local function GetLastDamageBoneId(ped)
  local boneId = 0
  local success, bone = GetPedLastDamageBone(ped)
  if success then
    boneId = bone
  end
  return boneId or 0
end

local BoneIdSlotMap = {
  [33869] = 'gloves', [4126]  = 'gloves', [34606] = 'gloves', [22798] = 'gloves',
  [53675] = 'gloves', [54187] = 'gloves', [49600] = 'gloves', [29881] = 'gloves',
  [38989] = 'gloves', [9246]  = 'gloves', [37709] = 'gloves', [7966]  = 'gloves',

  [45454] = 'boots', [33646] = 'boots', [65245] = 'boots', [35502] = 'boots',
  [43312] = 'boots', [55120] = 'boots', [38142] = 'boots', [2718]  = 'boots',
  [10710] = 'boots', [40453] = 'boots', [54157] = 'boots',

  [65478] = 'pants', [6884]  = 'pants', [58630] = 'pants', [60844] = 'pants',
  [41287] = 'pants', [21568] = 'pants',

  [53684] = 'torso', [27792] = 'torso', [6757]  = 'torso', [6758]  = 'torso',
  [14410] = 'torso', [14411] = 'torso', [14412] = 'torso', [56200] = 'torso',

  [21030] = 'head', [27981] = 'head', [57278] = 'head',
}

local BoneIndexSlotMap = {
  [201] = 'gloves', [299] = 'gloves', [200] = 'gloves', [298] = 'gloves', [199] = 'gloves', [297] = 'gloves',

  [3]  = 'boots', [34] = 'boots', [4]  = 'boots', [35] = 'boots', [5]  = 'boots', [36] = 'boots',
  [40] = 'boots', [9]  = 'boots',

  [2]  = 'pants', [33] = 'pants',
  [97] = 'pants', [110] = 'pants',

  [1]   = 'torso',
  [130] = 'torso', [131] = 'torso', [132] = 'torso', [133] = 'torso', [134] = 'torso',

  [144] = 'head', [166] = 'head',
}

local function ResolveWearSlotFromHit(boneId, candidates)
  local slotKey = (boneId and boneId ~= 0) and BoneIdSlotMap[boneId] or nil

  if not slotKey and type(candidates) == 'table' then
    for _, v in ipairs(candidates) do
      local n = tonumber(v or 0) or 0
      if n ~= 0 then
        slotKey = BoneIdSlotMap[n] or BoneIndexSlotMap[n]
        if slotKey then break end
      end
    end
  end

  if slotKey == 'torso' then
    local slots = (ClientState.equipment and ClientState.equipment.slots) or {}
    if slots['vest'] and slots['vest'].pieceId then return 'vest' end
    return 'chest'
  end

  return slotKey
end

local function QueueWearLoss(slotName, loss)
  if not slotName or slotName == '' then return end
  loss = tonumber(loss or 0) or 0
  if loss <= 0 then return end

  ClientState.wearQueue = ClientState.wearQueue or {}
  local e = ClientState.wearQueue[slotName]
  if not e then
    e = { loss = 0.0, hits = 0 }
    ClientState.wearQueue[slotName] = e
  end

  e.loss = (tonumber(e.loss or 0) or 0) + loss
  e.hits = (tonumber(e.hits or 0) or 0) + 1

  ClientState.wearQueueHits = (tonumber(ClientState.wearQueueHits or 0) or 0) + 1
  ClientState.wearQueueDirty = true
end

CreateThread(function()
  while true do
    local interval = (Config.Tuning and Config.Tuning.WearBatchIntervalMs) or 250
    Wait(interval)

    if ClientState.wearQueueDirty and ClientState.wearQueue and next(ClientState.wearQueue) ~= nil then
      local merged = {}
      for slotName, agg in pairs(ClientState.wearQueue) do
        if type(agg) == 'table' then
          merged[slotName] = { loss = tonumber(agg.loss or 0) or 0, hits = tonumber(agg.hits or 1) or 1 }
        end
      end

      ClientState.wearQueue = {}
      ClientState.wearQueueHits = 0
      ClientState.wearQueueDirty = false

      TriggerServerEvent('cas-armour:server:wearBatch', { merged = merged })
    end
  end
end)

local EVENT_GROUP = 0
local EVENT_ENTITY_DAMAGED = GetHashKey("EVENT_ENTITY_DAMAGED")
local EVENT_DATA_SIZE = 9

CreateThread(function()
    local lastPed = 0
    local lastHp = 0
    local bufReuse = DataView.ArrayBuffer(8 * EVENT_DATA_SIZE)

    while true do
        local pollMs = (HasAnyArmourEquipped() and ((Config.Tuning and Config.Tuning.DamagePollMs) or 10)) or ((Config.Tuning and Config.Tuning.DamageIdlePollMs) or 350)
        Wait(pollMs)

        local ped = PlayerPedId()
        if ped ~= lastPed then
            lastPed = ped
            lastHp = GetEntityHealth(ped)
        end

        if ClientState.ignoreSelfHeal then
            lastHp = GetEntityHealth(ped)
            goto continue
        end

        local size = GetNumberOfEvents(EVENT_GROUP)
        if size > 0 then
            for i = 0, size - 1 do
                local ev = GetEventAtIndex(EVENT_GROUP, i)

                if tonumber(ev) == tonumber(EVENT_ENTITY_DAMAGED) then
                    local buf = bufReuse

                    local ok = Citizen.InvokeNative(
                        0x57EC5FA4D4D6AFCA,
                        EVENT_GROUP,
                        i,
                        buf:Buffer(),
                        EVENT_DATA_SIZE
                    )

                    if ok then
                        local victim  = buf:GetInt32(0)
                        local culprit = buf:GetInt32(8)
                        local weapon  = buf:GetInt32(16)
                        local ammo    = buf:GetInt32(24)
                        local u4 = buf:GetInt32(32)
                        local u5 = buf:GetInt32(40)
                        local u6 = buf:GetInt32(48)
                        local u7 = buf:GetInt32(56)
                        local u8 = buf:GetInt32(64)
                        if victim == ped then
                            if (not culprit) or culprit == 0 or (not DoesEntityExist(culprit)) then
                                if GetPedSourceOfDeath then
                                    local src = GetPedSourceOfDeath(ped)
                                    if src and src ~= 0 and DoesEntityExist(src) then
                                        culprit = src
                                    end
                                elseif GetPedSourceOfLastDamage then
                                    local src = GetPedSourceOfLastDamage(ped)
                                    if src and src ~= 0 and DoesEntityExist(src) then
                                        culprit = src
                                    end
                                end
                            end

                            local hpNow = GetEntityHealth(ped)
                            local dmg = (lastHp or hpNow) - hpNow
                            if dmg < 0 then dmg = 0 end

                            if dmg > 0 then
                                local category = ClassifyDamage(culprit, weapon, ammo)
                                local dodged = false

                                if category == 'bullet' and HasPassive('bullet_dodge_chance') then
                                  local cfg_p = Config.Passives and Config.Passives.bullet_dodge_chance
                                  if math.random() < (cfg_p and cfg_p.chance or 0.15) then
                                    ClientState.ignoreSelfHeal = true
                                    local maxHp = GetEntityMaxHealth(ped) or 9999
                                    SetEntityHealth(ped, math.min(maxHp, hpNow + dmg))
                                    ClientState.ignoreSelfHeal = false
                                    hpNow = hpNow + dmg
                                    dodged = true
                                    dprint(('bullet_dodge: negated %.0f dmg'):format(dmg))
                                  end
                                end

                                if not dodged then
                                  local reductionPct = Shared.ComputeDamageReductionPercent(ClientState.stats, category)

                                  local effectiveDmg = dmg * (1.0 - reductionPct / 100.0)
                                  local shouldSurvive = ((lastHp or 0) - effectiveDmg) > 0

                                  if (hpNow <= 0 or IsEntityDead(ped)) and shouldSurvive and reductionPct > 0 then
                                    local targetHp = math.max(1, Shared.Round((lastHp or 0) - effectiveDmg))

                                    ClientState.ignoreSelfHeal = true
                                    local c = GetEntityCoords(ped)
                                    local h = GetEntityHeading(ped)
                                    pcall(function() NetworkResurrectLocalPlayer(c.x, c.y, c.z, h, true, false) end)
                                    pcall(function() ClearPedTasksImmediately(ped) end)
                                    SetEntityHealth(ped, targetHp)
                                    ClientState.ignoreSelfHeal = false
                                    hpNow = targetHp
                                    dprint(('armor prevented death: hp=%.0f'):format(hpNow))

                                  elseif reductionPct > 0 and hpNow > 0 then
                                    local heal = dmg * (reductionPct / 100.0)

                                    if heal > 0.5 then
                                      ClientState.ignoreSelfHeal = true
                                      local maxHp = GetEntityMaxHealth(ped) or 200
                                      local newHp = math.min(maxHp, hpNow + Shared.Round(heal))
                                      SetEntityHealth(ped, newHp)
                                      ClientState.ignoreSelfHeal = false
                                      hpNow = newHp
                                      dprint(('heal-back: dmg=%.0f pct=%.0f%% heal=%.0f hp=%.0f'):format(dmg, reductionPct, heal, hpNow))
                                    end
                                  end

                                  local boneId = GetLastDamageBoneId(ped)
                                  local wearLoss = dmg * (Config.Tuning.WearPerDamage or 0.45)
                                  wearLoss = Shared.Clamp(wearLoss, 0, Config.Tuning.MaxWearPerHit or 25)
                                  if wearLoss > 0 then
                                    local slotName = ResolveWearSlotFromHit(boneId, { u4, u5, u6, u7, u8 })
                                    QueueWearLoss(slotName, wearLoss)
                                  end
                                end
                            end

                            lastHp = hpNow
                        end

                        if culprit == ped and victim ~= ped and HasPassive('assassination_expertise') then
                          if DoesEntityExist(victim) and IsEntityAPed(victim) and not IsPedAPlayer(victim) and not IsEntityDead(victim) then
                            local alertness = -1
                            if GetPedAlertness then
                              local ok3, a = pcall(function() return GetPedAlertness(victim) end)
                              if ok3 and type(a) == 'number' then alertness = a end
                            end
                            if alertness == 0 then
                              local cfg_p = Config.Passives and Config.Passives.assassination_expertise
                              local bonusDmg = (cfg_p and cfg_p.stealthBonusDamage) or 15
                              pcall(function() ApplyDamageToPed(victim, bonusDmg, false) end)
                              dprint(('assassination_expertise: +%.0f bonus on unaware npc'):format(bonusDmg))
                            end
                          end
                        end
                    end
                end
            end
        else
            lastHp = GetEntityHealth(ped)
        end

        ::continue::
    end
end)

AddEventHandler('onClientResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  CreateThread(function()
    Wait(500)
    CaptureBaseMaxHp()
    Wait(1000)
    TriggerServerEvent('cas-armour:server:loadEquipment')
  end)
  -- Re-trigger NUI ping in case the browser frame just loaded
  CreateThread(function()
    Wait(200)
    if not ClientState.nuiReady then
      SendNUIMessage({ action = 'cas_armour:ping' })
    end
  end)
end)

RegisterNetEvent('vorp:SelectedCharacter', function()
  CreateThread(function()
    Wait(2000)
    -- Ensure NUI is pinged after character select (browser may only now be ready)
    if not ClientState.nuiReady then
      for i = 1, 30 do
        SendNUIMessage({ action = 'cas_armour:ping' })
        Wait(500)
        if ClientState.nuiReady then break end
      end
    end
    CaptureBaseMaxHp()
    for attempt = 1, 10 do
      TriggerServerEvent('cas-armour:server:loadEquipment')
      Wait(2000)
      if ClientState.equipment and next(ClientState.equipment) then
        dprint('Equipment loaded after ' .. attempt .. ' attempt(s)')
        break
      end
      dprint('Equipment not loaded yet, retrying... (' .. attempt .. '/10)')
    end
  end)
end)

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
  CreateThread(function()
    Wait(1500)
    CaptureBaseMaxHp()
    Wait(500)
    TriggerServerEvent('cas-armour:server:loadEquipment')
  end)
end)

RegisterNetEvent('cas-armour:client:forceReload', function()
  TriggerServerEvent('cas-armour:server:loadEquipment')
end)

exports('GetEquipment', function()
  return ClientState.equipment
end)

exports('GetStats', function()
  return ClientState.stats
end)

exports('GetActivePassives', function()
  return ClientState.activePassives
end)

AddEventHandler('onResourceStop', function(resName)
  if resName ~= GetCurrentResourceName() then return end
  StopArmourCam()
  SetNuiFocus(false, false)

  if ARMOR_BUFFER > 0 and BASE_MAX_HP and BASE_MAX_HP > 0 then
    local ped = PlayerPedId()
    if ped and ped ~= 0 and DoesEntityExist(ped) then
      SetEntityMaxHealth(ped, BASE_MAX_HP)
    end
    ARMOR_BUFFER = 0
  end

  if PassiveState.bearRagdollDisabled then
    local ped = PlayerPedId()
    if ped and ped ~= 0 and DoesEntityExist(ped) then
      pcall(function() SetPedCanRagdoll(ped, true) end)
    end
    PassiveState.bearRagdollDisabled = false
  end
  for _, blip in pairs(PassiveState.enemyBlips) do
    pcall(function() if DoesBlipExist(blip) then RemoveBlip(blip) end end)
  end
  PassiveState.enemyBlips = {}

  ClientState.nuiReady = false
end)

RegisterCommand('armourtest', function()
  local player = PlayerPedId()
  local pCoords = GetEntityCoords(player)
  local fwd = GetEntityForwardVector(player)

  local spawnPos = vector3(pCoords.x + fwd.x * 8.0, pCoords.y + fwd.y * 8.0, pCoords.z)

  local model = GetHashKey('u_m_m_valgunsmith_01')
  RequestModel(model)
  local timeout = 0
  while not HasModelLoaded(model) and timeout < 50 do
    Wait(100)
    timeout = timeout + 1
  end
  if not HasModelLoaded(model) then
    TriggerEvent('chat:addMessage', { args = { '^1[ARMOR TEST]^7', 'Model yüklenemedi!' } })
    return
  end

  local ped = CreatePed(model, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, false, false, false)
  Citizen.InvokeNative(0x77FF8D35EEC6BBC4, ped, 0, false)
  Citizen.InvokeNative(0x283978A15512B2FE, ped, true)

  SetEntityInvincible(ped, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  TaskSetBlockingOfNonTemporaryEvents(ped, true)

  local weapon = GetHashKey('WEAPON_REVOLVER_CATTLEMAN')
  GiveWeaponToPed_2(ped, weapon, 9999, true, false, 0, false, 0.5, 1.0, 0, false, 0.0, false)
  Citizen.InvokeNative(0xADF692B254977C0C, ped, weapon, 0, true, false)

  TaskTurnPedToFaceEntity(ped, player, 1000, 0.0, 0.0, 0.0)
  Wait(500)
  TaskShootAtEntity(ped, player, 15000, GetHashKey('FIRING_PATTERN_FULL_AUTO'), true)

  TriggerEvent('chat:addMessage', { args = { '^3[ARMOR TEST]^7', '15 saniye ateş edecek...' } })

  SetTimeout(15500, function()
    if DoesEntityExist(ped) then
      DeletePed(ped)
      DeleteEntity(ped)
      TriggerEvent('chat:addMessage', { args = { '^3[ARMOR TEST]^7', 'Ped silindi.' } })
    end
  end)

  SetModelAsNoLongerNeeded(model)
end, false)
