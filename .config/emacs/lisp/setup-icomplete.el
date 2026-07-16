;; -*- lexical-binding: t; -*-

(use-package icomplete
  :ensure nil
  :defer t
  :hook (after-init . fido-vertical-mode)
  :config
  (advice-add 'icomplete-exhibit :after
              (lambda (&rest _)
                (when (and (window-minibuffer-p) 
                           (overlayp icomplete-overlay))
                  (overlay-put icomplete-overlay 'window (selected-window))))))

(provide 'setup-icomplete)
