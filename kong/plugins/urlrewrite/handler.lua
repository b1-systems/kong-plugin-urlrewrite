local cjson = require "cjson"

local utils = require "kong.tools.utils"

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
    -- return with error if header is set but empty
    kong.log.err("Header is empty")
    return kong.response.exit(400, "Bad request")
  elseif rewrite_header == nil then
    -- skip processing if header is not set
    return plugin
  end

  kong.log.info("Header is not empty. Proceeding with parsing")
  local pattern = "(https?)://([^/]+)(/?[^?#]*)"
  local start, _, scheme, host, path = string.find(rewrite_header, pattern)
  if start == nil then
    return kong.response.exit(400, "Bad request")
  end

  local port = (scheme == "http") and 80 or 443

  -- special case: scheme://host:port/path
  local _host, _port = utils.unpack(utils.split(host, ":"))
  if _port ~= nil then
    local ok, _port_num = pcall(tonumber, _port)
    if not ok or _port_num == nil then
      return kong.response.exit(500,
        [[{"message": "Internal Server Error", "details": "Port in rewrite target is NaN"}]],
        {["Content-Type"] = "application/json"}
      )
    end
    host, port = _host, _port_num
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

  kong.log.debug("scheme=" .. scheme
    .. ", host=" .. host
    .. ", port=" .. port
    .. ", path=" .. path)

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

  -- NOTE: apparently, only setting the upstream_{scheme,host,uri} is insufficient.
  kong.service.set_target(host, port)

  kong.log.debug(cjson.encode(log_message))

end --]]

-- return our plugin object
return plugin
