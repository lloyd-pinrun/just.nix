{
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      name = "just.nix development shell";
      packages = with pkgs; [alejandra deadnix nixd statix];
      shellHook = ''
        ${config.pre-commit.installationScript}
        echo 1>&2 "$(id -un) | $(nix eval --raw --impure --expr 'builtins.currentSystem') | $(uname -r) "
      '';
    };

    pre-commit = {
      check.enable = false;

      settings = {
        default_stages = ["manual" "pre-push"];
        hooks = {
          end-of-file-fixer.enable = true;
          trim-trailing-whitespace.enable = true;

          # -- Git --
          commitizen.enable = true;
          no-commit-to-branch.enable = false;
          no-commit-to-branch.settings.branch = ["main"];

          # -- Misc --
          markdownlint.enable = true;
          mdsh.enable = true;
          typos.enable = true;

          # -- Nix --
          alejandra.enable = true;
          deadnix.enable = true;
          deadnix.settings.edit = true;
          statix.enable = true;
        };
      };
    };
  };
}
