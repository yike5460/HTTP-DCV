-- health check for nginx, simply return 200
ngx.status = ngx.HTTP_OK
ngx.say("OK")

