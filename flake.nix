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

        marp-dev-preview-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "marp-dev-preview.nvim";
          version = "scm";
          src = ./.;
        };

        neovim = pkgs.neovim.override {
          configure = {
            packages.myPlugins = with pkgs.vimPlugins; {
              start = [
                plenary-nvim
              ];
            };
            customRC = ''
              set rtp+=.
            '';
          };
        };
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
            echo "Nix dev shell configured to use local nvim config"
          '';
        };

        packages.marp-dev-preview-nvim = marp-dev-preview-nvim;
      }
    );
}
