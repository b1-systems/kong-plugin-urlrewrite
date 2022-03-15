local typedefs = require "kong.db.schema.typedefs"

return {
  {
    name = "urlrewrite_log_messages",
    --endpoint_key = "message", -- ???
    primary_key = { "id" },
    --generate_admin_api = false,
    fields = {
      {
        id = typedefs.uuid,
      },
      {
        created_at = typedefs.auto_timestamp_s,
      },
      {
        message = {
          type = "string",
          required = true,
        }
      }
    }
  }
}
