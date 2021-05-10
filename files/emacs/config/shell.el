;; -*- lexical-binding: t; -*-
;;; shell

;; TODO(lb): Try out https://github.com/mbriggs/emacs-pager
;; TODO(lb): Can directory-tracking work in SSH sessions?

;;; Directory Tracking

(defun add-mode-line-dirtrack ()
  (add-to-list
   'mode-line-buffer-identification
   '(:propertize (" " default-directory " ") face dired-directory)))


;; TODO: Make TRAMP procfs directory tracking into a MELPA package

(defun my/get-local-shell-pid ()
  (process-id
   (get-buffer-process
    (current-buffer))))

(defun my/get-remote-shell-pid ()
  (interactive)
  (comint-simple-send (get-buffer-process (current-buffer)) "echo $$\n")
  (let ((comint-last-output-end
         (save-excursion
           (goto-char comint-last-output-start)
           (evil-forward-word)
           (point))))
    (buffer-substring comint-last-output-start comint-last-output-end)))

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
         (setq my/shell-procfs-dirtrack-shell-pid
               (if (tramp-tramp-file-p default-directory)
                   (my/get-remote-shell-pid)
                 (my/get-local-shell-pid)))
         (when (bound-and-true-p shell-dirtrack-mode)
           (shell-dirtrack-mode 0))
         (when (bound-and-true-p dirtrack-mode)
           (dirtrack-mode 0))
         (add-hook 'comint-preoutput-filter-functions
                   'shell-procfs-dirtrack nil t))
        (t
         (remove-hook 'comint-preoutput-filter-functions
                      'shell-procfs-dirtrack t))))

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
(add-hook 'shell-mode-hook #'shell-procfs-dirtrack-mode)

(defun my/shell-mode-hook ()
  (evil-local-set-key 'normal "N" #'my/new-shell)
  (evil-local-set-key 'normal "n" #'my/new-shell)
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
