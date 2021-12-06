{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.why3;
  why3BuildInputs = [ cfg.package ] ++ cfg.provers;
  why3Conf = pkgs.runCommand "why3.conf" { buildInputs = why3BuildInputs; }
    ''
    why3 -C $out config detect
    echo "${cfg.extraConfig}" >> $out
    '';
  why3Flags = concatStringsSep " " [ "--extra-config ${why3Conf}" ];
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
    provers = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        A list of packages that should be detected as provers by Why3 and
        added as build inputs.
      '';
      example = literalExample "with pkgs; [ z3 ccv4 ]";
    };
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra configuration entries for Why3.
      '';
    };
  };

  config = mkIf cfg.enable {
    buildInputs = why3BuildInputs;
    aliases = { why3 = "${cfg.package}/bin/why3 ${why3Flags} \\$@"; };
  };
}
