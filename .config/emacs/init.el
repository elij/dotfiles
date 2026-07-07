;; -*- lexical-binding: t; -*-
;; init.el

(setq gc-cons-threshold (* 128 1024 1024))

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

(provide 'init)
