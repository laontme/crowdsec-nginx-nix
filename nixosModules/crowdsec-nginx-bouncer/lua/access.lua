if not crowdsec_ready then
  return
end

if ngx.var.uri:find("^/%.well%-known/acme%-challenge/") then
  return
end

local cs = require "crowdsec"
cs.Allow(ngx.var.remote_addr)
