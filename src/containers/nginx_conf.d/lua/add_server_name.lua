-- Dynamiclly add server name to nginx.conf

local CERTBOT_PRODUCTION_URL = "https://acme-v02.api.letsencrypt.org/directory"
local CERTBOT_STAGING_URL = "https://acme-staging-v02.api.letsencrypt.org/directory"

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

-- set certbot params
local SERVER_NAME = host
local CERTBOT_EMAIL = "demo@example.com"

-- get request body
ngx.req.read_body()
-- max_args = 10
local args, err = ngx.req.get_post_args(10)
if args then
    for k, v in pairs(args) do
        if k == "server_name" then
            -- set server name
            SERVER_NAME = v
        end
        if k == "certbot_email" then
            -- set certbot email
            CERTBOT_EMAIL = v
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
local file, err = io.open("/etc/nginx/conf.d/server_name.conf", "a")
-- local file, err = io.open("/tmp/server_name.conf", "a")

if file==nil then
    ngx.log(ngx.ERR, "Failed to open file: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
else
    file:write("server {")
    file:write("server_name ", SERVER_NAME, ";")
    file:write("}")
    file:close()
end

-- return 200
ngx.status = ngx.HTTP_OK
ngx.say("Nginx server name added successfully")

-- reload nginx
os.execute("/usr/local/openresty/nginx/sbin/nginx -s reload")

-- source and execute shell script to get aws credentials
os.execute("source /scripts/utils.sh")

-- execute certbot to generate new cert, make options configurable TBD
local cmd = "/usr/local/bin/certbot certonly --agree-tos --keep -n --text --preferred-challenges http-01 --authenticator webroot --rsa-key-size 4096 --elliptic-curve secp384r1 --key-type rsa --webroot-path /usr/local/openresty/nginx/html --debug --email " .. CERTBOT_EMAIL .. " --server " .. CERTBOT_PRODUCTION_URL .. " -d " .. SERVER_NAME

local handle = io.popen(cmd, "r")
local result = handle:read("*a")
handle:close()

-- import certificates into AWS ACM
-- error happend when execute aws cli, need to fix, use shell script instead TBD

-- read region from env variable with default value us-west-2
local region = os.getenv("AWS_REGION")
if region == nil then
    region = "us-west-2"
end

local cmd = "/usr/local/bin/aws acm import-certificate --certificate fileb:///etc/letsencrypt/live/" .. SERVER_NAME .. "/cert.pem " .. "--private-key fileb:///etc/letsencrypt/live/" .. SERVER_NAME .. "/privkey.pem " .. "--certificate-chain fileb:///etc/letsencrypt/live/" .. SERVER_NAME .. "/chain.pem " .. "--region " .. region
local handle = io.popen(cmd, "r")
local result = handle:read("*a")
handle:close()

-- modify server conf in previous step to use CloudFront URL as proxy_pass
-- server {
    -- listen 80;
    -- server_name example.org;    
    -- listen 443;
    -- listen [::]:443;
    -- ssl_certificate          /etc/letsencrypt/live/<custom domain>/fullchain.pem;
    -- ssl_certificate_key      /etc/letsencrypt/live/<custom domain>/privkey.pem;
    -- ssl_trusted_certificate  /etc/letsencrypt/live/<custom domain>/chain.pem;
    -- location / {
        -- proxy_pass https://d12345abcdefg.cloudfront.net;
    -- }
    -- include common.conf;
-- }

local CloudFront_URL = "https://d2vrdmmmfog1ys.cloudfront.net/"
-- make sure permissions are set correctly
local file, err = io.open("/etc/nginx/conf.d/server_name.conf", "a")
-- local file, err = io.open("/tmp/server_name.conf", "a")

if file==nil then
    ngx.log(ngx.ERR, "Failed to open file: ", err)
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
else
    file:write("server {")
    file:write("listen 80;")
    file:write("server_name ", SERVER_NAME, ";")
    file:write("listen 443;")
    file:write("listen [::]:443;")
    file:write("location / {")
    file:write("proxy_pass ", CloudFront_URL, ";")
    file:write("}")
    file:write("include common.conf;")
    file:write("}")
    file:close()
end

-- reload nginx
os.execute("/usr/local/openresty/nginx/sbin/nginx -s reload")

-- -- upload certifcate (cert.pem/chain.pem/fullchain.pem/privkey.pem) to s3 bucket
-- local cmd = "aws s3 cp /etc/letsencrypt/live/" .. SERVER_NAME .. "/cert.pem s3://certs/" .. SERVER_NAME .. "/cert.pem"
-- local handle = io.popen(cmd, "r")
-- local result = handle:read("*a")
-- handle:close()

-- local cmd = "aws s3 cp /etc/letsencrypt/live/" .. SERVER_NAME .. "/chain.pem s3://certs/" .. SERVER_NAME .. "/chain.pem"
-- local handle = io.popen(cmd, "r")
-- local result = handle:read("*a")
-- handle:close()

-- local cmd = "aws s3 cp /etc/letsencrypt/live/" .. SERVER_NAME .. "/fullchain.pem s3://certs/" .. SERVER_NAME .. "/fullchain.pem"
-- local handle = io.popen(cmd, "r")
-- local result = handle:read("*a")
-- handle:close()

-- local cmd = "aws s3 cp /etc/letsencrypt/live/" .. SERVER_NAME .. "/privkey.pem s3://certs/" .. SERVER_NAME .. "/privkey.pem"
-- local handle = io.popen(cmd, "r")
-- local result = handle:read("*a")
-- handle:close()

