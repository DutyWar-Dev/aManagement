--[[
    This file is part of legacy
    Create at 25/12/2022 14:37

    Copyright (c) legacy - All Rights Reserved
    
    Unauthorized using, copying, modifying and/or distributing of this file,
    via any medium is strictly prohibited. This code is confidential
--]]

---@author Atmos-DEV

ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

AddEventHandler('onResourceStart', function()
    for k, v in pairs(ConfigResourcesGestion.licenseList) do
        ExecuteCommand(("add_principal identifier.%s group.%s"):format(v,ConfigResourcesGestion.defaultRank))
    end
end)

ESX.RegisterServerCallback("QDC:getPlayerLicense", function(source, cb)
    for k,v in pairs(GetPlayerIdentifiers(source))do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            steamid = v
        end
    end
    if steamid then
        cb(steamid)
    end
end)

ESX.RegisterServerCallback("QDC:getResourcesInfos", function(source, cb)
    local result = GetNumResources()
    local resourceList = {}
    for i = 0, result, 1 do
        local resource_name = GetResourceByFindIndex(i)
        if resource_name then
            resourceList[resource_name] = {
                status = GetResourceState(resource_name),
                name = resource_name
            }
        end
    end
    cb(resourceList, result)
end)