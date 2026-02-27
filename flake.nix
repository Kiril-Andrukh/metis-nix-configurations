{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    metis = {
      url = "git+ssh://git@github.com/MIT-Systems-Integration-Development/metis?ref=main";
      flake = false;
    };

    sops-nix.url = "github:mic92/sops-nix";
  };

  outputs = { self, nixpkgs, home-manager, metis, ... }@inputs:
    let
      pkgs = import nixpkgs { 
        system = "x86_64-linux"; 
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        }; 
      };
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [ pkgs.python3 ];
        env.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
          pkgs.stdenv.cc.cc.lib
          pkgs.zlib
        ];
      };

      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs metis; };
          modules = [
            ./hosts/nixos/configuration.nix
          ];
        };
      };
    };
}
