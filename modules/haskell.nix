{ config, lib, pkgs, ... }:

with lib;
with builtins;
let
  cfg = config.haskell;

  spacemacsPackages = haskellPackages:
    with haskellPackages; [
      apply-refact
      hindent
      hlint
      stylish-haskell
      hasktags
    ];
  haskellBuildInput = (if cfg.hoogle.enable then
    cfg.haskellPackages.ghcWithHoogle
  else
    cfg.haskellPackages.ghcWithPackages) (haskellPackages:
      (cfg.packages haskellPackages)
      ++ optionals cfg.spacemacs.enable (spacemacsPackages haskellPackages)
      ++ optional cfg.cabal.enable pkgs.cabal-install);
in {
  options.haskell = {
    enable = mkEnableOption { name = "haskell"; };
    haskellPackages = mkOption {
      type = with types;
        addCheck (lazyAttrsOf anything)
        (packages: lib.hasAttr "ghcWithPackages" packages);
      default = pkgs.haskellPackages;
      defaultText = literalExample "pkgs.haskellPackages";
      description = ''
        The set of Haskell packages from which to get GHC and its packages.
        Use this option to set the version of GHC.
      '';
      example = literalExample "pkgs.haskell.packages.ghcjs";
    };
    packages = mkOption {
      type = with types; functionTo (listOf package);
      default = _: [ ];
      defaultText = literalExample "_ : []";
      description = ''
        Haskell packages that will be made available to the environment.
      '';
      example = literalExample ''
        haskellPackages: with haskellPackages; [ async cabal-install ];
      '';
    };
    # Whether to load packages required by Spacemacs layer.
    spacemacs.enable = mkEnableOption "spacemacs";

    hoogle.enable = mkEnableOption "hoogle";

    cabal = {
      enable = mkEnableOption "cabal";
      package = mkOption {
        type = types.package;
        default = pkgs.cabal-install;
        defaultText = defaultText "pkgs.cabal-install";
        description = "The package for cabal.";
      };
      # TODO: add ability to set path to binaries
      # TODO: explain that here cabal is not loaded with ghc, but as an external package
    };
  };

  config = mkIf cfg.enable {
    buildInputs = [ haskellBuildInput ];
    envVars.PATH.value = mkIf cfg.cabal.enable "~/.cabal/bin"; # only on linux
  };
}
