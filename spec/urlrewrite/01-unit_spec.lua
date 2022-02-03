local PLUGIN_NAME = "urlrewrite"


-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end


describe(PLUGIN_NAME .. ": (schema)", function()

    it("minimal config validates", function()
        assert(validate({}))
    end)

    it("full config validates", function()
        assert(validate({
                rewrite_header = "Rewrite-To"
            }))
    end)

    it("header name must not be empty", function()
        local config = { rewrite_header = "" }
        local ok, err = validate(config)
        assert.falsy(ok)
        assert.same({ rewrite_header = "length must be at least 1" },
            err.config)
    end)


    -- TODO: maybe test if plugin can only be enabled on routes
end)
