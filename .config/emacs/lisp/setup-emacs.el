;; -*- lexical-binding: t; -*-

(use-package emacs
  :ensure nil
  :custom
  (gc-cons-threshold (* 2 1024 1024))
  (jit-lock-defer-time 0.25)
  (bidi-display-reordering nil)
  (bidi-paragraph-direction 'left-to-right)
  (long-line-threshold 5000)
  (system-time-locale "en_GB.UTF-8")
  (indent-tabs-mode nil)
  (tab-width 4)
  (standard-indent 4)
  :config
  (setq custom-file (expand-file-name "custom.el" user-emacs-directory))
  (when (file-exists-p custom-file)
    (load custom-file 'noerror))
  
  (load-theme 'tango-dark t)
  
  (add-hook 'emacs-startup-hook
            (lambda ()
              (let ((hook-start (current-time))
                    (bg-active (face-background 'mode-line))
                    (bg-inactive (face-background 'mode-line-inactive)))
                (set-face-attribute 'mode-line nil :box `(:line-width 6 :color ,bg-active :style nil))
                (set-face-attribute 'mode-line-inactive nil :box `(:line-width 6 :color ,bg-inactive :style nil))))))

(provide 'setup-emacs)
