# crowdsec-nginx-nix

CrowdSec **nginx Lua bouncer** for NixOS (AppSec-capable). Staging flake until this lands in nixpkgs.

Upstream: [lua-cs-bouncer](https://github.com/crowdsecurity/lua-cs-bouncer) / [cs-nginx-bouncer](https://github.com/crowdsecurity/cs-nginx-bouncer).

## Use (before nixpkgs merge)

```nix
{
  inputs.crowdsec-nginx.url = "github:laontme/crowdsec-nginx-nix";
  # or path: /Users/you/Work/crowdsec-nginx-nix

  outputs = { nixpkgs, crowdsec-nginx, ... }: {
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      modules = [
        crowdsec-nginx.nixosModules.crowdsec-nginx-bouncer
        {
          services.crowdsec.enable = true; # LAPI
          services.crowdsec-nginx-bouncer = {
            enable = true;
            appsecUrl = "http://127.0.0.1:7422"; # or null for decisions-only
          };
        }
      ];
    };
  };
}
```

## Layout

- `pkgs/lua-cs-bouncer` — package (nixpkgs `by-name` shape)
- `nixosModules/crowdsec-nginx-bouncer` — NixOS module

## nixpkgs

Intended PR: package first, then module next to `services.crowdsec-firewall-bouncer`.  
AI-assisted work must follow nixpkgs `CONTRIBUTING.md` (human review + `Assisted-by:` trailer).
