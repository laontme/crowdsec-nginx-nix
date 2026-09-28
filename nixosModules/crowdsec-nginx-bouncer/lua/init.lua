-- Fail-open until crowdsec-nginx-bouncer-register writes the conf.
local conf = "@bouncerConf@"
local f = io.open(conf, "r")
if f == nil then
  ngx.log(ngx.ERR, "[Crowdsec] bouncer conf missing, fail-open until register")
  crowdsec_ready = false
  return
end
f:close()

cs = require "crowdsec"
local ok, err = cs.init(conf, "crowdsec-nginx-bouncer/v1.2.2")
if ok == nil then
  ngx.log(ngx.ERR, "[Crowdsec] init failed: " .. tostring(err) .. " (fail-open)")
  crowdsec_ready = false
  return
end

crowdsec_ready = true
ngx.log(ngx.NOTICE, "[Crowdsec] initialisation done")
