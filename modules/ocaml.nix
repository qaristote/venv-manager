{ config, lib, pkgs, ... }:

with lib;
with builtins;
let
  cfg = config.ocaml;

  tuaregPackages = optionals cfg.tuareg.enable (with pkgs; [ ocamlformat opam ])
    ++ (with cfg.ocamlPackages; [ merlin ocp-indent utop ]);
  userPackages = cfg.packages cfg.ocamlPackages;
  ocamlBuildInputs = (with cfg.ocamlPackages; [ ocaml findlib ]) ++ (with pkgs;
    if versionAtLeast cfg.version "4.12" then
      [ dune_2 ]
    else
      (optional (versionAtLeast cfg.version "4.02") dune_1)) ++ tuaregPackages
    ++ userPackages;

  stdlibDir = "${cfg.ocamlPackages.findlib}/lib/ocaml/${cfg.version}/site-lib";
  parseOcamlDrvName = with builtins;
    pkg:
    head (match "ocaml${cfg.version}-(.*)" (parseDrvName pkg.name).name);
  ocamlInit = pkgs.writeText "ocamlinit" (
    # load libs
    (concatStringsSep "\n" (map (dir: ''
      let () = try Topdirs.dir_directory "${dir}"
               with Not_found -> ();;
    '') ([ stdlibDir ] ++ cfg.toplevel.libDirs))) + ''
      #use "topfind";;
    ''
    # enable threading
    + (optionalString cfg.toplevel.thread "#thread;;")
    # list packages
    + (optionalString cfg.toplevel.list "#list;;")
    # require packages
    + (concatStringsSep "\n"
      (map (pkg: ''# require "${parseOcamlDrvName pkg}";;'')
        userPackages))
    # additional init commands
    + cfg.toplevel.extraInit

  );

in {
  options.ocaml = {
    enable = mkEnableOption { name = "ocaml"; };
    version = mkOption {
      type = types.uniq types.str;
      default = cfg.ocamlPackages.ocaml.version;
      defaultText = literalExample "cfg.ocamlPackages.ocaml.version";
      description = ''
        The version of OCaml. This option only exist for propagating the version
        of OCaml through the configuration. As such, it should not be set manually
        but through the ocamlPackages option.
      '';
    };
    ocamlPackages = mkOption {
      type = types.lazyAttrsOf types.package;
      default = pkgs.ocamlPackages;
      defaultText = literalExample "pkgs.ocamlPackages";
      description = ''
        The set of OCaml packages from which to get OCaml and its packages.
        Use this option to set the version of OCaml.
      '';
      example = literalExample "pkgs.ocaml-ng.ocamlPackages_4_11";
    };
    packages = mkOption {
      type = with types; functionTo (listOf package);
      default = _: [ ];
      defaultText = literalExample "_ : []";
      description = ''
        OCaml packages that will be made available to the environment.
      '';
      example = literalExample ''
        ocamlPackages: with ocamlPackages; [ owl lwt ];
      '';
    };
    toplevel = {
      require = mkOption {
        type = types.listOf types.str;
        default = builtins.map (pkg: pkg.pname) cfg.packages;
        defaultText = "builtins.map (pkg: pkg.pname) config.ocaml.packages";
        description = ''
          The list of names of packages to load when launching a top-level.
        '';
        example = [ "owl" "lwt" ];
      };
      libDirs = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = ''
          Additional paths from which to load OCaml libraries.
        '';
        example = let dollar = "$";
        in literalExample ''
          [ ${dollar}{my-package}/lib/ocaml/${dollar}{config.ocaml.version}/site-lib/ ]
        '';
      };
      # Whether to list loaded packages when launching a top-level.
      list = mkEnableOption "#require list;;";
      # Whether to enable threading when running a top-level.
      thread = mkEnableOption "#require thread;;";
      extraInit = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional commands to run when running a top-level.
        '';
        example = "Topfind.reset();;";
      };
    };
    # Whether to load packages required by Tuareg (Emacs' OCaml mode).
    tuareg.enable = mkEnableOption "tuareg";
  };

  config = mkIf cfg.enable {
    buildInputs = ocamlBuildInputs;
    aliases = {
      utop = let
        utops = builtins.filter
          (p: match "(.*-utop)" (parseDrvName p.name).name != null)
          ocamlBuildInputs;
        utop = head utops;
      in mkIf (utops != [ ]) ''${utop}/bin/utop -init "${ocamlInit}"'';
      ocaml = ''${cfg.ocamlPackages.ocaml}/bin/ocaml -init "${ocamlInit}"'';
    };
  };
}
