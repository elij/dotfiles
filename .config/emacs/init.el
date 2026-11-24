;;; init.el --- Main initialisation -*- lexical-binding: t; -*-

(setq gc-cons-threshold (* 128 1024 1024))

(when (eq system-type 'android)
  (setq-default with-editor-emacsclient-executable
                (expand-file-name
                 (or (bound-and-true-p emacsclient-program-name)
                     "libemacsclient.so")
                 exec-directory))
  (tool-bar-mode 1)
  (modifier-bar-mode 1)
  (define-key secondary-tool-bar-map [spacer]
              `(menu-item "" ignore :image
                          ,(create-image (format "/* XPM */\nstatic char *s[]={\"60 1 1 1\",\" c None\",\"%60s\"};" "")
                                         'xpm t)))
  (add-to-list 'default-frame-alist '(tool-bar-position . bottom))
  (set-frame-parameter nil 'tool-bar-position 'bottom)
  (setq tool-bar-button-margin 32
        auto-resize-tool-bars t))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(unless (require 'use-package nil 'noerror)
  (package-refresh-contents)
  (package-install 'use-package)
  (require 'use-package))

(setq use-package-always-ensure t)

(run-with-idle-timer 2.0 nil
                     (lambda ()
                       (unless package-archive-contents
                         (message "Fetching MELPA package archives in the background...")
                         (package-refresh-contents t))))

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(dolist (file (directory-files (expand-file-name "lisp" user-emacs-directory) t "^setup-.*\\.el$"))
  (require (intern (file-name-base file))))

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 2 1024 1024))))

(put 'erase-buffer 'disabled nil)

(provide 'init)
;;; init.el ends here
