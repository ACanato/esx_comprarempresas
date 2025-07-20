fx_version 'bodacious'
game 'gta5'

author 'hivy'
description 'Sistema de Empresas'
version '1.0.0'

dependency 'es_extended'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    'client.lua'
}