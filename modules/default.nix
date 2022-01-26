{ config, lib, pkgs, ... }:

with lib;
let cfg = config;
in {
  imports = [
    ./coq.nix
    ./golang.nix
    ./latex.nix
    ./nix.nix
    ./ocaml.nix
    ./python.nix
    ./rust.nix
    ./why3.nix
  ];

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
    direnv.enable = mkEnableOption "direnv" // {
      description = ''
        Whether the shell is to be loaded by direnv.
      '';
    };
    pinDerivations = {
      enable = mkEnableOption "dependencies derivation pinning" // {
        description = ''
          Whether to pin the shell dependencies in a snapshot that will not be
          garbage collected.

          From https://nixos.wiki/wiki/Storage_optimization#Pinning :
          This will create a persistent snapshot of your shell.nix dependencies,
          which then won't be garbage collected, as long as you have configured
          keep-outputs = true (and haven't changed the default of
          keep-derivations = true). This is useful if your project has a
          dependency with no substitutes available, or you don't want to spend
          time waiting to re-download your dependencies every time you enter the
          shell.
        '';
      };
      filename = mkOption {
        type = types.str;
        default = "./shell.nix";
        description = ''
          The name of the shell file whose dependencies are to be pinned.
        '';
        example = "./default.nix";
      };
      outputDir = mkOption {
        type = types.str;
        default = "./.nix-gc-roots";
        description = ''
          The name of the directory in which to store the derivation snapshots.
        '';
      };
    };

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
    # envVars
    ## Environment variables are declared in a shell hook because simply adding the
    ## top-level arguments of pkgs.mkShell ovewrites the old values of the
    ## variables, which may be a problem, for example for PATH.
    (let
      dollar = "$";
      makeEnvVarCommand = name:
        { reset, value }:
        ''
          export "${name}"=${
            optionalString (!reset) (''"${dollar}${name}":'')
          }"${value}"'';
    in (attrValues (mapAttrs makeEnvVarCommand cfg.envVars)))
    # aliases
    ++ (if cfg.direnv.enable then
      (let
        aliasDir = ''"$PWD"/.direnv/aliases'';
        makeAliasCommand = name: value:
          let target = "${aliasDir}/${name}";
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
      in (attrValues (mapAttrs makeAliasCommand cfg.aliases))))
    # pinDerivations
    ++ (optional cfg.pinDerivations.enable ''
      rm -rf .nix-gc-roots
      ${pkgs.nix}/bin/nix-instantiate '${cfg.pinDerivations.filename}' --indirect --add-root '${cfg.pinDerivations.outputDir}/shell.drv'
    ''));
}
