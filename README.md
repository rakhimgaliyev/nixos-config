# pc install notes

Use the installer script. Manual partition/LUKS/mount commands are no longer the main path.

## Requirements
- Boot NixOS installer in UEFI mode.
- Copy this repo locally (for example to `/tmp/nixos-confg`).
- Run commands as `root` (`sudo -i`).

## Install (recommended)
From repo root:

```bash
sudo ./scripts/install-from-live.sh
```

With explicit options:

```bash
sudo DISK=/dev/nvme0n1 HOST=pc SWAP_GB=40 ./scripts/install-from-live.sh
```

## What the script does
- Shows available disks and asks for multiple confirmations.
- Wipes target disk and creates GPT: EFI + LUKS partition.
- Creates LUKS2, Btrfs, subvolumes (`@`, `@home`, `@nix`, `@persist`, `@snapshots`).
- Creates swapfile (default `40G`, Btrfs-safe).
- Generates `hardware-configuration.nix` and copies it to `hosts/<HOST>/hardware-configuration.nix`.
- Runs `nixos-install --flake <repo>#<HOST>`.

## Optional: find GPU bus IDs
```bash
lspci -nnk | grep -E -A2 "VGA|3D"
```

## Steam / Dota
In Steam launch options for Dota, use:

```bash
gamemoderun %command%
```
