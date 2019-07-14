# Spec
{
  snabbvirtbot = { config, pkgs, lib, ... }: {
    # custom NixOS options here

    # Disable IOMMU for Snabb Switch.
    boot.kernelParams = [ "intel_iommu=off" "hugepages=4096" "panic=60"];

    # Used by snabb
    boot.kernelModules = [ "msr" "kvm-intel" ];

    # Luke: it's a PITA for benchmarking because it introduces variation that's hard to control
    # The annoying thing is that Turbo Boost will unpredictably increase the clock speed
    # above its normal value based on stuff like how many cores are in use or temperature of the data center or ...
    boot.postBootCommands = ''
      echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
      echo 2 > /sys/devices/cpu/rdpmc
    '';

    # mount /hugetlbfs for snabbnfv
    systemd.mounts = [
      { where = "/hugetlbfs";
        enable  = true;
        what  = "hugetlbfs";
        type  = "hugetlbfs";
        options = "pagesize=2M";
        requiredBy  = ["basic.target"];
      }
    ];

    # Docker support
    virtualisation.docker.enable = true;
    virtualisation.docker.storageDriver = "devicemapper";
    # https://github.com/NixOS/nixpkgs/issues/11478
    virtualisation.docker.socketActivation = true; # old

    environment.sessionVariables.SSL_CERT_FILE =
    "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

    imports = [
      ./../modules/snabb_bot.nix
      ./../modules/snabb_doc.nix
    ];
    services.snabb_bot.environment =
    ''
      export SNABB_TEST_IMAGE=eugeneia/snabb-nfv-test-vanilla
    '';
    services.snabb_bot.credentials = "snabbbot:hangelar2014";
    services.snabb_doc.credentials = "snabbbot:hangelar2014";

  };
}

