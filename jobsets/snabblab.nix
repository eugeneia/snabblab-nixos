{nixpkgs ? <nixpkgs>}:

let
  stdenv = (import nixpkgs {}).stdenv;
  mkChannel = { name, src, constituents ? [], meta ? {}, ... }@args:
  stdenv.mkDerivation ({
    inherit name src constituents;
    preferLocalBuild = true;
    _hydraAggregate = true;

    phases = [ "unpackPhase" "patchPhase" "installPhase" ];
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
  src = stdenv.mkDerivation {
      name = "snabblab-alpha";
      nixpkgsVersion = "alpha";
      src = ./../.;
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        cp -r --no-preserve=ownership "${nixpkgs}/" nixpkgs
        chmod -R u+w nixpkgs
        echo -n "$nixpkgsVersion" > nixpkgs/.version-suffix
        echo "echo '$nixpkgsVersion'" \
          > nixpkgs/nixos/modules/installer/tools/get-version-suffix
        echo -n "a" > nixpkgs/.git-revision
        echo './nixpkgs' > nixpkgs-path.nix
        cp -r . "$out"
      '';
    }; 
   eval = import "${nixpkgs}/nixos/lib/eval-config.nix" {
    modules = [ (import ./../machines/eiger.nix).build1 ];
  };
in {
  machines = { 
    build-1 = mkChannel {
      name = "snabblab-machine-build-1"; 
      constituents = [eval.config.system.build.toplevel];
      inherit src;
      patchPhase = ''
        touch .update-on-nixos-rebuild
      '';
    };
  };
  inherit (import ./../pkgs {}) snabbpkgs;
}
