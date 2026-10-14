{ pkgs, self }:

let
  system = pkgs.stdenv.hostPlatform.system;
  version = "3.4.0";
  assets = {
    "x86_64-linux" = {
      file = "engram_3.4.0_linux_amd64.tar.gz";
      hash = "sha256-cV/aYlVW5G1l3bRSa7f4ij/uUznKPETORMxlLxf6V/E=";
    };
    "aarch64-linux" = {
      file = "engram_3.4.0_linux_arm64.tar.gz";
      hash = "sha256-MwnpwLu1OdGD/Vqp+aE816oOgewlErW+3vuLK901s+U=";
    };
  };
  asset = assets.${system} or (throw "Engram Cloud does not support ${system}");
  archive = pkgs.fetchurl {
    url = "https://github.com/Gentleman-Programming/engram/releases/download/v${version}/${asset.file}";
    hash = asset.hash;
  };
  engramCloud =
    pkgs.runCommand "engram-cloud-${version}"
      {
        nativeBuildInputs = [
          pkgs.gnutar
          pkgs.gzip
        ];
      }
      ''
        mkdir -p "$out/bin"
        tar -xzf ${archive} -C "$out/bin" engram
        chmod 0555 "$out/bin/engram"
      '';
  revision = if self ? dirtyRev then self.dirtyRev else self.rev or "unknown";
  image = pkgs.dockerTools.buildLayeredImage {
    name = "agent-services-engram";
    tag = "latest";
    maxLayers = 16;
    contents = [
      pkgs.cacert
      pkgs.tzdata
      pkgs.dockerTools.fakeNss
      engramCloud
    ];
    fakeRootCommands = ''
      mkdir -p ./tmp ./data
      chown -R 10001:10001 ./data
      chmod 0700 ./data
      chmod 1777 ./tmp
    '';
    config = {
      Labels = {
        "org.opencontainers.image.title" = "Engram Cloud";
        "org.opencontainers.image.description" =
          "Engram Cloud server using an external PostgreSQL database";
        "org.opencontainers.image.source" = "https://github.com/RogerNavelsaker/nixpkg-engram";
        "org.opencontainers.image.version" = version;
        "org.opencontainers.image.revision" = revision;
      };
      User = "10001:10001";
      Entrypoint = [ "${engramCloud}/bin/engram" ];
      Cmd = [
        "cloud"
        "serve"
      ];
      Env = [
        "PATH=${pkgs.lib.makeBinPath [ engramCloud ]}"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "HOME=/data"
        "TMPDIR=/tmp"
        "TZ=UTC"
        "ENGRAM_CLOUD_HOST=0.0.0.0"
        "ENGRAM_PORT=7437"
      ];
      WorkingDir = "/data";
      Volumes = {
        "/data" = { };
      };
      ExposedPorts = {
        "7437/tcp" = { };
      };
    };
  };
in
{
  packages.engram-cloud = engramCloud;
  images.engram-cloud-image = image;
}
