
Shared = Shared or {}

function Shared.Clamp(x, min, max)
  if x < min then return min end
  if x > max then return max end
  return x
end

function Shared.Round(x)
  return math.floor(x + 0.5)
end

function Shared.DeepCopy(t)
  if type(t) ~= 'table' then return t end
  local out = {}
  for k, v in pairs(t) do
    out[k] = Shared.DeepCopy(v)
  end
  return out
end

function Shared.MergeStats(into, add)
  if type(add) ~= 'table' then return into end
  for k, v in pairs(add) do
    if type(v) == 'number' then
      into[k] = (into[k] or 0) + v
    end
  end
  return into
end

function Shared.ComputeSetBonuses(equipment)
  local equippedBySet = {}

  if equipment and equipment.slots then
    for _, slotName in ipairs(Config.Slots) do
      local s = equipment.slots[slotName]
      if s and s.pieceId then
        local piece = Config.ArmorPieces[s.pieceId]
        if piece and piece.set then
          equippedBySet[piece.set] = (equippedBySet[piece.set] or 0) + 1
        end
      end
    end
  end

  local activeBonuses, activePassives = {}, {}

  for setId, count in pairs(equippedBySet) do
    local set = Config.ArmorSets[setId]
    if set and set.bonuses then
      for threshold, bonus in pairs(set.bonuses) do
        if count >= tonumber(threshold) then
          table.insert(activeBonuses, { setId = setId, threshold = tonumber(threshold), bonus = bonus })
          if bonus.passive and bonus.passive ~= '' then
            table.insert(activePassives, { setId = setId, passive = bonus.passive, threshold = tonumber(threshold) })
          end
        end
      end
    end
  end

  return equippedBySet, activeBonuses, activePassives
end

function Shared.ComputeAggregatedStats(equipment)
  local stats = {}
  local _, activeBonuses, activePassives = Shared.ComputeSetBonuses(equipment)

  if equipment and equipment.slots then
    for _, slotName in ipairs(Config.Slots) do
      local s = equipment.slots[slotName]
      if s and s.pieceId then
        local piece = Config.ArmorPieces[s.pieceId]
        if piece and piece.stats then
          local cond = tonumber(s.condition or 0) or 0
          local maxC = tonumber(s.maxCondition or piece.maxCondition or 1) or 1
          local ratio = 0
          if maxC > 0 then ratio = Shared.Clamp(cond / maxC, 0.0, 1.0) end

          local scaled = {}
          for k, v in pairs(piece.stats) do
            if type(v) == 'number' then
              scaled[k] = v * ratio
            end
          end
          Shared.MergeStats(stats, scaled)

          if piece.weight then
            if piece.weight == 'heavy' then
              stats.weightPenalty = (stats.weightPenalty or 0) + (Config.WeightPenalty.heavy or 0)
            elseif piece.weight == 'medium' then
              stats.weightPenalty = (stats.weightPenalty or 0) + (Config.WeightPenalty.medium or 0)
            elseif piece.weight == 'light' then
              stats.weightPenalty = (stats.weightPenalty or 0) + (Config.WeightPenalty.light or 0)
            end
          end
        end
      end
    end
  end

  for _, b in ipairs(activeBonuses) do
    if b.bonus and b.bonus.stats then
      Shared.MergeStats(stats, b.bonus.stats)
    end
  end

  return stats, activeBonuses, activePassives
end

function Shared.ComputeDamageReductionPercent(stats, category)
  stats = stats or {}

  local base = (stats.armorBase or 0) * (Config.Tuning.ArmorBaseToReduction or 2.0)

  local extra = 0
  if category == 'bullet' then extra = stats.bulletResist or 0 end
  if category == 'melee' then extra = stats.meleeResist or 0 end
  if category == 'animal' then extra = stats.animalResist or 0 end
  if category == 'fall' then extra = stats.fallResist or 0 end
  if category == 'explosion' then extra = stats.explosionResist or 0 end
  if category == 'poison' then extra = stats.poisonResist or 0 end

  local reduction = base + extra
  reduction = Shared.Clamp(reduction, 0, Config.Tuning.MaxDamageReductionPercent or 60)
  return reduction
end

function Shared.ComputeMoveMultiplier(stats)
  stats = stats or {}

  local staminaCost = (stats.staminaCostModifier or 0)
  local weightPenalty = (stats.weightPenalty or 0)

  local mult = 1.0
  mult = mult - (staminaCost * (Config.Tuning.StaminaCostToMovePenalty or 0.004))
  mult = mult - weightPenalty

  return Shared.Clamp(mult, Config.Tuning.MinMoveMultiplier or 0.78, Config.Tuning.MaxMoveMultiplier or 1.05)
end
