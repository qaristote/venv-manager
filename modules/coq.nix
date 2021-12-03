{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.coq;
  coqBuildInputs = (with cfg.coqPackages; [ coq ])
    ++ (cfg.packages cfg.coqPackages);
in {
  options.coq = {
    enable = mkEnableOption { name = "coq"; };
    coqPackages = mkOption {
      type = types.lazyAttrsOf types.package;
      default = pkgs.coqPackages;
      defaultText = literalExample "pkgs.coqPackages";
      description = ''
        The set of Coq packages from which to get Coq and its packages.
        Use this option to set the version of Coq.
      '';
    };
    packages = mkOption {
      type = with types; functionTo (listOf package);
      default = _: [ ];
      defaultText = literalExample "_: [ ]";
      description = ''
        Coq packages that will be made available to the environment.
      '';
      example = literalExample ''
        coqPackages: with coqPackages; [ autosubst ];
      '';
    };
  };
  config = mkIf cfg.enable {
    buildInputs = coqBuildInputs;
  };
}
