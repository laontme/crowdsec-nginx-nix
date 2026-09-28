{
  config,
  lib,
  pkgs,
  options,
  ...
}:

# Generic CrowdSec nginx Lua bouncer + optional AppSec.
# Pair with services.crowdsec (LAPI). Does not install the engine.
let
  cfg = config.services.crowdsec-nginx-bouncer;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  luaCs = cfg.package;

  initLua = pkgs.replaceVars ./lua/init.lua {
    bouncerConf = cfg.configPath;
    luaCsRoot = "${luaCs}/lua";
  };

  nginxHttp = pkgs.replaceVars ./nginx-http.conf {
    crowdsecLog = cfg.accessLogPath;
    initLua = "${initLua}";
    workerLua = "${./lua/worker.lua}";
    accessLua = "${./lua/access.lua}";
  };

  bouncerConfTemplate = pkgs.replaceVars ./bouncer.conf {
    apiUrl = cfg.apiUrl;
    appsecUrl = if cfg.appsecUrl != null then cfg.appsecUrl else "";
    banTemplate = "${luaCs}/templates/ban.html";
  };

  registerScript = pkgs.replaceVars ./register-bouncer.sh {
    bouncerName = cfg.bouncerName;
    apiKeyFile = cfg.apiKeyPath;
    bouncerConf = cfg.configPath;
    bouncerConfTemplate = "${bouncerConfTemplate}";
    python = lib.getExe pkgs.python3;
  };
in
{
  options.services.crowdsec-nginx-bouncer = {
    enable = mkEnableOption "CrowdSec nginx Lua bouncer";

    package = mkPackageOption pkgs "lua-cs-bouncer" { };

    apiUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:8080";
      description = "CrowdSec LAPI URL.";
    };

    appsecUrl = mkOption {
      type = types.nullOr types.str;
      default = "http://127.0.0.1:7422";
      description = ''
        AppSec URL. Set to null to only enforce LAPI decisions (no WAF body inspection).
      '';
    };

    bouncerName = mkOption {
      type = types.str;
      default = "nginx";
      description = "Name used with `cscli bouncers add`.";
    };

    configPath = mkOption {
      type = types.path;
      default = "/var/lib/crowdsec/nginx-bouncer.conf";
      description = "Runtime bouncer config path (written by the register service).";
    };

    apiKeyPath = mkOption {
      type = types.path;
      default = "/var/lib/crowdsec/nginx-bouncer.key";
      description = "Where the bouncer API key is stored.";
    };

    accessLogPath = mkOption {
      type = types.path;
      default = "/var/log/nginx/crowdsec.log";
      description = "Extra nginx access_log in combined format for the nginx collection.";
    };

    registerBouncer = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Register this bouncer with local LAPI via cscli (requires services.crowdsec).";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          !cfg.registerBouncer.enable
          || ((options.services ? crowdsec) && config.services.crowdsec.enable);
        message = "services.crowdsec-nginx-bouncer.registerBouncer needs services.crowdsec.enable";
      }
    ];

    # options.users.users ? crowdsec is always false (dynamic attr); set unconditionally.
    users.users.crowdsec.extraGroups = [ "nginx" ];

    systemd.tmpfiles.rules = [
      "d /var/lib/crowdsec 0750 crowdsec crowdsec -"
      "f ${cfg.accessLogPath} 0640 nginx nginx -"
    ];

    # Share a real /var/lib/crowdsec with the engine (no DynamicUser private/ symlink).
    systemd.services.crowdsec-nginx-bouncer-register = mkIf cfg.registerBouncer.enable {
      description = "Register nginx Lua bouncer with CrowdSec LAPI";
      wantedBy = [ "multi-user.target" ];
      after = [ "crowdsec.service" ];
      wants = [ "crowdsec.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "crowdsec";
        Group = "crowdsec";
        SupplementaryGroups = [ "nginx" ];
        StateDirectory = "crowdsec";
        RemainAfterExit = true;
        ExecStart = "${pkgs.runtimeShell} ${registerScript}";
        ExecStartPost = "+${pkgs.systemd}/bin/systemctl try-reload-or-restart nginx.service";
      };
      path = [
        config.services.crowdsec.package
        pkgs.jq
        pkgs.coreutils
      ];
    };

    # NixOS wires resty.core automatically; we only add CrowdSec's Lua deps.
    services.nginx = {
      lua.enable = true;
      lua.extraPackages = ps: [
        ps.lua-resty-http
        ps.lua-resty-lrucache
        ps.lua-cjson
      ];
      appendHttpConfig = lib.mkAfter ''
        include ${nginxHttp};
      '';
    };
  };
}
