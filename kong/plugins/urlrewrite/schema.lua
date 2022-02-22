local typedefs = require "kong.db.schema.typedefs"

-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local schema = {
  name = plugin_name,
  fields = {
    -- this plugin cannot be configured on a consumer
    { consumer = typedefs.no_consumer },
    -- this plugin cannot be configured on a service
    { service = typedefs.no_service },
    -- plugin works on http
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
            { rewrite_header = typedefs.header_name {
                    required = true,
                    default = "Rewrite-To",
                }
            }
        },
        entity_checks = {
        },
      },
    },
  },
}

return schema
