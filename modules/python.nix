{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.python;
  pythonWithPackages = (cfg.python.withPackages cfg.packages).override {
    ignoreCollisions = cfg.ignoreCollisions;
  };
in {
  options.python = {
    enable = mkEnableOption { name = "python"; };

    python = mkOption {
      type = types.package;
      default = pkgs.python3;
      defaultText = literalExample "pkgs.python3Minimal";
      description = ''
        The package providing python.
        Use this option to set the version of Python.
      '';
      example = literalExample "pkgs.python310";
    };

    packages = mkOption {
      type = with types; functionTo (listOf package);
      default = _: [ ];
      defaultText = literalExample "_: []";
      description = ''
        Python packages that will be made available to the environment.
      '';
      example = literalExample ''
        pythonPackages: with pythonPackages; [
             requests (callPackage ./my-package.nix {})
        ];
      '';
    };

    ignoreCollisions = mkEnableOption "ignoring collisions when building the Python environnement";
  };

  config = mkIf cfg.enable {
    buildInputs = [ pythonWithPackages ];
    # shellHook = ''
    #   # Tells pip to put packages into $PIP_PREFIX instead of the usual locations.
    #   # See https://pip.pypa.io/en/stable/user_guide/#environment-variables.
    #   export PIP_PREFIX=$(pwd)/_build/pip_packages
    #   export PYTHONPATH="$PIP_PREFIX/${cfg.python.sitePackages}:$PYTHONPATH"
    #   export PATH="$PIP_PREFIX/bin:$PATH"
    #   unset SOURCE_DATE_EPOCH
    # '';
  };
}
