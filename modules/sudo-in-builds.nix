{ config, lib, ... }:

# allows sudo in builders via /run/wrappers/bin/sudo
# has to be available on all servers for builds to always have those paths available inside chroot
{
  nix.useSandbox = false;
  nix.extraOptions = ''
    allow-new-privileges = true
  '';

  security.sudo.extraConfig = lib.concatMapStringsSep "\n" (i: "nixbld${toString i} ALL=(ALL) NOPASSWD:ALL") (lib.range 1 config.nix.nrBuildUsers);
}
