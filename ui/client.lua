-- Cliente para la interfaz de usuario del sistema de ban
local isUIOpen = false
local cachedBans = {}

-- Registrar eventos
RegisterNetEvent("banSystem:showUI")
AddEventHandler("banSystem:showUI", function()
    ToggleUI(true)
end)

RegisterNetEvent("banSystem:receiveBans")
AddEventHandler("banSystem:receiveBans", function(bans)
    cachedBans = bans
    SendNUIMessage({
        type = "updateBans",
        bans = bans
    })
end)

RegisterNetEvent("banSystem:banResult")
AddEventHandler("banSystem:banResult", function(success)
    SendNUIMessage({
        type = "banResult",
        success = success
    })
    
    if success then
        TriggerServerEvent("banSystem:getBans")
    end
end)

RegisterNetEvent("banSystem:unbanResult")
AddEventHandler("banSystem:unbanResult", function(success)
    SendNUIMessage({
        type = "unbanResult",
        success = success
    })
    
    if success then
        TriggerServerEvent("banSystem:getBans")
    end
end)

-- Abrir/cerrar la interfaz
function ToggleUI(state)
    isUIOpen = state
    
    SetNuiFocus(isUIOpen, isUIOpen)
    SendNUIMessage({
        type = "toggleUI",
        state = isUIOpen
    })
    
    if isUIOpen then
        TriggerServerEvent("banSystem:getBans")
    end
end

-- Comandos de teclas
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Cerrar UI con ESC
        if isUIOpen and IsControlJustReleased(0, 27) then
            ToggleUI(false)
        end
    end
end)

-- Callbacks NUI
RegisterNUICallback("closeUI", function(data, cb)
    ToggleUI(false)
    cb("ok")
end)

RegisterNUICallback("banPlayer", function(data, cb)
    TriggerServerEvent("banSystem:banPlayer", data)
    cb("ok")
end)

RegisterNUICallback("unbanPlayer", function(data, cb)
    TriggerServerEvent("banSystem:unbanPlayer", data.banId)
    cb("ok")
end)

RegisterNUICallback("searchPlayer", function(data, cb)
    local results = {}
    local searchTerm = string.lower(data.term)
    
    for _, ban in ipairs(cachedBans) do
        if string.find(string.lower(ban.targetName), searchTerm) then
            table.insert(results, ban)
        end
    end
    
    cb(results)
end)