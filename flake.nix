{
  description = "Engram CLI and Cloud server Nix packages";

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
        version = "3.7.2";

        osMap = {
          "x86_64-linux" = "linux_amd64";
          "aarch64-linux" = "linux_arm64";
          "x86_64-darwin" = "darwin_amd64";
          "aarch64-darwin" = "darwin_arm64";
        };

        hashMap = {
          "x86_64-linux" = "8db9d5db1c1574b8b830aac4ffbe86c024014aed6b9a3f0406ac3361a152cdf0";
          "aarch64-linux" = "cdbbcb68d3e842d3e52e27edccef55e6fe98ce3cdbc90cd79894323b029efb50";
          "x86_64-darwin" = "d35623443a5d85e8f78338cda5d0bb73b2f7ec6217a57e4abb71904a3e0d6287";
          "aarch64-darwin" = "f96e08db8f47ca49ebc034eba30e468db81eb56df98f9bf21a73366b510695e4";
        };

        target = osMap.${system} or (throw "Unsupported system: ${system}");
        sha256 = hashMap.${system} or (throw "Unsupported system: ${system}");
        url = "https://github.com/Gentleman-Programming/engram/releases/download/v${version}/engram_${version}_${target}.tar.gz";
        cli = pkgs.stdenv.mkDerivation {
          pname = "engram";
          inherit version;

          src = pkgs.fetchurl { inherit url sha256; };
          sourceRoot = ".";

          installPhase = ''
            runHook preInstall
            mkdir -p "$out/bin"
            cp engram "$out/bin/"
            chmod +x "$out/bin/engram"
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Engram CLI: Persistent memory for AI coding agents";
            homepage = "https://github.com/Gentleman-Programming/engram";
            license = licenses.mit;
            mainProgram = "engram";
            maintainers = [ ];
            platforms = platforms.linux ++ platforms.darwin;
          };
        };

        cloudOutputs =
          if pkgs.stdenv.hostPlatform.isLinux then
            import ./nix/engram-cloud.nix { inherit pkgs self; }
          else
            { packages = { }; images = { }; };
      in {
        packages = {
          default = cli;
          engram = cli;
        } // cloudOutputs.packages // cloudOutputs.images;

        checks = cloudOutputs.packages // cloudOutputs.images;
      });
}
