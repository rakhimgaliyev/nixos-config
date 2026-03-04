#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   sudo ./scripts/install-from-live.sh
# Optional env:
#   DISK=/dev/nvme0n1 HOST=pc SWAP_GB=40 ./scripts/install-from-live.sh

DISK="${DISK:-/dev/nvme0n1}"
HOST="${HOST:-pc}"
SWAP_GB="${SWAP_GB:-40}"
MNT="/mnt"
PART_SEP=""

if [[ "${DISK}" =~ (nvme|mmcblk) ]]; then
  PART_SEP="p"
fi
EFI_PART="${DISK}${PART_SEP}1"
CRYPT_PART="${DISK}${PART_SEP}2"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
HOST_DIR="${REPO_ROOT}/hosts/${HOST}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

if [[ ! -d /sys/firmware/efi ]]; then
  echo "UEFI mode is required. Reboot installer in UEFI mode."
  exit 1
fi

if [[ ! -b "${DISK}" ]]; then
  echo "Disk not found: ${DISK}"
  exit 1
fi

if [[ ! -f "${REPO_ROOT}/flake.nix" ]]; then
  echo "flake.nix not found in repo root: ${REPO_ROOT}"
  exit 1
fi

if [[ ! -d "${HOST_DIR}" ]]; then
  echo "Host dir not found: ${HOST_DIR}"
  exit 1
fi

confirm_yes_no() {
  local prompt="$1"
  local reply
  read -r -p "${prompt} [y/N]: " reply
  [[ "${reply}" =~ ^[Yy]$ ]]
}

require_exact_input() {
  local prompt="$1"
  local expected="$2"
  local reply
  read -r -p "${prompt}: " reply
  [[ "${reply}" == "${expected}" ]]
}

echo "Detected disks:"
lsblk -d -o NAME,SIZE,MODEL
echo
echo "About to ERASE disk: ${DISK}"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS "${DISK}" || true
echo "Repo root: ${REPO_ROOT}"
echo "Host: ${HOST}"
echo "Swapfile: ${SWAP_GB}G"
if ! confirm_yes_no "Continue with this disk"; then
  echo "Cancelled."
  exit 1
fi
if ! require_exact_input "Type exact disk path to confirm" "${DISK}"; then
  echo "Disk path mismatch. Cancelled."
  exit 1
fi
if ! require_exact_input "Final confirmation, type ERASE" "ERASE"; then
  echo "Cancelled."
  exit 1
fi

echo "[1/7] Cleaning previous mounts/maps..."
swapoff -a || true
umount -R "${MNT}" 2>/dev/null || true
cryptsetup close cryptroot 2>/dev/null || true

echo "[2/7] Partitioning ${DISK} (GPT + EFI + cryptroot)..."
parted -s "${DISK}" mklabel gpt
parted -s "${DISK}" mkpart ESP fat32 1MiB 1025MiB
parted -s "${DISK}" set 1 esp on
parted -s "${DISK}" mkpart cryptroot 1025MiB 100%
partprobe "${DISK}"

echo "[3/7] Creating filesystems and LUKS..."
mkfs.fat -F 32 -n EFI "${EFI_PART}"
if ! confirm_yes_no "Run LUKS format on ${CRYPT_PART}"; then
  echo "Cancelled."
  exit 1
fi
echo "Set LUKS passphrase for ${CRYPT_PART}:"
cryptsetup luksFormat --type luks2 "${CRYPT_PART}"
cryptsetup open "${CRYPT_PART}" cryptroot
mkfs.btrfs -L nixos /dev/mapper/cryptroot

echo "[4/7] Creating and mounting Btrfs subvolumes..."
mount /dev/mapper/cryptroot "${MNT}"
btrfs subvolume create "${MNT}/@"
btrfs subvolume create "${MNT}/@home"
btrfs subvolume create "${MNT}/@nix"
btrfs subvolume create "${MNT}/@persist"
btrfs subvolume create "${MNT}/@snapshots"
umount "${MNT}"

mount -o subvol=@,compress=zstd,noatime /dev/mapper/cryptroot "${MNT}"
mkdir -p "${MNT}"/{boot,home,nix,persist,.snapshots,swap}
mount -o subvol=@home,compress=zstd,noatime /dev/mapper/cryptroot "${MNT}/home"
mount -o subvol=@nix,compress=zstd,noatime /dev/mapper/cryptroot "${MNT}/nix"
mount -o subvol=@persist,compress=zstd,noatime /dev/mapper/cryptroot "${MNT}/persist"
mount -o subvol=@snapshots,compress=zstd,noatime /dev/mapper/cryptroot "${MNT}/.snapshots"
mount "${EFI_PART}" "${MNT}/boot"

echo "[5/7] Creating swapfile (${SWAP_GB}G)..."
swapoff "${MNT}/swap/swapfile" 2>/dev/null || true
rm -f "${MNT}/swap/swapfile"
chattr +C "${MNT}/swap"
btrfs property set "${MNT}/swap" compression no 2>/dev/null || true
dd if=/dev/zero of="${MNT}/swap/swapfile" bs=1M count="$((SWAP_GB * 1024))" status=progress
chmod 600 "${MNT}/swap/swapfile"
mkswap "${MNT}/swap/swapfile"
swapon "${MNT}/swap/swapfile"

echo "[6/7] Generating hardware config..."
nixos-generate-config --root "${MNT}" || true
if [[ ! -f "${MNT}/etc/nixos/hardware-configuration.nix" ]]; then
  echo "hardware-configuration.nix was not generated."
  echo "Check mounts with: findmnt -R /mnt"
  exit 1
fi
cp "${MNT}/etc/nixos/hardware-configuration.nix" "${HOST_DIR}/hardware-configuration.nix"

echo "[7/7] Installing NixOS from local flake..."
echo "Mounts:"
findmnt -R "${MNT}" || true
echo "Swap:"
swapon --show || true
if ! confirm_yes_no "Proceed with nixos-install --flake ${REPO_ROOT}#${HOST}"; then
  echo "Cancelled before install."
  exit 1
fi
nixos-install --flake "${REPO_ROOT}#${HOST}"

echo "Install complete. You can reboot now."
