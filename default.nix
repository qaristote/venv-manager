{  pkgs, settings }:

let
  lib = pkgs.lib; 
  defaultSettings = lib.optional (lib.pathExists ./config/default.nix) ./config;
  module = lib.evalModules {
    modules = [ settings ./modules ] ++ defaultSettings;
    specialArgs.pkgs = pkgs;
  };
in
pkgs.mkShell ({
  inherit (module.config)
    inputsFrom buildInputs nativeBuildInputs shellHook exitHook;
})
