;; -*- lexical-binding: t; -*-

(use-package window
  :ensure nil
  :custom
  (split-height-threshold nil)
  (split-width-threshold 100)
  :config
  (setq-default top-margin-width 2 bottom-margin-height 2 left-margin-width 2 right-margin-width 2)
  (set-window-buffer nil (current-buffer))
  (let ((bg-colour (face-attribute 'default :background))
        (inactive-bg (face-attribute 'mode-line-inactive :background)))
    
    ;;   (set-face-attribute 'margin nil :background bg-colour)
    (set-face-attribute 'fringe nil :background bg-colour)

    (when (> emacs-major-version 31)
      (set-face-attribute 'header-line nil
                          :height 1
                          :background inactive-bg
                          :foreground (face-attribute 'default :foreground) 
                          :box `(:line-width 8 :color ,inactive-bg :style nil)
                          :underline `(:color ,inactive-bg :position t)))))

(provide 'setup-window)
