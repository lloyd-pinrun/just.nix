/*
A module to import into flakes based on `flake-parts`
Makes integration into a flake more tidy :)
See: https://flake.parts
*/
{inputs, ...}: let
  inherit (inputs.flake-parts.lib) mkPerSystemOption;
in {
  options = {
    perSystem = mkPerSystemOption ({
      config,
      lib,
      options,
      pkgs,
      ...
    }: let
      inherit (config) just;

      inherit
        (builtins)
        attrNames
        attrValues
        getAttr
        hasAttr
        ;

      inherit
        (lib)
        concatStringsSep
        getExe
        literalExpression
        mkEnableOption
        mkIf
        mkOption
        mkPackageOption
        pipe
        setAttrByPath
        toList
        types
        ;

      inherit
        (pkgs)
        mkShell
        writeText
        ;
    in {
      options = {
        just = {
          enable = mkEnableOption "just command runner";

          defaultRecipe = mkOption {
            type = types.enum (attrNames just.recipes);
            default = "list";
            example = literalExpression ''
              "check *ARGS"
            '';
            description = ''
              The recipe that should be ran by default when using just.
            '';
          };

          recipes = mkOption {
            type = types.lazyAttrsOf (
              types.coercedTo types.str (setAttrByPath ["command"])
              (types.submodule ({
                config,
                name,
                ...
              }: {
                options = {
                  command = mkOption {
                    type = types.str;
                    example = literalExpression ''
                      "pre-commit run {{ ARGS }}"
                    '';
                    description = ''
                      The command to run as part of this recipe.
                    '';
                  };

                  recipe = mkOption {
                    type = types.str;
                    readOnly = true;
                    default = ''
                      ${name}:
                        ${config.command}
                    '';
                    description = ''
                      The justfile recipe generated from this configuration.
                      It will consist of the recipe's name and the command configured for the recipe.
                    '';
                  };
                };
              }))
            );
            default = {};
            description = ''
              The recipes to be included in the generated justfile.
            '';
          };

          package = mkPackageOption pkgs "just" {};

          finalPackage = mkOption {
            type = types.package;
            readOnly = true;
            description = "Final just package";
          };

          devShell = mkOption {
            type = types.package;
            readOnly = true;
            description = "The devShell which includes the just executable.";
          };

          justfile = mkOption {
            type = types.package;
            readOnly = true;
            default = pipe just.recipes [
              (
                recipes:
                  toList (recipes.${just.defaultRecipe} or [])
                  ++ attrValues (removeAttrs recipes [just.defaultRecipe])
              )
              (map (getAttr "recipe"))
              (concatStringsSep "\n")
              (writeText "justfile")
            ];
          };
        };
      };

      config = mkIf just.enable {
        just = {
          recipes."list" = "@just --list";

          finalPackage =
            if hasAttr "override" just.package
            then
              just.package.overrideAttrs (attrs: {
                nativeBuildInputs =
                  (attrs.nativeBuildInputs or [])
                  ++ [pkgs.makeWrapper];

                postInstall =
                  (attrs.postInstall or "")
                  + ''
                    wrapProgram $out/bin/just --add-flags "--justfile ${just.justfile}"
                  '';
              })
            else just.package;

          devShell = mkShell {
            packages = [just.finalPackage pkgs.git];
            shellHook = ''
              export JUST_WORKING_DIRECTORY="$(${getExe pkgs.git} rev-parse --show-toplevel)"
            '';
          };
        };
      };
    });
  };
}
