if not crowdsec_ready then
  return
end

local cs = require "crowdsec"
if string.lower(cs.get_mode()) == "stream" then
  cs.SetupStream()
end
if ngx.worker.id() == 0 then
  cs.SetupMetrics()
end
