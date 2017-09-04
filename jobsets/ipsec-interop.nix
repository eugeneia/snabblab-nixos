# Build Snabb, Snabb manual and run tests for given Snabb branch

{ pkgs ? (import <nixpkgs> {})
# which Snabb source directory is used for testing
, snabbSrc ? (builtins.fetchTarball https://github.com/snabbco/snabb/tarball/next)
# what hardware group is used when executing the jobs
, hardware ? "lugano"
}:

let
  local_lib = import ../lib { inherit pkgs; };
in rec {
  snabb = import "${snabbSrc}" {};
  tests = local_lib.mkSnabbTest {
    name = "ipsec-interop-tests";
    inherit hardware snabb;
    needsNixTestEnv = true;
    checkPhase = ''
      # run tests
      cd src && sudo -E apps/ipsec/selftest.sh

      # keep the logs
      #cp src/testlog/* $out/
      cp qemu*.log $out/
    '';
  };
}
