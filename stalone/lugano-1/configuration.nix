# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/sda" ];

  # pci=realloc is needed for SR-IOV to work. intel_iommu is NOT disabled
  # because it is needed for SR-IOV (i.e. using the i40e driver that let’s us
  # test with Intel AVF VFs.)
  boot.kernelParams = [ "hugepages=4096" "panic=60" "pci=realloc"];
  boot.kernelModules = [ "msr" ];
  boot.postBootCommands = ''
    echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
    echo 2 > /sys/devices/cpu/rdpmc
  '';

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gcc glibc binutils git gnumake wget nmap screen tmux pciutils tcpdump curl
    strace htop file cpulimit numactl psmisc linuxPackages.perf nox nixops lsof
    ipmitool ncdu psmisc lshw
    # manpages
    manpages
    posix_man_pages
  ];
    
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "16.03"; # Did you read the comment?

  networking = {
    hostName = "lugano-1";
    defaultGateway = "195.176.0.209";
    interfaces.eno1 = {
    ipAddress = "195.176.0.211";
      prefixLength = 28;
    };
    localCommands = ''
      ip -6 addr add '2001:620:20b0:1:225:90ff:fefc:6d00/64' dev 'eno1' || true
    '';
    nameservers = [
      "8.8.8.8"
    ];
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = "without-password";
    ports = [22 4040 4041];
  };

  security.sudo.wheelNeedsPassword = false;

  users.extraUsers.luke = {
    isNormalUser = true;
    uid = 1000;
    description = "Luke Gorrie";
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCcsvXQs8U1TYZyGYLusQpOtBvmyvsa0wqxIUXrnmqIHY9HX5D0SYYra7Vy0b8SjNsvV9ywZZRi4b1BnKNG6Gxe+JMC9+mokBCYTo68gclfYAWS+x0DzO7KEPh9PeFUrYuUYekRaK42j923LBBMIQOwtPDhFzgRoYXZEaBCtUyCHrUi98b0CWL1uu0C7QfAoXLXY5l2pndT1tyxZnYg0rlohuhCDsniZZ+Em2mV0235lJ8l7UbvV3fASoAW4qEs3jkvBXwpDGKBJEoev6trM12FC4ZSiKcH7LBLxz2G5KCfRht46cXtp379xRBfAVI5z2WCegIGtRhNto591BRIBCmj" ];
    extraGroups = [ "wheel" "libvirtd" ];
  };
  users.extraUsers.max = {
    isNormalUser = true;
    uid = 1012;
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQC/zwFEk3x5wI0hZAr91DIWRL0YlWwBgJ0XoFJE0aRnblQ842Cg7cKAgNVnRhgBd8Wz1xGxAOOE0uTGuUs+2wP9/XAL82pjOg9gPqL2B55NnihK4MDykAzGrTZQlUoaVH4ukmiSyaw3W83BnLjg/lQue/71DYhmmWYYj5W1RNLsQMHW/7Ddp/3vJv+Ltffct01eQvzG809/PLz7hCTNFauWTLEWB6hPXBpVR8gMRlOaDzEoGo0/lTKPZNwbPTIGrdRWWhOXfF+JBEl20lS8MVFcC66aHQoIPEg4ADJtyNJMYB1lFH4Pm+fgeaU+j6d621ju45EWOgLwSw49EjaITKnnrrOv/B+lCeIbFEi9J+Whr77KU1PsVqSkfbqStoWOWIlQJmyhuq3FDUZaYj7LSDjbSxJhmqd+SODLz1wJ1/dP2mCdErI4QyXfbV4f6AIdDYXQ4s7R3XJ2yn4rdXFDnYhJgbQ/IZIqMpg1NGjeNBJfahzzMSZTItCMb1kyY6dCMruQiEr1RRlQkIQurYVkq5NrBg2DHbmA5ZmZvd41h58o34tEsCe9cTaUdmYoiA1PHCtsl4LaEOvsjzqr7mTdfT1Le0v1//4k65XpRf9peNxtyTs1c899i2iq7WLTdrssuPo/AOrB3dm3hcUIwqO/toHAN/vKHht4242UypDLJXEcXLQmafCEiI1xW9Q9ZbDTYCksJ20WzVW5LCe0CyXMyB/0AuRvnaTDbUANH+J7JKh5zuhtjBcmYzTFt8QkJjj4yRTTMlSxC6T2JvJxaSf25kJ7eHzt+zPiQ1QN7jECPpi5jpxIcy4GQk7AfbDW5DMI1SM250Kao6BLBZ5cI5fFIufMMmLdHLaWgC9tF/A5p0c+etvXMQFkdZ05FE+aHqVrabArHIAIiNfzKKDaGyTPh9X4s0f4lWeYhu0vlEU69JW05tYm+HP+1j1lARKwKlbQ509sxP4126irMtV6ksO/3IrryKlTFMaKax10fJwvfRwQkNjuYvd5I2CWN7oGinjggAO757nI6gK+D0WfilAPguS21CFq+9hyA2THs5KXfXap2dsqFmJCiu78KslcDmCTG0PwenBii2SrYuzddJnGjTk0HMZc26nj02XgoQhlaVOvjQYzx+8PPg5V6qwjcOhKRp4/7wwFWqt1twj4O3SBd1PhTFrY+SFfSaGNTqaeWiaLkQ1nN5UsNNTonLPiCj8gwsJKg5MwwOlFcPxyIjdXayQ3dRBiyyW8sRPHx/vyK0Xt3uH3dTBMt+oxTOlxj6s0jWIJ6zbsBiyATsvf8HwNeX1KU2NSrgUj+oarmuYKa+PX2+N0EKF9u0v9iN99LH/1/v4ilpSwwugZnWXwXdJeXjqn eugeneia" ];
    extraGroups = [ "wheel" "libvirtd" ];
  };

}
