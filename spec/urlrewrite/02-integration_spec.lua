local helpers = require "spec.helpers"


local PLUGIN_NAME = "urlrewrite"

--[[
  define 2 small mock servers, based on Kong's custom_nginx.template fixture
]]
local fixtures = {
  http_mock = {
    test1_upstream = [[
      server {
        server_name test1.localhost;
        listen 8080;
        keepalive_requests 10;

        location / {
          content_by_lua_block {
            local mu = require "spec.fixtures.mock_upstream"
            ngx.status = 404
            return mu.send_default_json_response()
          }
        }

        location = /request {
          content_by_lua_block {
            local mu = require "spec.fixtures.mock_upstream"
            return mu.send_default_json_response()
          }
        }

        location = /status/200 {
          return 200;
        }

        location = /status/404 {
          return 404;
        }
      }
    ]],
    test2_upstream = [[
      server {
        server_name test2.localhost;
        listen 8081;
        keepalive_requests 10;

        location / {
          content_by_lua_block {
            local mu = require "spec.fixtures.mock_upstream"
            ngx.status = 404
            return mu.send_default_json_response()
          }
        }

        location = / {
          return 200;
        }

        location = /request {
          content_by_lua_block {
            local mu = require "spec.fixtures.mock_upstream"
            return mu.send_default_json_response()
          }
        }

        location = /status/200 {
          return 200;
        }

        location = /status/404 {
          return 404;
        }
      }
    ]]
  }
}


for _, strategy in helpers.all_strategies() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy == "off" and "postgres" or strategy, nil, { PLUGIN_NAME })

      local service_upstream1 = bp.services:insert({
        name = "upstream_service1",
        host = "test1.localhost",
        port = 80,
      })

      local route1 = bp.routes:insert({
        service = service_upstream1,
        --paths = { "path1" },
        hosts = { "test1.com" },
      })
      local _ = bp.routes:insert({
        service = service_upstream1,
        --paths = { "path2" },
        hosts = { "test2.com" },
      })

      local upstream1 = bp.upstreams:insert({
        name = service_upstream1.host,
      })
      bp.targets:insert({
        upstream = { id = upstream1.id },
        target = "127.0.0.1:8080",
      })
      -- add the plugin to test to the route we created
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {},
      }

      local upstream2 = bp.upstreams:insert({
        name = "test2.localhost",
      })
      bp.targets:insert({
        upstream = { id = upstream2.id },
        target = "127.0.0.1:8081",
      })

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
        -- write & load declarative config, only if 'strategy=off'
        declarative_config = strategy == "off" and helpers.make_yaml_file() or nil,
      }, nil, nil, fixtures))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)

    describe("request", function()
      it("accepted if header is present and not empty", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            ["Host"] = "test1.com",
            ["Rewrite-To"] = "http://test1.localhost/request",
          }
        })
        assert.res_status(200, r)
      end)
    end)

    describe("request", function()
      it("rejected if header is not present", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            ["Host"] = "test1.com",
          }
        })
        assert.res_status(400, r)
      end)
    end)

    describe("request", function ()
      it("not rewritten if request goes to route without plugin", function ()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            ["Host"] = "test2.com",
            ["Rewrite-To"] = "http://test1.localhost/status/404",
          }
        })
        assert.res_status(200, r)
      end)
    end)

    describe("request", function()
      it("accepted if header contains URL without path and no trailing slash", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            ["Host"] = "test1.com",
            ["Rewrite-To"] = "http://test2.localhost",
          }
        })
        assert.res_status(200, r)
      end)
    end)

    describe("request", function()
      it("accepted if header contains URL without path and but trailing slash", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            ["Host"] = "test1.com",
            ["Rewrite-To"] = "http://test2.localhost/",
          }
        })
        assert.res_status(200, r)
      end)
    end)

    describe("request", function()
      it("rejected if header contains invalid URL", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            ["Host"] = "test1.com",
            ["Rewrite-To"] = "foo://bar",
          }
        })
        assert.res_status(400, r)
      end)
    end)

    describe("request", function()
      it("rejected if header contains URL with malformed port", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            ["Host"] = "test1.com",
            ["Rewrite-To"] = "http://test1.localhost:8a0/request",
          }
        })
        assert.res_status(500, r)
      end)
    end)

    describe("request", function()
      it("rewritten to the path given in the header", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/404",
          headers = {
            ["Host"] = "test1.com",
            ["Rewrite-To"] = "http://test1.localhost/request",
          }
        })

        assert.res_status(200, r)

        local new_uri = assert.request(r).kong_request.vars.uri
        assert.are.equal("/request", new_uri)
      end)
    end)

    describe("request", function()
      it("rewritten to the host given in the header", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/404",
          headers = {
            ["Host"] = "test1.com",
            ["Rewrite-To"] = "http://test2.localhost/request",
          }
        })

        assert.res_status(200, r)

        local new_host = assert.request(r).has.header("Host")
        assert.are.equal("test2.localhost", new_host)
      end)
    end)

    describe("request", function()
      it("rewritten to the scheme given in the header", function()
        local r = assert(client:send {
          schema = "https",
          method = "GET",
          path = "/status/404",
          headers = {
            ["Host"] = "test1.com",
            ["Rewrite-To"] = "http://test1.localhost/request",
          }
        })

        assert.res_status(200, r)

        local new_scheme = assert.request(r).kong_request.vars.scheme
        assert.are.equal("http", new_scheme)
      end)
    end)

    describe("request", function()
      it("passes if header contains URL with port number", function()
        local r = assert(client:send {
          method = "GET",
          path = "/status/200",
          headers = {
            ["Host"] = "test1.com",
            ["Rewrite-To"] = "http://test1.localhost:80/request",
          }
        })
        assert.res_status(200, r)
      end)
    end)

  end)
end
