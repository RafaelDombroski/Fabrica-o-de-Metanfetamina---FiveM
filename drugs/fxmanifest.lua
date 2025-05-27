fx_version 'cerulean'
game 'gta5'

author 'Seu Nome'
description 'Sistema de Produção Química'
version '1.0.0'

dependencies {
    'vrp'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    '@vrp/lib/utils.lua',
    'client.lua'
}

server_scripts {
    '@vrp/lib/utils.lua',
    'server.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html'
}