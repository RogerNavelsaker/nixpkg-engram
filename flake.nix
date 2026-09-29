{
  description = "Engram: Persistent memory for AI coding agents";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://rogernavelsaker.cachix.org"
      "https://nacosolutions.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "rogernavelsaker.cachix.org-1:n1DtzMNhA9Rz4Kg3xlXOi/KceULu8VrMbs9WXyMFQNQ="
      "nacosolutions.cachix.org-1:JzCiW2CLcuLXtwOVAg3SlSK/kpqWbfSFEVenyKVUlug="
    ];
  };


  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        version = "2.2.1";

        osMap = {
          "x86_64-linux" = "linux_amd64";
          "aarch64-linux" = "linux_arm64";
          "x86_64-darwin" = "darwin_amd64";
          "aarch64-darwin" = "darwin_arm64";
        };

        hashMap = {
          "x86_64-linux" = "5094bbe764f4c775bb17ce7ac53931323ca184a1f57e88d458aaa4c4d6e6a85a";
          "aarch64-linux" = "a23952a114f3f6cfb4e9714d84f1f489b627694d18890e2cf9ce17b81df4d6e1";
          "x86_64-darwin" = "a1a56d68d6179aa055aadbe35bfbaa34639e97ad99dcc95ec894b0248b0f4111";
          "aarch64-darwin" = "1e4cf5b67fd79ca07535eb01ea3a03ba942862c209dfe47e6cee86ec0cbeadaf";
        };

        target = osMap.${system} or (throw "Unsupported system: ${system}");
        sha256 = hashMap.${system} or (throw "Unsupported system: ${system}");

        url = "https://github.com/Gentleman-Programming/engram/releases/download/v${version}/engram_${version}_${target}.tar.gz";
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "engram";
          inherit version;

          src = pkgs.fetchurl {
            inherit url sha256;
          };

          sourceRoot = ".";

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp engram $out/bin/
            chmod +x $out/bin/engram
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Engram: Persistent memory for AI coding agents";
            homepage = "https://github.com/Gentleman-Programming/engram";
            license = licenses.mit;
            mainProgram = "engram";
            maintainers = [ ];
            platforms = platforms.linux ++ platforms.darwin;
          };
        };
      }
    );
}