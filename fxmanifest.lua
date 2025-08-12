fx_version 'bodacious'
game 'gta5'

author 'Canato'
description 'System to buy Companies'
version '1.2.0'

dependency 'es_extended'

shared_scripts {
    'config.lua'
}

client_scripts {
    '@es_extended/locale.lua',
    'locales/*.lua',
    'client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    '@es_extended/locale.lua',
    'locales/*.lua',
    'server.lua'
}