{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.latex;
  latexmkFlags = concatStringsSep " " ([
    (if cfg.latexmk.output.dvi.enable then "-dvi" else "-dvi-")
    (if cfg.latexmk.output.ps.enable then "-ps" else "-ps-")
    (if cfg.latexmk.output.pdf.enable then
      ("-pdf" + cfg.latexmk.output.pdf.method)
    else
      "-pdf-")
    (optionalString cfg.minted.enable "-shell-escape")
  ] ++ (map (filename: "-r ${filename}") cfg.latexmk.rc)
    ++ cfg.latexmk.extraFlags);
  latexBuildInput = cfg.texlive.combine ((cfg.packages cfg.texlive)
    // (optionalAttrs cfg.latexmk.enable { inherit (cfg.texlive) latexmk; })
    // (optionalAttrs cfg.minted.enable {
      inherit (cfg.texlive)
        minted catchfile etoolbox fancyvrb float framed fvextra ifplatform
        kvoptions lineno pdftexcmds upquote xcolor xstring;
    }));
in {
  options.latex = {
    enable = mkEnableOption { name = "LaTex"; };

    texlive = mkOption {
      type = types.attrs;
      default = pkgs.texlive;
      defaultText = literalExample "pkgs.texlive";
      description = ''
        The package providing LaTex.
        Use this option to set the version of LaTex.
      '';
    };

    packages = mkOption {
      type = with types; functionTo attrs;
      default = tl: { inherit (tl) scheme-basic; };
      defaultText = literalExample "tl: { inherit (tl) scheme-basic; }";
      description = ''
        Collection of packages that will be made available to the environment.
      '';
      example = literalExample ''
        tl: {
          inherit (tl) scheme-full calligra;
          my-package = { pkgs = [ (pkgs.callPackage ./my-package.nix {}) ]; };
        }
      '';
    };

    latexmk = {
      enable = mkEnableOption "latexmk";
      output = {
        dvi.enable = mkEnableOption "dvi output";
        pdf = {
          enable = mkEnableOption "pdf output";
          method = mkOption {
            type = types.enum [ "" "dvi" "lua" "ps" "xe" ];
            default = "lua";
            description = ''
              Method by which to generate the pdf.
            '';
          };
        };
        ps.enable = mkEnableOption "ps output";
      };
      rc = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = ''
          List of LaTeXmk rc files to load.
        '';
        example = literalExample "[ ~/.config/latexmkrc ]";
      };
      extraFlags = mkOption {
        # TODO vulnerable to shell injection
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Flags to pass to latexmk.
        '';
        example = [ "-shell-escape" "-M" ];
      };
    };

    minted = {
      enable = mkEnableOption "minted";
    };
  };

  config = mkIf cfg.enable {
    buildInputs = [ latexBuildInput ] ++ (optional cfg.latexmk.enable pkgs.ps);
    aliases.latexmk = mkIf cfg.latexmk.enable
      "${latexBuildInput}/bin/latexmk ${latexmkFlags} \\$@";
    python = mkIf cfg.minted.enable {
      enable = true;
      packages = ps: with ps; [ pygments ];
    };
  };
}
