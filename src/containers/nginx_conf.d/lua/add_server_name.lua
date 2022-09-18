-- Dynamiclly add server name to nginx.conf

-- parse request header
local host = ngx.var.host
local uri = ngx.var.uri

-- leave here for future support of url args
-- local args = ngx.req.get_uri_args()

-- leave here for future support of url headers
-- local h = ngx.resp.get_headers()
-- for k, v in pairs(h) do
--     ngx.say(k, " : ", v)
-- end

-- set log location
-- local log_file = "/var/log/nginx/access.log"

-- get server name
local server_name = host


-- get request body
ngx.req.read_body()
-- max_args = 10
local args, err = ngx.req.get_post_args(10)
if args then
    for k, v in pairs(args) do
        if k == "server_name" then
            -- set server name
            server_name = v
        end
    end
else
    local file = ngx.req.get_body_file()
    if file then
        local fh, err = io.open(file, "r")
        if fh then
            local data = fh:read("*a")
            fh:close()
            ngx.say("request is in tmp file, data:", data)
        end
    else
        ngx.say("no body found")
    end
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