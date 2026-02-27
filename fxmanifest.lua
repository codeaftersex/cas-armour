fx_version "cerulean"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
description "Advanced Armor system for RedM!"
author "CAS, UIforc"
version '1.1.0'

lua54 'yes'

games {
  "rdr3"
}

ui_page 'nui/index.html'
nui_devtools 'true'

dependencies {
  'oxmysql',
}

shared_scripts {
  'shared/framework.lua',
  'shared/config.lua',
  'shared/shared.lua'
}

client_scripts {
  'client/dataview.lua',
  'client/client_config.lua',
  'client/client_variables.lua',
  'client/main.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/server_config.lua',
  'server/server_variables.lua',
  'server/server_main.lua'
}


files {
    "nui/**/*"
}


escrow_ignore {
  "**/*"
}
