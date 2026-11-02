;;; init.el --- Main initialisation -*- lexical-binding: t; -*-

(setq gc-cons-threshold (* 128 1024 1024))

(when (eq system-type 'android)
  (tool-bar-mode 1)
  (modifier-bar-mode 1)
  (add-to-list 'default-frame-alist '(tool-bar-position . bottom))
  (set-frame-parameter nil 'tool-bar-position 'bottom)
  (setq tool-bar-button-margin '(12 . 8))
  (setq auto-resize-tool-bars t))

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

(dolist (file (directory-files (expand-file-name "lisp" user-emacs-directory) t "^setup-.*\\.el$"))
  (let ((module-name (intern (file-name-base file))))
    (load-file file)
    (require module-name)))

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 2 1024 1024))))

(put 'erase-buffer 'disabled nil)

(provide 'init)
;;; init.el ends here
