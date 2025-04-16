-- Sistema Avanzado de Ban para Jugadores
-- Desarrollado por Trae AI

local BanSystem = {}
BanSystem.Config = {
    EnableLogging = true,
    DefaultBanDuration = 7, -- días
    MaxWarningsBeforeBan = 3,
    AdminGroups = {"admin", "moderator", "superadmin"}
}

-- Hacer que BanSystem sea accesible globalmente
_G.BanSystem = BanSystem

-- Cargar módulos
BanSystem.Database = LoadResourceFile(GetCurrentResourceName(), "database/database.lua")
BanSystem.Database = assert(load(BanSystem.Database))()

BanSystem.UI = LoadResourceFile(GetCurrentResourceName(), "ui/interface.lua")
BanSystem.UI = assert(load(BanSystem.UI))()

-- Añadir el módulo de webhook
BanSystem.Webhook = LoadResourceFile(GetCurrentResourceName(), "webhook.lua")
BanSystem.Webhook = assert(load(BanSystem.Webhook))()

-- Inicializar el sistema
function BanSystem:Initialize()
    self.Database:Connect()
    self.UI:Setup()
    
    -- Registrar comandos
    RegisterCommand("banplayer", function(source, args, rawCommand)
        if self:IsAdmin(source) then
            local targetId = tonumber(args[1])
            local reason = table.concat(args, " ", 2)
            self:BanPlayer(source, targetId, reason)
        else
            TriggerClientEvent("chat:addMessage", source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"Sistema de Ban", "No tienes permisos para usar este comando."}
            })
        end
    end, false)
    
    RegisterCommand("openbanui", function(source, args, rawCommand)
        if self:IsAdmin(source) then
            TriggerClientEvent("banSystem:openUI", source)
        else
            TriggerClientEvent("chat:addMessage", source, {
                color = {255, 0, 0},
                multiline = true,
                args = {"Sistema de Ban", "No tienes permisos para usar este comando."}
            })
        end
    end, false)
    
    print("Sistema de Ban inicializado correctamente.")
end

-- Verificar si un jugador es administrador
function BanSystem:IsAdmin(playerId)
    local playerGroup = self:GetPlayerGroup(playerId)
    for _, group in ipairs(self.Config.AdminGroups) do
        if playerGroup == group then
            return true
        end
    end
    return false
end

-- Obtener el grupo de un jugador (implementar según tu sistema de permisos)
function BanSystem:GetPlayerGroup(playerId)
    -- Implementar según tu sistema de permisos
    -- Ejemplo: return exports.yourPermissionSystem:getGroup(playerId)
    return "admin" -- Temporal para pruebas
end

-- Banear a un jugador
function BanSystem:BanPlayer(adminId, targetId, reason, duration)
    local adminName = GetPlayerName(adminId)
    local targetName = GetPlayerName(targetId)
    duration = duration or self.Config.DefaultBanDuration
    
    if not targetName then
        TriggerClientEvent("chat:addMessage", adminId, {
            color = {255, 0, 0},
            multiline = true,
            args = {"Sistema de Ban", "Jugador no encontrado."}
        })
        return false
    end
    
    -- Recopilar identificadores del jugador
    local identifiers = {}
    for _, identifier in ipairs(GetPlayerIdentifiers(targetId)) do
        table.insert(identifiers, identifier)
    end
    
    local banData = {
        targetId = targetId,
        targetName = targetName,
        adminId = adminId,
        adminName = adminName,
        reason = reason,
        duration = duration,
        timestamp = os.time(),
        identifiers = identifiers
    }
    
    local success = self.Database:AddBan(banData)
    
    if success then
        -- Notificar al administrador
        TriggerClientEvent("chat:addMessage", adminId, {
            color = {0, 255, 0},
            multiline = true,
            args = {"Sistema de Ban", "Has baneado a " .. targetName .. " por: " .. reason}
        })
        
        -- Notificar a todos los jugadores
        TriggerClientEvent("chat:addMessage", -1, {
            color = {255, 0, 0},
            multiline = true,
            args = {"Sistema de Ban", targetName .. " ha sido baneado por: " .. reason}
        })
        
        -- Enviar notificación a Discord
        self.Webhook:SendBanMessage(banData)
        
        -- Expulsar al jugador
        DropPlayer(targetId, "Has sido baneado por: " .. reason)
        
        return true
    else
        TriggerClientEvent("chat:addMessage", adminId, {
            color = {255, 0, 0},
            multiline = true,
            args = {"Sistema de Ban", "Error al banear al jugador."}
        })
        return false
    end
end

-- Verificar si un jugador está baneado al conectarse
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local source = source
    local identifiers = GetPlayerIdentifiers(source)
    
    deferrals.defer()
    deferrals.update("Verificando estado de ban...")
    
    local isBanned, banInfo = BanSystem.Database:CheckBan(identifiers)
    
    if isBanned then
        if banInfo.duration > 0 then
            local timeLeft = (banInfo.timestamp + (banInfo.duration * 86400)) - os.time()
            if timeLeft <= 0 then
                -- El ban ha expirado
                BanSystem.Database:RemoveBan(banInfo.id)
                deferrals.done()
            else
                -- Convertir tiempo restante a formato legible
                local days = math.floor(timeLeft / 86400)
                local hours = math.floor((timeLeft % 86400) / 3600)
                local minutes = math.floor((timeLeft % 3600) / 60)
                
                deferrals.done("Estás baneado por: " .. banInfo.reason .. "\nTiempo restante: " .. days .. " días, " .. hours .. " horas, " .. minutes .. " minutos")
            end
        else
            -- Ban permanente
            deferrals.done("Estás baneado permanentemente por: " .. banInfo.reason)
        end
    else
        deferrals.done()
    end
end)

-- Iniciar el sistema cuando el recurso se inicia
AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        BanSystem:Initialize()
    end
end)

-- Mover la función RemoveBan al archivo database/database.lua
-- No debe estar aquí después del return

return BanSystem