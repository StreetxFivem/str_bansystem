-- Módulo de base de datos para el sistema de ban (SQL Version)
local Database = {}

-- Configuración de la base de datos
Database.Config = {
    AutoReconnect = true,
    Debug = false
}

-- Estado de la conexión
Database.Connected = false

-- Conectar a la base de datos
function Database:Connect()
    -- Verificar si oxmysql está disponible
    if not exports.oxmysql then
        print("^1ERROR: oxmysql no encontrado. Por favor instala oxmysql para usar este recurso.^7")
        return false
    end
    
    -- Crear tabla si no existe
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS ban_system (
            id INT AUTO_INCREMENT PRIMARY KEY,
            target_id VARCHAR(50) NOT NULL,
            target_name VARCHAR(255) NOT NULL,
            admin_id VARCHAR(50) NOT NULL,
            admin_name VARCHAR(255) NOT NULL,
            reason TEXT NOT NULL,
            duration INT NOT NULL,
            timestamp INT NOT NULL,
            identifiers TEXT NOT NULL
        )
    ]], {}, function(result)
        if result then
            print("^2Base de datos de bans inicializada correctamente.^7")
            self.Connected = true
        else
            print("^1Error al inicializar la base de datos de bans.^7")
        end
    end)
    
    return true
end

-- Añadir un nuevo ban
function Database:AddBan(banData)
    if not self.Connected then
        return false
    end
    
    -- Asegurarse de que identifiers existe y es una tabla
    if not banData.identifiers or type(banData.identifiers) ~= "table" then
        banData.identifiers = {}
    end
    
    -- Añadir identificadores del jugador si la tabla está vacía
    if #banData.identifiers == 0 and banData.targetId then
        local playerIdentifiers = GetPlayerIdentifiers(banData.targetId)
        if playerIdentifiers and #playerIdentifiers > 0 then
            banData.identifiers = playerIdentifiers
        else
            -- Si no podemos obtener identificadores, usar al menos uno para evitar errores
            banData.identifiers = {"steam:unknown_" .. banData.targetId}
        end
    end
    
    -- Verificar que tenemos al menos un identificador
    if #banData.identifiers == 0 then
        print("^1Error: No se pudieron obtener identificadores para el jugador " .. banData.targetName .. "^7")
        return false
    end
    
    -- Convertir identifiers a JSON
    local identifiersJson = json.encode(banData.identifiers)
    
    -- Insertar en la base de datos
    exports.oxmysql:insert('INSERT INTO ban_system (target_id, target_name, admin_id, admin_name, reason, duration, timestamp, identifiers) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {
            banData.targetId,
            banData.targetName,
            banData.adminId,
            banData.adminName,
            banData.reason,
            banData.duration,
            banData.timestamp,
            identifiersJson
        },
        function(id)
            if id and id > 0 then
                print("^2Ban añadido con ID: " .. id .. "^7")
                banData.id = id
                return true
            else
                print("^1Error al añadir ban a la base de datos.^7")
                return false
            end
        end
    )
    
    return true
end

-- Verificar si un jugador está baneado
function Database:CheckBan(identifiers)
    if not self.Connected then
        return false, nil
    end
    
    -- Crear una promesa para manejar la consulta asíncrona
    local p = promise.new()
    
    -- Obtener todos los bans
    exports.oxmysql:execute('SELECT * FROM ban_system', {}, function(bans)
        if not bans or #bans == 0 then
            p:resolve({false, nil})
            return
        end
        
        -- Verificar cada ban
        for _, ban in ipairs(bans) do
            -- Asegurarse de que identifiers es un JSON válido y decodificarlo
            local success, banIdentifiers = pcall(json.decode, ban.identifiers)
            
            if success and banIdentifiers and type(banIdentifiers) == "table" then
                -- Asegurarse de que podemos iterar sobre banIdentifiers
                if #banIdentifiers > 0 then
                    for _, banIdentifier in ipairs(banIdentifiers) do
                        for _, playerIdentifier in ipairs(identifiers) do
                            if banIdentifier == playerIdentifier then
                                -- Verificar si el ban ha expirado
                                if ban.duration > 0 then
                                    local expirationTime = ban.timestamp + (ban.duration * 86400)
                                    if os.time() > expirationTime then
                                        -- El ban ha expirado, eliminarlo
                                        self:RemoveBan(ban.id)
                                        p:resolve({false, nil})
                                        return
                                    end
                                end
                                
                                -- El jugador está baneado
                                p:resolve({true, ban})
                                return
                            end
                        end
                    end
                else
                    -- Arreglar el registro con identifiers vacíos
                    print("^3Advertencia: Ban ID " .. ban.id .. " tiene un array de identifiers vacío. Intentando reparar...^7")
                    -- Podríamos intentar actualizar este registro o eliminarlo
                    self:RemoveBan(ban.id)
                end
            else
                -- Formato inválido, intentar reparar
                print("^1Error: Formato de identifiers inválido para el ban ID " .. ban.id .. ". Intentando reparar...^7")
                
                -- Opción 1: Eliminar el ban con formato inválido
                self:RemoveBan(ban.id)
                
                -- Opción 2 (alternativa): Intentar reparar el formato
                -- local fixedIdentifiers = json.encode({})
                -- exports.oxmysql:execute('UPDATE ban_system SET identifiers = ? WHERE id = ?', {fixedIdentifiers, ban.id})
            end
        end
        
        -- El jugador no está baneado
        p:resolve({false, nil})
    end)
    
    local result = Citizen.Await(p)
    return table.unpack(result)
end

-- Eliminar un ban
function Database:RemoveBan(banId, adminName)
    if not self.Connected then
        return false
    end
    
    -- Obtener información del ban antes de eliminarlo
    local p = promise.new()
    
    exports.oxmysql:execute('SELECT * FROM ban_system WHERE id = ?', {banId}, function(results)
        if results and #results > 0 then
            local banData = results[1]
            
            -- Eliminar el ban
            exports.oxmysql:execute('DELETE FROM ban_system WHERE id = ?', {banId}, function(affectedRows)
                if affectedRows and affectedRows > 0 then
                    print("^2Ban con ID " .. banId .. " eliminado.^7")
                    
                    -- Enviar notificación a Discord si se proporciona el nombre del admin
                    -- Acceder al webhook a través del objeto global
                    if adminName and _G.BanSystem and _G.BanSystem.Webhook then
                        _G.BanSystem.Webhook:SendUnbanMessage(banData, adminName)
                    end
                    
                    p:resolve(true)
                else
                    print("^1Error al eliminar ban con ID " .. banId .. ".^7")
                    p:resolve(false)
                end
            end)
        else
            print("^1Error: Ban con ID " .. banId .. " no encontrado.^7")
            p:resolve(false)
        end
    end)
    
    return Citizen.Await(p)
end

-- Obtener todos los bans
function Database:GetAllBans()
    if not self.Connected then
        return {}
    end
    
    local p = promise.new()
    
    exports.oxmysql:execute('SELECT * FROM ban_system ORDER BY id DESC', {}, function(results)
        p:resolve(results or {})
    end)
    
    return Citizen.Await(p)
end

-- Obtener bans por nombre de jugador
function Database:GetBansByPlayerName(playerName)
    if not self.Connected then
        return {}
    end
    
    local p = promise.new()
    
    exports.oxmysql:execute('SELECT * FROM ban_system WHERE target_name LIKE ? ORDER BY id DESC', 
        {'%' .. playerName .. '%'}, 
        function(results)
            p:resolve(results or {})
        end
    )
    
    return Citizen.Await(p)
end

-- Verificar si un jugador está baneado por ID
function Database:IsPlayerBanned(playerId)
    if not self.Connected then
        return false, nil
    end
    
    local identifiers = GetPlayerIdentifiers(playerId)
    return self:CheckBan(identifiers)
end

return Database