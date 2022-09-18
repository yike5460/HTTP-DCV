-- Dynamiclly add server name to nginx.conf

-- parse request header
local host = ngx.var.host
local uri = ngx.var.uri
local args = ngx.req.get_uri_args()

-- set log location
local log_file = "/var/log/nginx/access.log"

-- set log level
-- local log_level = ngx.INFO

-- loggin requests
local h = ngx.resp.get_headers()
for k, v in pairs(h) do
  ngx.log(ngx.DEBUG, 'Header name: ', k, " Value: ", v)
end

-- get server name
local server_name = host
if args["server_name"] ~= nil then
    server_name = args["server_name"]
end

-- append server name to server_name.conf
-- server {
    -- server_name example.org;
-- }

-- make sure permissions are set correctly
local file, err = io.open("/etc/nginx/conf.d/server_name.conf", "w")
-- local file, err = io.open("/tmp/server_name.conf", "w")

if file==nil then
    ngx.log(ngx.ERR, "Failed to open file: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
else
    file:write("server {")
    file:write("server_name ", server_name, ";")
    file:write("}")
    file:close()
end

-- return 200
ngx.status = ngx.HTTP_OK
ngx.say("OK")

-- reload nginx
os.execute("/usr/local/openresty/nginx/sbin/nginx -s reload")