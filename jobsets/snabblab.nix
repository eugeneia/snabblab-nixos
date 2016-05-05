{ nixpkgs ? <nixpkgs> }:

let
  stdenv = (import nixpkgs {}).stdenv;
  mkChannel = { name, src, constituents ? [], meta ? {}, isNixOS ? true, ... }@args:
    stdenv.mkDerivation ({
      inherit name src constituents;
      preferLocalBuild = true;
      _hydraAggregate = true;

      phases = [ "unpackPhase" "patchPhase" "installPhase" ];
  
      patchPhase = stdenv.lib.optionalString isNixOS ''
        touch .update-on-nixos-rebuild
      '';

      installPhase = ''
        mkdir -p "$out/tarballs" "$out/nix-support"
        tar cJf "$out/tarballs/nixexprs.tar.xz" \
          --owner=0 --group=0 --mtime="1970-01-01 00:00:00 UTC" \
          --transform='s!^\.!${name}!' .
        echo "channel - $out/tarballs/nixexprs.tar.xz" \
          > "$out/nix-support/hydra-build-products"
        echo $constituents > "$out/nix-support/hydra-aggregate-constituents"
        for i in $constituents; do
          if [ -e "$i/nix-support/failed" ]; then
      touch "$out/nix-support/failed"
          fi
        done
      '';

      meta = meta // {
        isHydraChannel = true;
      };
    } // removeAttrs args [ "name" "channelName" "src" "constituents" "meta" ]);
  mkChannelWithNixpkgs = { ... }@args:
    let
      src = stdenv.mkDerivation {
        name = args.name + "-with-nixpkgs";
        nixpkgsVersion = "TODO";
        src = args.src;
        phases = [ "unpackPhase" "installPhase" ];
        installPhase = ''
          cp -r --no-preserve=ownership "${nixpkgs}/" nixpkgs
          chmod -R u+w nixpkgs
          echo "echo '$nixpkgsVersion'" \
            > nixpkgs/nixos/modules/installer/tools/get-version-suffix
          echo -n "$nixpkgsVersion" > nixpkgs/.version-suffix
          echo -n "a" > nixpkgs/.git-revision
          echo './nixpkgs' > nixpkgs-path.nix
          cp -r . "$out"
        '';
      }; 
    in mkChannel (args // { inherit src; });
  evalMachine = name: (import "${nixpkgs}/nixos/lib/eval-config.nix" {
    modules = [ (import ./../machines/eiger.nix)."${name}" ];
  }).config.system.build.toplevel;
in {
  machines = stdenv.lib.genAttrs ["build1" "build2" "build3" "build4"]
    (name: mkChannelWithNixpkgs {
      name = "snabblab-machine-${name}";
      constituents = [ (evalMachine name) ];
      src = ./../.;
    });

  # build all our custom packages
  inherit (import ./../pkgs {}) snabbpkgs;
}
