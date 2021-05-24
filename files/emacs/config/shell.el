;; -*- lexical-binding: t; -*-
;;; shell

;; TODO(lb): Try out https://github.com/mbriggs/emacs-pager
;; TODO(lb): Can directory-tracking work in SSH sessions?

;;; Directory Tracking

(defun add-mode-line-dirtrack ()
  (add-to-list
   'mode-line-buffer-identification
   '(:propertize (" " default-directory " ") face dired-directory)))

;;;; Procfs

;; NOTE: This has been difficult to get to work with TRAMP, so I use the prompt
;; method below.
;;
;; TODO: Make TRAMP procfs directory tracking into a MELPA package

(defvar my/shell-procfs-dirtrack-tramp-prefix "")
(defvar my/shell-procfs-dirtrack-shell-pid nil)
(make-variable-buffer-local 'my/shell-procfs-dirtrack-tramp-prefix)
(make-variable-buffer-local 'my/shell-procfs-dirtrack-shell-pid)

(defun my/get-local-shell-pid ()
  (process-id
   (get-buffer-process
    (current-buffer))))

(defun my/get-remote-shell-pid ()
  (interactive)
  (comint-simple-send (get-buffer-process (current-buffer)) "echo \" $$\"\n")
  (save-excursion
    (search-backward-regexp " [[:digit:]]+")
    (string-to-number
     (buffer-substring (match-beginning 0) (match-end 0)))))

(defun my/shell-procfs-dirtrack-refresh-pid ()
  (interactive)
  (setq my/shell-procfs-dirtrack-shell-pid
        (if (tramp-tramp-file-p default-directory)
            (my/get-remote-shell-pid)
          (my/get-local-shell-pid))))

(defun shell-procfs-dirtrack (str)
  (prog1 str
    (when (string-match comint-prompt-regexp str)
      (let ((directory (tramp-handle-file-symlink-p
                        (format (concat my/shell-procfs-dirtrack-tramp-prefix
                                        "/proc/%s/cwd")
                                my/shell-procfs-dirtrack-shell-pid))))
        (when (tramp-handle-file-directory-p directory)
          (cd directory))))))

(define-minor-mode shell-procfs-dirtrack-mode
  "Track shell directory by inspecting procfs."
  nil nil nil

  (defvar-local my/shell-procfs-dirtrack-tramp-prefix "")
  (defvar-local my/shell-procfs-dirtrack-shell-pid "")

  (cond (shell-procfs-dirtrack-mode
         (setq my/shell-procfs-dirtrack-tramp-prefix
               (if (tramp-tramp-file-p default-directory)
                   ;; (with-parsed-tramp-file-name default-directory parsed
                   ;;   ;; TODO: How to go from TRAMP struct to string?
                   ;;   )
                   (my/get-tramp-prefix default-directory)
                 ""))
         (my/shell-procfs-dirtrack-refresh-pid)
         (when (bound-and-true-p shell-dirtrack-mode)
           (shell-dirtrack-mode 0))
         (when (bound-and-true-p dirtrack-mode)
           (dirtrack-mode 0))
         (add-hook 'comint-preoutput-filter-functions
                   'shell-procfs-dirtrack nil t))
        (t
         (remove-hook 'comint-preoutput-filter-functions
                      'shell-procfs-dirtrack t))))

;; (add-hook 'shell-mode-hook #'shell-procfs-dirtrack-mode)

;;;; Prompt

;; In ZSH, try:
;;
;;     NEWLINE=$'\n'
;;     PROMPT="%30000<<${NEWLINE}[/ssh:%n@%m:%0d]${NEWLINE}> "
;;
;; In Bash:
;;
;;     NEWLINE=$'\n'
;;     PS1="${NEWLINE}[/ssh:\u@\h:\w]${NEWLINE}> "
;;
;; In Docker (TODO: Not working, docker-tramp hangs):
;;
;;     NEWLINE=$'\n'
;;     CID=$(basename $(cat /proc/1/cpuset))
;;     CID=${CID:0:12}
;;     USER=$(whoami)
;;     PS1="${NEWLINE}[/ssh:langston@big|sudo:root@big|docker:${USER}@${CID}:\w] ${NEWLINE}> "
;;
;; In Podman:
;;
;;     NEWLINE=$'\n'
;;     CID=${CID:0:12}
;;     USER=$(whoami)
;;     PS1="${NEWLINE}[/ssh:langston@big|docker:${USER}@${CID}:\w] ${NEWLINE}> "
;;
;; Then:

(setq dirtrack-list '("^\\[\\(/.+\\)\\]" 1 nil))
(add-hook 'shell-mode-hook #'dirtrack-mode)
(setq docker-tramp-docker-executable "podman")

(defun my/local-zsh-prompt ()
  (interactive)
  (insert
   "NEWLINE=$'\\n'\n"
   "PROMPT=\"%30000<<${NEWLINE}[%0d]${NEWLINE}> \""))

(defun my/ssh-zsh-prompt ()
  (interactive)
  (insert
   "NEWLINE=$'\\n'\n"
   "PROMPT=\"%30000<<${NEWLINE}[/ssh:%n@%m:%0d]${NEWLINE}> \""))

(defun my/podman-bash-prompt ()
  (interactive)
  (insert
   "NEWLINE=$'\\n'\n"
   "CID=${CID:0:12}\n"
   "USER=$(whoami)\n"
   "PS1=\"${NEWLINE}[/ssh:langston@big|docker:${USER}@${CID}:\w] ${NEWLINE}> \"\n"))

;;; Variables, Keybindings, and Hooks

(setq shell-file-name "/run/current-system/sw/bin/zsh")

(defun my/new-shell ()
  (interactive)
  (let ((current-prefix-arg 1))
    (call-interactively #'shell)))

;; TODO: Why does default-directory stay at host /tmp?
(defun my/new-shell-big ()
  (interactive)
  (let ((host (my/choose-host))
        (default-directory "/ssh:big:/home/langston/code/"))
    (cd "/ssh:big:/home/langston/code/")
    (shell)))

(add-hook 'shell-mode-hook #'add-mode-line-dirtrack)

(defun my/shell-mode-hook ()
  (evil-local-set-key 'normal "mN" #'my/new-shell)
  (evil-local-set-key 'normal "mn" #'my/new-shell)
  (setq-local olivetti-body-width 140))

(add-hook 'shell-mode-hook #'my/shell-mode-hook)

;;; Interception

;; TODO: Fun stuff like interpolate values of lisp variables or results of
;; calling lisp functions.

;; TODO: TRAMP awareness!

(defun my/comint-intercept-man (str)
  (pcase (split-string str)
    (`("man" ,page) (prog1 "" (woman page)))
    (_ str)))

(defun my/comint-intercept-git-status (str)
  (pcase str
    ("git status" (prog1 "" (magit-status)))
    (_ str)))

(defun my/comint-intercept-ff (str)
  (pcase (split-string str)
    (`("ff" ,arg) (prog1 "" (find-file arg)))
    (_ str)))

;; TODO Doesn't quite work?
(defun my/comint-intercept-lisp (str)
  (pcase (split-string str)
    (`(":eval" ,rest) (prog1 "" (eval rest)))
    (_ str)))

(setq
  my/comint-transformer-list
  (list
   #'my/comint-intercept-man
   #'my/comint-intercept-git-status
   #'my/comint-intercept-ff
   #'my/comint-intercept-lisp))

(defun my/comint-intercept (args)
  (pcase args
    (`(,proc ,str)
     (list proc (funcall (apply #'-compose my/comint-transformer-list) str)))
    (_
     (progn
       (warn "Bad args to comint-input-sender: %s" args)
       args))))

;; TODO: Maybe apply to (the value of) comint-input-sender instead?
(advice-add #'comint-simple-send :filter-args #'my/comint-intercept)
;; (advice-remove #'comint-simple-send #'my/comint-intercept)

;; TODO: Source ~/.zsh.d/prompt?
