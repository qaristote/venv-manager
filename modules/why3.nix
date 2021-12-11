{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.why3;
  why3BuildInputs = [ cfg.package ] ++ cfg.provers
    ++ (optional config.coq.enable config.coq.coqPackages.coq);
  why3Conf = pkgs.runCommand "why3.conf" { buildInputs = why3BuildInputs; } (''
    why3 --config=$out config detect
  '' + (optionalString (cfg.defaultEditor != null) ''
    sed -i 's/^default_editor = ".*"$/default_editor = "${cfg.defaultEditor} %f"/' $out
  '') + ''
    echo "" >> $out
    echo '${cfg.extraConfig}' >> $out
  '');
  why3Flags = concatStringsSep " " [ "--config=${why3Conf}" ];
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
        added as build inputs. Coq can be added independently using the
        coq option.
      '';
      example = literalExample "with pkgs; [ z3 ccv4 ]";
    };
    defaultEditor = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The default editor to launch provers with.
      '';
      example = "emacsclient -c";
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
    # buildInputs = [(cfg.package.withProvers cfg.provers)];
    aliases = { why3 = "${cfg.package}/bin/why3 ${why3Flags} \\$@"; };
    coq = {
      rc = ''
        Add Rec LoadPath "${cfg.package}/lib/why3/coq/" as Why3.
      '';
    };
  };
}
