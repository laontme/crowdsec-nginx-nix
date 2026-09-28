#!/bin/sh
set -eu
cscli="cscli -c /etc/crowdsec/config.yaml"
# LAPI can retain a bouncer after rollbacks wipe the key file; delete and re-add.
if $cscli bouncers list -o json | jq -e --arg n "@bouncerName@" 'any(.[]; .name == $n)' >/dev/null; then
  if [ ! -s @apiKeyFile@ ]; then
    echo "nginx bouncer registered but key missing; re-registering" >&2
    $cscli bouncers delete -- "@bouncerName@"
    rm -f @apiKeyFile@
    $cscli bouncers add --output raw -- "@bouncerName@" > @apiKeyFile@
  fi
else
  rm -f @apiKeyFile@
  $cscli bouncers add --output raw -- "@bouncerName@" > @apiKeyFile@
fi

umask 027
@python@ - @bouncerConfTemplate@ @apiKeyFile@ @bouncerConf@ <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
key = Path(sys.argv[2]).read_text().strip()
Path(sys.argv[3]).write_text(text.replace("__API_KEY__", key))
PY
chgrp nginx @bouncerConf@
chmod 0640 @bouncerConf@
chmod 0600 @apiKeyFile@
