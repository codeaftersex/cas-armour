
Framework = Framework or {}
Framework.Name = nil
Framework.Ready = false

FW = FW or {}

local _vorpCore = nil
local _rsgCore  = nil

CreateThread(function()
    Wait(100)

    if GetResourceState('vorp_core') == 'started' then
        Framework.Name = "vorp"
        print("^2[cas-armour] VORP Framework detected^7")
    elseif GetResourceState('rsg-core') == 'started' then
        Framework.Name = "rsgcore"
        print("^2[cas-armour] RSGCore Framework detected^7")
    else
        print("^1[cas-armour] ERROR: No supported framework detected! Ensure vorp_core or rsg-core is started.^7")
        return
    end

    if IsDuplicityVersion() then
        if Framework.Name == "vorp" then
            while not _vorpCore do
                local ok, core = pcall(function()
                    return exports.vorp_core and exports.vorp_core:GetCore() or nil
                end)
                if ok and core then
                    _vorpCore = core
                    break
                end
                TriggerEvent('getCore', function(core2)
                    _vorpCore = core2
                end)
                Wait(500)
            end
            print("^2[cas-armour] VORP Core resolved^7")

        elseif Framework.Name == "rsgcore" then
            local ok, core = pcall(function()
                return exports['rsg-core']:GetCoreObject()
            end)
            if ok and core then
                _rsgCore = core
                print("^2[cas-armour] RSGCore object resolved^7")
            else
                print("^1[cas-armour] ERROR: Could not get RSGCore object^7")
                return
            end
        end
    end

    Framework.Ready = true
end)

if IsDuplicityVersion() then

    local function AwaitExport(fn)
        local p = promise.new()
        fn(function(res)
            p:resolve(res)
        end)
        return Citizen.Await(p)
    end

    function FW.GetCharacterId(src)
        if Framework.Name == "vorp" then
            if not _vorpCore then return nil end
            local ok, user = pcall(function()
                return _vorpCore.getUser and _vorpCore.getUser(src) or nil
            end)
            if not ok or not user then return nil end

            local character = user.getUsedCharacter
            if type(character) == 'function' then
                character = character()
            end
            if type(character) ~= 'table' then return nil end

            local charId = character.charIdentifier or character.identifier or character.id or character.charId
            if not charId then return nil end
            return tostring(charId)

        elseif Framework.Name == "rsgcore" then
            if not _rsgCore then return nil end
            local player = _rsgCore.Functions.GetPlayer(src)
            if not player or not player.PlayerData then return nil end
            local cid = player.PlayerData.citizenid
            if not cid then return nil end
            return tostring(cid)
        end

        return nil
    end

    function FW.GetInventoryItems(src)
        if Framework.Name == "vorp" then
            local raw = AwaitExport(function(cb)
                exports.vorp_inventory:getUserInventoryItems(src, cb)
            end) or {}

            local items = {}
            for _, it in ipairs(raw) do
                if it then
                    table.insert(items, {
                        id       = it.id or it.mainid or it.uniqueid,
                        name     = it.name,
                        label    = it.label,
                        desc     = it.desc,
                        count    = it.count or 1,
                        metadata = it.metadata or {},
                    })
                end
            end
            return items

        elseif Framework.Name == "rsgcore" then
            if not _rsgCore then return {} end
            local player = _rsgCore.Functions.GetPlayer(src)
            if not player or not player.PlayerData or not player.PlayerData.items then return {} end

            local items = {}
            for _, it in pairs(player.PlayerData.items) do
                if it and it.name and it.name ~= '' then
                    table.insert(items, {
                        id       = it.slot,
                        name     = it.name,
                        label    = it.label or it.name,
                        desc     = it.description or '',
                        count    = it.amount or it.count or 1,
                        metadata = it.info or {},
                    })
                end
            end
            return items
        end

        return {}
    end

    function FW.CanCarryItem(src, itemName, amount)
        if Framework.Name == "vorp" then
            local res = AwaitExport(function(cb)
                exports.vorp_inventory:canCarryItem(src, itemName, amount, cb)
            end)
            return res == true

        elseif Framework.Name == "rsgcore" then
            if not _rsgCore then return false end
            if exports['rsg-inventory'] and exports['rsg-inventory'].CanAddItem then
                local ok, res = pcall(function()
                    return exports['rsg-inventory']:CanAddItem(src, itemName, amount)
                end)
                if ok then return res ~= false end
            end
            return true
        end

        return false
    end

    function FW.AddItem(src, itemName, amount, metadata)
        if Framework.Name == "vorp" then
            return AwaitExport(function(cb)
                exports.vorp_inventory:addItem(src, itemName, amount, metadata or {}, cb)
            end)

        elseif Framework.Name == "rsgcore" then
            if not _rsgCore then return false end
            local player = _rsgCore.Functions.GetPlayer(src)
            if not player then return false end

            local info = metadata or {}
            local result = player.Functions.AddItem(itemName, amount, nil, info)
            local sharedItem = _rsgCore.Shared.Items and _rsgCore.Shared.Items[itemName]
            if sharedItem then
                TriggerClientEvent('rsg-inventory:client:ItemBox', src, sharedItem, "add", amount)
            end
            return result
        end

        return nil
    end

    function FW.SubItem(src, itemName, amount, metadata)
        if Framework.Name == "vorp" then
            return AwaitExport(function(cb)
                exports.vorp_inventory:subItem(src, itemName, amount, metadata or {}, cb)
            end)

        elseif Framework.Name == "rsgcore" then
            if not _rsgCore then return false end
            local player = _rsgCore.Functions.GetPlayer(src)
            if not player then return false end

            local result = player.Functions.RemoveItem(itemName, amount)
            local sharedItem = _rsgCore.Shared.Items and _rsgCore.Shared.Items[itemName]
            if sharedItem then
                TriggerClientEvent('rsg-inventory:client:ItemBox', src, sharedItem, "remove", amount)
            end
            return result
        end

        return nil
    end

    function FW.SubItemById(src, itemId, amount)
        if Framework.Name == "vorp" then
            if not exports.vorp_inventory.subItemById then return nil end
            local ok, res = pcall(function()
                return AwaitExport(function(cb)
                    exports.vorp_inventory:subItemById(src, itemId, cb, false, amount or 1)
                end)
            end)
            if not ok then return nil end
            return res

        elseif Framework.Name == "rsgcore" then
            if not _rsgCore then return nil end
            local player = _rsgCore.Functions.GetPlayer(src)
            if not player then return nil end

            local slot = tonumber(itemId)
            if not slot then return nil end

            local items = player.PlayerData.items or {}
            for _, it in pairs(items) do
                if it and it.slot == slot then
                    local result = player.Functions.RemoveItem(it.name, amount or 1, slot)
                    return result
                end
            end
            return nil
        end

        return nil
    end

    function FW.SetItemMetadata(src, itemId, metadata)
        if Framework.Name == "vorp" then
            if not exports.vorp_inventory.setItemMetadata then return nil end
            local ok, res = pcall(function()
                return AwaitExport(function(cb)
                    exports.vorp_inventory:setItemMetadata(src, itemId, metadata or {}, cb)
                end)
            end)
            if not ok then return nil end
            return res

        elseif Framework.Name == "rsgcore" then
            if not _rsgCore then return nil end
            local player = _rsgCore.Functions.GetPlayer(src)
            if not player then return nil end

            local slot = tonumber(itemId)
            if not slot then return nil end

            local items = player.PlayerData.items or {}
            for _, it in pairs(items) do
                if it and it.slot == slot then
                    it.info = metadata or {}
                    TriggerClientEvent('rsg-inventory:client:UpdatePlayerInventory', src, items)
                    return true
                end
            end
            return nil
        end

        return nil
    end

    function FW.RegisterUsableItem(itemName, callback)
        if Framework.Name == "vorp" then
            if not exports.vorp_inventory.registerUsableItem then return end
            exports.vorp_inventory:registerUsableItem(itemName, function(data)
                callback({
                    source   = data.source,
                    id       = data.id,
                    metadata = data.metadata or {},
                })
            end)

        elseif Framework.Name == "rsgcore" then
            if not _rsgCore then return end
            _rsgCore.Functions.CreateUseableItem(itemName, function(src, itemData)
                callback({
                    source   = src,
                    id       = itemData and itemData.slot or nil,
                    metadata = itemData and itemData.info or {},
                })
            end)
        end
    end

    function FW.Notify(src, msg)
        if Framework.Name == "rsgcore" then
            TriggerClientEvent('RSGCore:Notify', src, msg, 'primary', 5000)
        else
            TriggerClientEvent('cas-armour:client:notify', src, msg)
        end
    end

    function FW.IsReady()
        return Framework.Ready == true
    end

    function FW.WaitReady()
        while not Framework.Ready do
            Wait(250)
        end
    end

end

exports("GetFrameworkName", function()
    return Framework.Name
end)

exports("IsFrameworkReady", function()
    return Framework.Ready
end)
