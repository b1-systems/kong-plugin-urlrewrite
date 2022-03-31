# kong urlrewrite

Rewrite a request based on a URL provided by a header. The request will then be
made against the provided URL instead of the upstream target that is configured
for the service.

This plugin can only be enabled on routes.

## Configuration

### Enable the plugin on a route

```bash
curl -X POST http://{HOST}:8001/routes/{ROUTE}/plugins \
    --data "name=urlrewrite" \
    --data "config.rewrite_header=Rewrite-To"
```

`HOST` is the domain for the host running Kong.
`ROUTE` is the `id` or the `name` of the route where the plugin should be enabled.

## Usage

An example for a request against a route with this plugin:

``` bash
curl -X GET http://{HOST}:8000/example \
    -H "Rewrite-To: https://httpbin.org/anything"
```
