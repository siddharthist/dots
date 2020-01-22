{ pkgs, ... }:

{
  home.packages = with pkgs; [fasd];

  services = {
    dunst.enable = true;
    lorri.enable = true;
  };

  # programs.home-manager = {
  #   enable = true;
  # };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    sessionVariables = {
      # masterpassword
      MPW_FULLNAME = "Langston Barrett";
      MPW_SITETYPE = "x";
      XDG_CONFIG_HOME = "$HOME/.config";
      EDITOR = "emacs";
    };
    shellAliases = {
      amiconnected = "while true; do if curl google.com &> /dev/null; then echo \"$(date +%H:%M) ~~~GOOD~~~\"; else echo \"$(date +%H:%M) ---BAD---\"; fi; sleep 5; done";
      test-ssh = "ssh -T git@github.com";
      ls1 = "ls -1";
      screenshot = "import -window root ~/Downloads/screenshot.jpg";
      # Pipe stuff to this command and get a URL back
      pastebin = "curl -F \"clbin=<-\" https://clbin.com";

      # Docker
      docker-gc = "sudo docker ps -a -q -f status=exited | xargs --no-run-if-empty sudo docker rm";
      docker-gc-images = "docker images -q | xargs --no-run-if-empty docker rmi || true";

      # systemd
      sys   = "sudo systemctl";
      syss  = "sudo systemctl status";
      sysr  = "sudo systemctl restart";
      sysu  = "systemctl --user";
      sysus = "systemctl --user status";
      sysur = "systemctl --user restart";

      top5  = "watch 'ps aux | sort -nrk 3,3 | head -n 5'";
      cdr = "cd $(fd --type d | fzf)";
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };
}
