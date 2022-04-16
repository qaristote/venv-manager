{ pkgs, settings }:

let
  lib = pkgs.lib;
  defaultSettings = lib.optional (lib.pathExists ./config/default.nix) ./config;
  module = lib.evalModules {
    modules = [ settings ./modules ] ++ defaultSettings;
    specialArgs.pkgs = pkgs;
  };
  clean-hooks = hookList:
    lib.mapAttrs (name: value:
      if lib.elem name hookList then ''
        ${value}
        export "${name}"=
      '' else
        value);
in pkgs.mkShell ({
  inherit (clean-hooks [ "shellHook" ] module.config)
    inputsFrom buildInputs nativeBuildInputs shellHook exitHook;
})
