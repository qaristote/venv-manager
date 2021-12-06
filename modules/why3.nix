{ pkgs, lib, ... }:

with lib;
let
  cfg = config.why3;
  proverSubmodule = types.submodule {
    options = {
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The name of the prover.
        '';
      };
      package = mkOption {
        type = types.package;
        description = ''
          The package providing the prover.
        '';
      };
    };
  };
  why3BuildInputs = [ cfg.package ] ++ cfg.provers.detect
    ++ (mapAttrsToList (_: prover: prover.package) cfg.provers.manual);
in {
  options.why3 = {
    enable = mkEnableOption "why3";
    package = mkOption {
      type = types.package;
      default = pkgs.why3;
      defaultText = literalExample "pkgs.why3";
      description = ''
        The package for why3. This sets the version of Why3.
      '';
    };
    provers = {
      detect = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = ''
          Provers to use that are known to be supported by Why3.
        '';
        example = literalExample "with pkgs; [ z3 ccv4 ]";
      };
      manual = mkOption {
        type = types.attrsOf proverSubmodule;
        default = { };
        description = ''
          Provers to use that are not known to be supported by Why3.
        '';
        example = literalExample ''
          {
            myProver = {
              package = pkgs.my-prover;
            };
          }
        '';
      };
    };
  };

  config.why3 = mkIf cfg.enable { buildInputs = why3BuildInputs; };
}
