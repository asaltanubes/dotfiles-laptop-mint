{ config, pkgs, lib, cspell-lsp, isMint, genericLinux?true, ... }:
let
  check-hm-updates = pkgs.writeShellApplication {
    name = "check-hm-updates";
    runtimeInputs = with pkgs; [ nix coreutils libnotify ];
    text = builtins.readFile ./scripts/update-check.sh;
  };
in
  {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "asaltanubes";
  home.homeDirectory = "/home/asaltanubes";
  targets.genericLinux.enable = genericLinux;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    check-hm-updates # script to check for updates on the packages

    pkgs.tmux
    pkgs.typst
    pkgs.ripgrep

    # Helix editor stuff
    pkgs.helix
    pkgs.nil # nix lsp
    pkgs.texlab # latex lsp
    pkgs.tinymist # typst lsp
    cspell-lsp.packages.${pkgs.stdenv.hostPlatform.system}.default # spelling lsp

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
     (pkgs.writeShellScriptBin "update-home-manager" ''
      cd "${config.home.homeDirectory}/.config/home-manager"
      nix flake update
      cd ~/dotfiles
      current_datetime="$a  %d-%m-%y %T"$a  %d-%m-%y %T
      git add home-manager
      git commit -m "Home-manager update on $current_datetime"
      git push
      cd "${config.home.homeDirectory}/.config/home-manager"
      home-manager switch --flake .
      '')
  ] ++ lib.optionals (!isMint) [ pkgs.xreader ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    "home.nix" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/home.nix";
    };
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/asaltanubes/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # systemd service to check for updates
  systemd.user.services.check-hm-updates = {
    Unit = {
      Description = "Check for Home Manager updates";
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe check-hm-updates;
    };
  };

  systemd.user.timers.check-hm-updates = {
    Timer = {
      OnStartupSec="5s";
      RandomicedDelaySec="3s";
    };
    Install.WantedBy = [ "timers.target" ];
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
