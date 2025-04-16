-- Módulo de interfaz de usuario para el sistema de ban
local UI = {}

-- Configuración de la UI
UI.Config = {
    Width = 800,
    Height = 600,
    Title = "Sistema Avanzado de Ban"
}

-- Configurar la interfaz
function UI:Setup()
    -- Registrar eventos para la comunicación cliente-servidor
    RegisterNetEvent("banSystem:openUI")
    AddEventHandler("banSystem:openUI", function()
        TriggerClientEvent("banSystem:showUI", source)
    end)
    
    RegisterNetEvent("banSystem:getBans")
    AddEventHandler("banSystem:getBans", function()
        local source = source
        local bans = exports.str_bansystem:GetAllBans()
        TriggerClientEvent("banSystem:receiveBans", source, bans)
    end)
    
    RegisterNetEvent("banSystem:banPlayer")
    AddEventHandler("banSystem:banPlayer", function(data)
        local source = source
        local success = exports.str_bansystem:BanPlayer(source, data.targetId, data.reason, data.duration)
        TriggerClientEvent("banSystem:banResult", source, success)
    end)
    
    RegisterNetEvent("banSystem:unbanPlayer")
    AddEventHandler("banSystem:unbanPlayer", function(banId)
        local source = source
        local success = exports.str_bansystem:RemoveBan(banId)
        TriggerClientEvent("banSystem:unbanResult", source, success)
    end)
    
    print("Interfaz de usuario configurada.")
end

return UI