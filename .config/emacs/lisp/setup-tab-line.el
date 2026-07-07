;; -*- lexical-binding: t; -*-

(use-package tab-line
  :ensure nil
  :defer t
  :custom
  (tab-line-close-button-show nil)
  :config
  (global-tab-line-mode -1)
  (setq tab-line-tab-name-format-function
        (lambda (tab &optional tabs)
          (let ((name (tab-line-tab-name-buffer tab tabs)))
            (concat "  " name "  "))))
  
  (let ((bg (face-background 'tab-line)))
    (set-face-attribute 'tab-line nil :box `(:line-width 6 :color ,bg :style nil)))
  (let ((bg (face-background 'tab-line-tab)))
    (set-face-attribute 'tab-line-tab nil :box `(:line-width 6 :color ,bg :style nil)))
  (let ((bg (face-background 'tab-line-tab-inactive)))
    (set-face-attribute 'tab-line-tab-inactive nil :box `(:line-width 6 :color ,bg :style nil))))

(provide 'setup-tab-line)
