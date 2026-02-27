# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, metis, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  virtualisation.docker.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  networking = {
    hostName = "nixos";
    firewall.allowedTCPPorts = [ 22 8000 ];
    networkmanager.enable = true;
  };

  systemd.services.preload-docker-images = {
    description = "Preload Docker images";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.docker ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if ! ${pkgs.docker}/bin/docker image inspect mcr.microsoft.com/mssql/server:2025-latest > /dev/null 2>&1; then
        ${pkgs.docker}/bin/docker load -i ${pkgs.dockerTools.pullImage {
          imageName = "mcr.microsoft.com/mssql/server";
          imageDigest = "sha256:5ffdffd2ba852051c2fc2f5b310391bf896dbaf8d16cc026a3c859d6214b30d1";
          hash = "sha256-rt6VqQCG4xiY+6Ht7v3rrIq4M3UOxhvcySsLcIezJIE=";
          finalImageName = "mcr.microsoft.com/mssql/server";
          finalImageTag = "2025-latest";
        }}
      fi
    '';
  };
  

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  time.timeZone = "Europe/Warsaw";

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    initialPassword = "nixos";
    packages = with pkgs; [
      tree
    ];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs metis; };
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      "nixos" = import ./home.nix;
    };
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      curl
      libGL
      glib
      libx11
      libxext
      libxcursor
      libxrandr
      libxi
      libxrender
      libxtst
      libxscrnsaver
      libxcomposite
      libxdamage
      libxfixes
      alsa-lib
      libdrm
      expat
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git 
    gh
    unixODBC
    unixODBCDrivers.msodbcsql18
    docker
    skopeo
    sops
    age
  ];

  environment.etc."odbcinst.ini".text = ''
    [ODBC Driver 18 for SQL Server]
    Description=Microsoft ODBC Driver 18 for SQL Server
    Driver=${pkgs.unixODBCDrivers.msodbcsql18}/lib/libmsodbcsql-18.1.so.1.1
  '';

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/root/.config/sops/age/keys.txt";
    secrets.ssh_private_key = {
      path = "/root/.ssh/id_ed25519";
      mode = "0600";
    };
  };

  system.stateVersion = "25.11";

}

