--[[
    This file is part of legacy
    Create at 25/12/2022 14:40

    Copyright (c) legacy - All Rights Reserved
    
    Unauthorized using, copying, modifying and/or distributing of this file,
    via any medium is strictly prohibited. This code is confidential
--]]

---@author Atmos-DEV

ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(500)
    end
end)

function spairs(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function KeyboardInput(entryTitle, textEntry, inputText, maxLength)
    RageUI.CloseAll()
    AddTextEntry(entryTitle, textEntry)
    DisplayOnscreenKeyboard(1, entryTitle, "", inputText, "", "", "", maxLength)
    blockinput = true

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Citizen.Wait(500)
        blockinput = false
        RageUI.Visible(RMenu:Get("resources", "gestion"), true)
        return result
    else
        Citizen.Wait(500)
        blockinput = false
        RageUI.Visible(RMenu:Get("resources", "gestion"), true)
        return nil
    end
end

function starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

function checkstatus(status)
    if status == "started" then
        return "~g~En fonction"
    else
        return "~r~Arrêté"
    end
end

QDCResources = {
    isMenuOpened = false,
    spawnPlayer = true,
    resourcesNumber = nil,
    resourcesList = {},
    filtre = nil,
}

RMenu.Add("resources", "gestion", RageUI.CreateMenu("Resources", "~b~Gestion :", nil, nil, "aLib", "black"))
RMenu:Get("resources", "gestion").Closed = function()
    QDCResources.isMenuOpened = false
    QDCResources.filtre = nil
end

RMenu.Add('resources', 'options', RageUI.CreateSubMenu(RMenu:Get('resources', 'gestion'), 'Resources', "~b~Options :"))

local function openMenu()

    if QDCResources.isMenuOpened then return end
    QDCResources.isMenuOpened = true

    RageUI.Visible(RMenu:Get("resources", "gestion"), true)

    Citizen.CreateThread(function()
        while QDCResources.isMenuOpened do
            if QDCResources.resourcesList and QDCResources.resourcesNumber then
                RageUI.IsVisible(RMenu:Get("resources", "gestion"), true, true, true, function()
                    RageUI.Button("Filtre", nil, {RightLabel = QDCResources.filtre}, true, {
                        onSelected = function()
                            QDCResources.filtre = KeyboardInput("atmos", "Nom de la resource", "", 16)
                            if QDCResources.filtre ~= nil then
                                QDCResources.filtre = QDCResources.filtre
                            else
                                QDCResources.filtre = nil
                            end
                        end
                    })
                    RageUI.Button("Refresh", nil, {RightLabel = "→→→"}, true, {
                        onSelected = function()
                            ExecuteCommand("refresh")
                            ESX.ShowNotification("Vous venez de ~b~synchroniser~s~ les resources avec le serveur !")
                            refreshResources()
                        end
                    })
                    RageUI.Separator("↓ Nombre de resources ~b~"..QDCResources.resourcesNumber.."~s~ ↓")
                    for k, v in spairs(QDCResources.resourcesList, function(t,a,b) return t[b].name > t[a].name end) do
                        resourcename = v.name
                        status = v.status
                        if not QDCResources.filtre then
                            RageUI.Button(k, nil, {RightLabel = checkstatus(v.status).." ~s~→→→"}, true, {
                                onSelected = function()
                                    status = v.status
                                    resourcename = v.name
                                end
                            }, RMenu:Get("resources", "options"))
                        elseif starts(resourcename:lower(), QDCResources.filtre:lower()) then
                            RageUI.Button(k, nil, {RightLabel = checkstatus(v.status).." ~s~→→→"}, true, {
                                onSelected = function()
                                    status = v.status
                                    resourcename = v.name
                                end
                            }, RMenu:Get("resources", "options"))
                        end
                    end
                end)
                RageUI.IsVisible(RMenu:Get("resources", "options"), true, true, true, function()
                    RageUI.Separator("↓ Resource : ~b~"..resourcename.."~s~ ↓")
                    if status == "started" then
                        RageUI.Button("~g~Redémarrer la resource", nil, {RightLabel = "→→→"}, true, {
                            onSelected = function()
                                ExecuteCommand("ensure "..resourcename)
                                refreshResources()
                                ESX.ShowNotification(("~g~Redémarrage~s~ de la resource ~b~%s~s~ !"):format(resourcename))
                                RageUI.GoBack()
                            end
                        })
                    else
                        RageUI.Button("~g~Démarrer la resource", nil, {RightLabel = "→→→"}, true, {
                            onSelected = function()
                                ExecuteCommand("ensure "..resourcename)
                                refreshResources()
                                ESX.ShowNotification(("~g~Démarrage~s~ de la resource ~b~%s~s~ !"):format(resourcename))
                                RageUI.GoBack()
                            end
                        })
                    end
                    RageUI.Button("~r~Stopper la resource", nil, {RightLabel = "→→→"}, true, {
                        onSelected = function()
                            ExecuteCommand("stop "..resourcename)
                            refreshResources()
                            ESX.ShowNotification(("~r~Arrêt~s~ de la resource ~b~%s~s~ !"):format(resourcename))
                            RageUI.GoBack()
                        end
                    })
                end)
            end
            Wait(0)
        end
    end)
end

RegisterCommand(ConfigResourcesGestion.commandName, function()
    ESX.TriggerServerCallback("QDC:getPlayerLicense", function(license)
        for k, v in pairs(ConfigResourcesGestion.licenseList) do
            if license == v then
                refreshResources()
                openMenu()
            else
                ESX.ShowNotification("~r~Problème~s~ : Vous n'avez pas la permission nécessaire !")
            end
        end
    end)
end)

function refreshResources()
    ESX.TriggerServerCallback("QDC:getResourcesInfos", function(resourcesList, resourcesNumber)
        QDCResources.resourcesList = resourcesList
        QDCResources.resourcesNumber = resourcesNumber
    end)
end

RegisterKeyMapping(ConfigResourcesGestion.commandName, 'Resources Gestion', 'keyboard', ConfigResourcesGestion.defaultKey)