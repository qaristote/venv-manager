{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.coq;
  # coqBuildInputs = (with cfg.coqPackages; [ coq ])
  #   ++ (cfg.packages cfg.coqPackages);
  coqBuildInputs = [ cfg.coq ]
    ++ (map (package: package.override { coq = cfg.coq; })
      (cfg.packages pkgs.coqPackages));
  coqrc = pkgs.writeText "coqrc" cfg.rc;
  coqFlags = concatStringsSep " " ([ "-init-file ${coqrc}" ]);
in {
  options.coq = {
    enable = mkEnableOption { name = "coq"; };
    coq = mkOption {
      type = types.package;
      default = pkgs.coq;
      defaultText = literalExample "pkgs.coq";
      description = ''
        The package providing Coq. Use this option to set the version of Coq.
      '';
    };
    # coqPackages = mkOption {
    #   type = types.lazyAttrsOf types.package;
    #   default = pkgs.coqPackages;
    #   defaultText = literalExample "pkgs.coqPackages";
    #   description = ''
    #     The set of Coq packages from which to get Coq and its packages.
    #     Use this option to set the version of Coq.
    #   '';
    # };
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
    rc = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands to be prepended to any document read by Coq.
      '';
      example = ''
        Add Rec LoadPath "../my-module/" as MyModule.
      '';
    };

    # This option isn't available yet as disabling buildIde is actually heavier
    # on the user (the version without IDE is not cached by Hydra).
    # ide.enable = mkEnableOption "IDE";
  };
  config = mkIf cfg.enable {
    buildInputs = coqBuildInputs;
    aliases = {
      coqc = "${cfg.coq}/bin/coqc ${coqFlags} \\$@";
      coqide = "${cfg.coq}/bin/coqide ${coqFlags} \\$@";
      coqtop = "${cfg.coq}/bin/coqtop ${coqFlags} \\$@";
    };
  };
}
