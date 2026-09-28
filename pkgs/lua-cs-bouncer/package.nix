{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lua-cs-bouncer";
  version = "1.0.17";

  src = fetchFromGitHub {
    owner = "crowdsecurity";
    repo = "lua-cs-bouncer";
    rev = "v${finalAttrs.version}";
    hash = "sha256-WvlFf4JLgPbFByJ5G/NW0uhGbho0D+IIYa+nNt9dOCQ=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lua $out/templates
    cp -r lib/. $out/lua/
    cp -r templates/. $out/templates/
    runHook postInstall
  '';

  meta = {
    description = "CrowdSec Lua library used by nginx/OpenResty bouncers";
    homepage = "https://github.com/crowdsecurity/lua-cs-bouncer";
    changelog = "https://github.com/crowdsecurity/lua-cs-bouncer/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
