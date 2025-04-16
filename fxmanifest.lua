fx_version 'cerulean'
game 'gta5'

author 'Trae AI'
description 'Sistema Avanzado de Ban con UI (SQL Version)'
version '1.1.0'

-- Dependencias
dependencies {
    'oxmysql'
}

-- Scripts del lado del servidor
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'webhook.lua',
    'database/database.lua',
    'ui/interface.lua',
    'main.lua'
}

-- Scripts del lado del cliente
client_scripts {
    'ui/client.lua'
}

-- Archivos UI
ui_page 'ui/html/index.html'

-- Archivos para cargar
files {
    'ui/html/index.html',
    'ui/html/styles.css',
    'ui/html/script.js'
}

-- Exportaciones
server_exports {
    'BanPlayer',
    'RemoveBan',
    'GetAllBans',
    'GetBansByPlayerName',
    'IsPlayerBanned'
}