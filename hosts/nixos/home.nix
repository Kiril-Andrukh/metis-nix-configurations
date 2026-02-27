{ config, pkgs, lib, metis, ... }:

{
  home.username = "nixos";
  home.homeDirectory = "/home/nixos";

  home.stateVersion = "25.11";

  
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  home.packages = with pkgs; [
    vscode
    python312
  ];

  home.activation = {
    cloneMetis = lib.hm.dag.entryAfter ["writeBoundary"] ''
      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh"
      if [ ! -d "$HOME/metis" ] || [ -L "$HOME/metis" ]; then
        rm -rf "$HOME/metis"
        ${pkgs.git}/bin/git clone git@github.com:MIT-Systems-Integration-Development/metis.git "$HOME/metis"
      fi
    '';

    # setupMetis = lib.hm.dag.entryAfter ["cloneMetis"] ''
    #   if [ ! -d "$HOME/metis/venv" ]; then
    #     ${pkgs.python312}/bin/python -m venv "$HOME/metis/venv"
    #     "$HOME/metis/venv/bin/pip" install poetry
    #   fi
    #   cd "$HOME/metis" && "$HOME/metis/venv/bin/poetry" install
    # '';
  };

  programs = {
    home-manager.enable = true; 
    vscode.enable = true;
  };
}
