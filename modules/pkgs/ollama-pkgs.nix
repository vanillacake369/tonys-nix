{ pkgs, lib, ... }: {

  home.packages = with pkgs; [
    ollama 
  ];
}

