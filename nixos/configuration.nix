{ config, pkgs, ... }:

{
  imports = [
      ./audio.nix
      ./hardware-configuration.nix
      ./networking.nix
      ./packages.nix
      ./security.nix
      ./ssh.nix
      ./steam.nix
      ./systemd.nix
      ./users.nix
      ./x.nix
      ./zsh.nix
  ];

  # Use the gummiboot efi boot loader.
  boot = {
    supportedFilesystems = ["exfat" "btrfs" "ntfs" "vfat"];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  i18n = {
    # Use a bigger font for HiDPI displays
    consoleFont = "sun12x22";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  services.printing = {
    enable = true;
    drivers = [ pkgs.hplipWithPlugin ];
  };

  hardware.bluetooth.enable = true;
  nixpkgs.config.allowUnfree = true;
  #services.chrony.enable = true;
  time.timeZone = "USA/Los_Angeles";

  nix = {
    maxJobs = 4;
    buildCores = 4;
    gc.automatic = true;
    useSandbox = true;
    # Use a local clone of nixpkgs at /etc/nixpkgs
    #nixPath = [ "nixos-config=/etc/nixos/configuration.nix" "/home/siddharthist/code" ];
  };
}
