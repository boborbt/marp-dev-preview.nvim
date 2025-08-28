{
  description = "A flake for developing a neovim plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        neovim = pkgs.neovim;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            neovim
            luajit
            luarocks
            stylua
          ];

          shellHook = ''
            export XDG_CONFIG_HOME=$(pwd)/.config
	    export PATH=$PATH:$HOME/.luarocks/bin
            echo "Nix dev shell configured to use local nvim config"
          '';
        };
      }
    );
}
