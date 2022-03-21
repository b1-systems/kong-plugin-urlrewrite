local cjson = require "cjson"

-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.


local plugin = {
  PRIORITY = 800, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1",
}


-- runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)
  local rewrite_header = kong.request.get_header(plugin_conf.rewrite_header)
  if rewrite_header == "" then
    -- check if header is not empty
    kong.log.err("Header is empty")
    return kong.response.exit(400, "Bad request")
  elseif rewrite_header == nil then
    -- check if header exists
    kong.log.err("Header is nil")
    return kong.response.exit(400, "Bad request")
  end

  kong.log.info("Header is not empty. Proceeding with parsing")
  local pattern = "(https?)://([^/]+)(/?[^?#]*)"
  local start, _, scheme, host, path = string.find(rewrite_header, pattern)
  if start == nil then
    return kong.response.exit(400, "Bad request")
  end

  local log_message = {
    original_request = {
      headers = kong.request.get_headers(),
      scheme = kong.request.get_scheme(),
      path = kong.request.get_path(),
    },
    has_transformed = {
      scheme = false,
      host = false,
      path = false,
    }
  }

  kong.log.inspect({scheme=scheme, host=host, path=path})

  if scheme ~= nil and scheme ~= "" then
    if kong.request.get_scheme() ~= scheme then
      kong.service.request.set_scheme(scheme)
      log_message.has_transformed.scheme = true
    end
  end

  if host ~= nil and host ~= "" then
    if kong.request.get_host() ~= host then
      kong.service.request.set_header("Host", host)
      log_message.has_transformed.host = true
    end
  end

  if path ~= nil and path ~= "" then
    if kong.request.get_path() ~= path then
      --kong.service.request.set_path(path)
      ngx.var.upstream_uri = path
      log_message.has_transformed.path = true
    end
  end

  local entity, err = kong.db.urlrewrite_log_messages:insert({ message = cjson.encode(log_message)})

  if not entity then
    kong.log.err("Error when inserting log message: " .. err)
  end

  -- NOTE: apparently, only setting the upstream_{scheme,host,uri} is insufficient.
  kong.service.set_target(host, scheme == "http" and 80 or 443)

end --]]

-- return our plugin object
return plugin
