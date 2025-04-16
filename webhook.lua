-- Sistema de Webhook para Discord
local Webhook = {}

-- Configuración del webhook
Webhook.Config = {
    Enabled = true,
    URL = "https://discord.com/api/webhooks/1361407487118676049/WC2JkC0evEtWlbcRODRcRNCztxspquQC4hXI7hjed1N217RQvkcJ9iQx4zWbOW-LaQsY", -- Reemplazar con tu URL de webhook de Discord
    BotName = "Sistema de Ban",
    BotAvatar = "https://i.imgur.com/YOUR_AVATAR.png", -- Reemplazar con URL de imagen
    Color = 16711680, -- Color rojo en decimal
    Footer = "Sistema Avanzado de Ban"
}

-- Enviar mensaje de ban a Discord
function Webhook:SendBanMessage(banData)
    if not self.Config.Enabled or not self.Config.URL or self.Config.URL == "https://discord.com/api/webhooks/1361407487118676049/WC2JkC0evEtWlbcRODRcRNCztxspquQC4hXI7hjed1N217RQvkcJ9iQx4zWbOW-LaQsY" then
        return false
    end
    
    -- Formatear duración
    local duration = banData.duration > 0 and banData.duration .. " días" or "Permanente"
    
    -- Crear embed para Discord
    local embed = {
        {
            ["color"] = self.Config.Color,
            ["title"] = "**Nuevo Ban**",
            ["description"] = "Un jugador ha sido baneado del servidor.",
            ["fields"] = {
                {
                    ["name"] = "Jugador Baneado",
                    ["value"] = banData.targetName,
                    ["inline"] = true
                },
                {
                    ["name"] = "Admin",
                    ["value"] = banData.adminName,
                    ["inline"] = true
                },
                {
                    ["name"] = "Razón",
                    ["value"] = banData.reason,
                    ["inline"] = false
                },
                {
                    ["name"] = "Duración",
                    ["value"] = duration,
                    ["inline"] = true
                },
                {
                    ["name"] = "Fecha",
                    ["value"] = os.date("%d/%m/%Y %H:%M:%S", banData.timestamp),
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = self.Config.Footer
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ", banData.timestamp)
        }
    }
    
    -- Preparar payload
    local payload = {
        username = self.Config.BotName,
        avatar_url = self.Config.BotAvatar,
        embeds = embed
    }
    
    -- Enviar a Discord
    PerformHttpRequest(self.Config.URL, function(err, text, headers) end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
    
    return true
end

-- Enviar mensaje de desbaneo a Discord
function Webhook:SendUnbanMessage(banData, adminName)
    if not self.Config.Enabled or not self.Config.URL or self.Config.URL == "https://discord.com/api/webhooks/1361407487118676049/WC2JkC0evEtWlbcRODRcRNCztxspquQC4hXI7hjed1N217RQvkcJ9iQx4zWbOW-LaQsY" then
        return false
    end
    
    -- Crear embed para Discord
    local embed = {
        {
            ["color"] = 65280, -- Color verde en decimal
            ["title"] = "**Jugador Desbaneado**",
            ["description"] = "Un jugador ha sido desbaneado del servidor.",
            ["fields"] = {
                {
                    ["name"] = "Jugador Desbaneado",
                    ["value"] = banData.target_name,
                    ["inline"] = true
                },
                {
                    ["name"] = "Admin",
                    ["value"] = adminName,
                    ["inline"] = true
                },
                {
                    ["name"] = "Ban Original",
                    ["value"] = "Razón: " .. banData.reason,
                    ["inline"] = false
                },
                {
                    ["name"] = "Fecha",
                    ["value"] = os.date("%d/%m/%Y %H:%M:%S"),
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = self.Config.Footer
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    -- Preparar payload
    local payload = {
        username = self.Config.BotName,
        avatar_url = self.Config.BotAvatar,
        embeds = embed
    }
    
    -- Enviar a Discord
    PerformHttpRequest(self.Config.URL, function(err, text, headers) end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
    
    return true
end

return Webhook