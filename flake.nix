{
  description = "NixOS desktop (Hyprland + Nvidia hybrid)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wallpaper-runner = {
      url = "github:rakhimgaliyev/wallpaper-runner";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, wallpaper-runner }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.pc = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {
            nixpkgs.overlays = [
              (_: prev: {
                wallpaper-runner = wallpaper-runner.packages.${system}.default;
              })
            ];
          }
          ./hosts/pc/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.user = import ./home/user.nix;
          }
        ];
      };
    };
}
