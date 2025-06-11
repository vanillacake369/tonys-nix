# Module for lua compilation
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "lua-dev-env";

  buildInputs = [
    pkgs.lua54Packages.lua
    pkgs.lua54Packages.luaunit
  ];
}
