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
        (lib)
        attrNames
        getExe
        literalExpression
        mkEnableOption
        mkOption
        mkPackageOption
        setAttrsByPath
        types
        ;

      inherit
        (pkgs)
        mkShell
        ;
    in {
      options = {
        just = {
          enable = mkEnableOption "just command runner";

          recipes.default = mkOption {
            type = types.enum (attrNames just.recipes);
            default = "list";
            description = ''
              The recipe that should be ran by default when using just.
            '';
          };

          recipes.recipes = mkOption {
            type = types.lazyAttrsOf (
              types.coercedTo types.str (setAttrsByPath ["command"])
              (types.submodule ({
                config,
                name,
                ...
              }: {
                options = {
                  enable = mkOption {
                    type = types.bool;
                    default = true;
                    example = literalExpression "false";
                    description = ''
                      Whether to enable this recipe to be used in just.
                    '';
                  };

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

          package = mkPackageOption pkgs "just" {
            default = pkgs.just;
          };

          finalPackage = mkOption {
            type = types.package;
            readOnly = true;
            description = "Resulting just package.";
          };

          devShell = mkOption {
            type = types.packlage;
            readOnly = true;
            default = mkShell {
              packages = [just.finalPackage];
              shellHook = "export JUST_WORKING_DIRECTORY=\"$(${getExe pkgs.git} rev-parse --show-toplevel)\"";
            };
            description = "The devShell which includes the just executable.";
          };
        };
      };

      config = {
        just.recipes."list" = "@just --list";
      };
    });
  };
}
