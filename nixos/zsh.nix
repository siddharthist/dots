{ config, pkgs, ... }:

{
  imports = [];

  environment = {

    systemPackages = with pkgs; [
      direnv # automatically invoke/revoke a nix-shell
      fasd
    ];

    shellAliases = {
      amiconnected = "while true; do if curl google.com &> /dev/null; then echo \"$(date +%H:%M) ~~~GOOD~~~\"; else echo \"$(date +%H:%M) ---BAD---\"; fi; sleep 5; done";
      docker-gc = "sudo docker ps -a -q -f status=exited | xargs --no-run-if-empty sudo docker rm";
      docker-gc-images = "docker images -q | xargs --no-run-if-empty docker rmi || true";
      sys = "sudo systemctl";
      sysu = "systemctl --user";
      pastebin = "curl -F \"clbin=<-\" https://clbin.com";
      test-ssh = "ssh -T git@github.com";
      ls1 = "ls -1";
      reload = "source /etc/zshrc";
      # TODO: imagemagick
      screenshot = "import -window root ~/Downloads/screenshot.jpg";
      conky = "conky --config=$XDG_CONFIG_HOME/conky/conkyrc";
      nixpkgs-pr-review = "export TRAVIS_BUILD_DIR=$PWD && ./maintainers/scripts/travis-nox-review-pr.sh nixpkgs-verify nixpkgs-manual nixpkgs-tarball && ./maintainers/scripts/travis-nox-review-pr.sh nixos-options nixos-manual";
      #nix-shell = "nix-shell --pure";

      # Convenience
      # TODO: nix function
      work-algebra = ''
        cd ~/Dropbox/langston/tex/math332; \
          zathura dummit.djvu & disown; \
          zathura notes/tex/1-ring-theory.pdf & disown; \
          ${pkgs.emacs}/bin/emacs & disown; \
          sleep 1; exit 0
      '';
      work-topology = ''
        cd ~/Dropbox/langston/tex/math342; \
          zathura lee.pdf & disown; \
          zathura notes/tex/4-6.pdf & disown; \
          ${pkgs.emacs}/bin/emacs & disown; \
          sleep 1; exit 0
      '';
      work-crypto = ''
        cd ~/Dropbox/langston/tex/math388; \
          zathura katz.pdf & disown; \
          zathura notes/tex/public-key-cryptography.pdf & disown; \
          ${pkgs.emacs}/bin/emacs & disown; \
          sleep 1; exit 0
      '';
      work-sf = ''
        cd ~/code/software-foundations; \
          firefox toc.html & disown; \
          nix-shell --run "${pkgs.emacs}/bin/emacs & disown"; \
          sleep 1; exit 0
      '';

      # Git
      ga = "git add";
      gb = "git branch";
      gc = "git checkout";
      gcl = "git clone --depth 20";
      gcm = "git commit -m";
      gd = "git diff";
      gdc = "git diff --cached";
      gdm = "git diff master";
      gf = "git fetch";
      gm = "git merge";
      gp = "git checkout master && git pull && git checkout -";
      gpo = "git push origin";
      gr = "git reset";
      grhm = "git reset --hard origin/master";
      gri = "git rebase -i";
      gs = "git status";
    };

    variables = {
      XDG_CONFIG_HOME = "$HOME/.config";
      PATH = "$PATH:$XDG_CONFIG_HOME/bin";
      EDITOR = "emacs";

      # masterpassword
      MP_FULLNAME = "Langston Barrett";
      MP_SITETYPE = "x";

    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    #enableSyntaxHighlighting = true;

    # custom prompt: "code > "
    promptInit = ''
      autoload -U promptinit && promptinit
      autoload -U colors && colors
      PROMPT="%{$fg_bold[0]%}%2~%  >%{$reset_color%} "
    '';

    # zshrc
    interactiveShellInit = ''
      # See NixOS/nix#1056
      if [ -n "$IN_NIX_SHELL" ]; then
        export TERMINFO=/run/current-system/sw/share/terminfo

        # Reload terminfo
        real_TERM=$TERM; TERM=xterm; TERM=$real_TERM; unset real_TERM
      fi

      eval "$(fasd --init posix-alias zsh-hook)"
      if [[ -z $IN_NIX_SHELL ]]; then
        eval "$(direnv hook zsh)"
      fi
      source_all() {[[ -d $1 ]] && for f in $1/*.zsh; do source "$f"; done; unset f;}
      source_all $HOME/.zsh.d
    '';
  };

  # programs.bash = {
  #   interactiveShellInit = ''
  #     if [[ -z $IN_NIX_SHELL ]]; then
  #       eval "$(direnv hook bash)"
  #     fi
  #     zsh; exit
  #   '';
  # };
}
