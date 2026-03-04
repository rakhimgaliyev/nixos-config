{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Required in initrd so the encrypted root on NVMe is visible before LUKS unlock.
  boot.initrd.availableKernelModules = [ "nvme" "vmd" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/e3b2fa81-c22a-45b1-8747-361a3bb76224";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/315f31c5-b592-4a4b-8d53-4c2026150f36";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/315f31c5-b592-4a4b-8d53-4c2026150f36";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/315f31c5-b592-4a4b-8d53-4c2026150f36";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/315f31c5-b592-4a4b-8d53-4c2026150f36";
    fsType = "btrfs";
    options = [ "subvol=@persist" "compress=zstd" "noatime" ];
  };

  fileSystems."/.snapshots" = {
    device = "/dev/disk/by-uuid/315f31c5-b592-4a4b-8d53-4c2026150f36";
    fsType = "btrfs";
    options = [ "subvol=@snapshots" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/EB62-015D";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  swapDevices = [
    { device = "/swap/swapfile"; }
  ];
}
