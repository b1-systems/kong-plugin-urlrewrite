local plugin_name = "urlrewrite"
local package_name = "kong-plugin-" .. plugin_name
local package_version = "0.1.0"
local rockspec_revision = "1"


package = package_name
version = package_version .. "-" .. rockspec_revision
supported_platforms = { "linux", "macosx" }

source = {
    url = "..."
}

description = {
  summary = "Kong plugin to rewrite scheme, host and/or path of a request by header.",
  license = "Apache 2.0",
}


dependencies = {
}


build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..plugin_name..".daos"] = "kong/plugins/"..plugin_name.."/daos.lua",
    ["kong.plugins."..plugin_name..".handler"] = "kong/plugins/"..plugin_name.."/handler.lua",
    ["kong.plugins."..plugin_name..".migrations"] = "kong/plugins/"..plugin_name.."/migrations/init.lua",
    ["kong.plugins."..plugin_name..".migrations.000_base_urlrewrite.lua"] = "kong/plugins/"..plugin_name.."/migrations/000_base_urlrewrite.lua",
    ["kong.plugins."..plugin_name..".schema"] = "kong/plugins/"..plugin_name.."/schema.lua",
  }
}
