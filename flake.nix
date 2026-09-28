{
  description = "CrowdSec nginx Lua bouncer for NixOS (staging until nixpkgs)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          lua-cs-bouncer = pkgs.callPackage ./pkgs/lua-cs-bouncer { };
          default = self.packages.${system}.lua-cs-bouncer;
        }
      );

      nixosModules = {
        crowdsec-nginx-bouncer =
          { ... }:
          {
            imports = [ ./nixosModules/crowdsec-nginx-bouncer ];
            nixpkgs.overlays = [ self.overlays.default ];
          };
        default = self.nixosModules.crowdsec-nginx-bouncer;
      };

      # Convenience when this flake is used as an input:
      #   overlays.default
      overlays.default = final: prev: {
        lua-cs-bouncer = final.callPackage ./pkgs/lua-cs-bouncer { };
      };
    };
}
