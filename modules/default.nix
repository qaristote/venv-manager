{ config, lib, pkgs, ... }:

with lib;
let cfg = config;
in {
  imports =
    [ ./coq.nix ./golang.nix ./latex.nix ./nix.nix ./python.nix ./ocaml.nix ./why3.nix ];

  options = {
    # Inputs
    inputsFrom = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        The list of derivations whose inputs will be made available to the environment.
      '';
      example = literalExample ''
        [ pkgs.python3 ]
      '';
    };
    buildInputs = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        A list of derivations which will be made available to the environment.
      '';
      example = literalExample ''
        [ pkgs.ocamlPackages.owl ]
      '';
    };
    nativeBuildInputs = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        A list of derivations which will be made available to the environment
        and will be propagated.
      '';
      example = literalExample ''
        [ pkgs.python3 ];
      '';
    };

    # EnvVars
    envVars = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          reset = mkOption {
            type = types.bool;
            default = false;
            description = ''
              If `true`, reset the value of the variable before changing it.
              If `false`, the new value is thus set as $VAR=$VAR:`config.envVars.VAR.value`.
            '';
          };
          value = mkOption {
            type = types.envVar;
            default = "";
            description = ''
              The new value to give to the environment variable.
            '';
          };
        };
      });
      default = { };
      description = ''
        Environment variables that will be made available to the environment.
      '';
      example = {
        PATH = {
          reset = true;
          value = "~/.local/bin";
        };
      };
    };
    aliases = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Aliases.
        If direnv is enabled, they are installed as executables in
        .direnv/aliases. They may then take arguments. This also means that
        "recursive" aliases (e.g. ssh="export A=something ssh") will fail ; the
        executable in the definition should be called by its full path (e.g.
        $\{pkgs.openssh\}/bin/ssh). 
      '';
      example = literalExample ''
        { zz = "ls -la"; };
      '';
    };

    # Misc
    ## Whether the shell is to be loaded by direnv
    direnv.enable = mkEnableOption "direnv";

    # Hooks
    shellHook = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands to run after initializing the environment.
      '';
      example = ''
        alias ll="ls -l"
        git status
      '';
    };
    exitHook = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands to run when exiting the shell.
      '';
      example = ''
        git clean
      '';
    };
  };

  config.shellHook = concatStringsSep "\n" (
    # Environment variables are declared in a shell hook because simply adding the
    # top-level arguments of pkgs.mkShell ovewrites the old values of the
    # variables, which may be a problem, for example for PATH.
    (let
      dollar = "$";
      makeEnvVarCommand = name:
        { reset, value }:
        ''
          export "${name}"=${
            optionalString (!reset) (''"${dollar}${name}":'')
          }"${value}"'';
    in (attrValues (mapAttrs makeEnvVarCommand cfg.envVars)))
    ++ (if cfg.direnv.enable then
      (let
        aliasDir = ''"$PWD"/.direnv/aliases'';
        makeAliasCommand = name: value:
          let target = ''${aliasDir}/${name}'';
          in ''
            echo '#!${pkgs.bash}/bin/bash -e' > "${target}"
            echo "${value}" >> "${target}"
            chmod +x "${target}"
          '';
      in ([''
        mkdir -p "${aliasDir}"
        rm -f "${aliasDir}"/*
        PATH="${aliasDir}":"$PATH" # $PATH has to come last for the alias to take effect
      ''] ++ (attrValues (mapAttrs makeAliasCommand cfg.aliases))))
    else
      (let makeAliasCommand = name: value: ''alias "${name}"="${value}"'';
      in (attrValues (mapAttrs makeAliasCommand cfg.aliases)))));
}
