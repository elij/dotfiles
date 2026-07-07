;; -*- lexical-binding: t; -*-

(use-package grove-extra
  :ensure nil
  :vc (:url "https://github.com/elij/grove-extra")
  :defer t
  :commands (grove-extra-mode)
  :hook (global-grove-mode . grove-extra-mode)
  :custom
  (grove-default-extension "md")
  (grove-file-extensions '("md" "org"))
  (grove-graph-renderer 'fa2)
  (grove-graph-default-zoom 1.0)
  (grove-graph-mmdr-direction "TD")
  (grove-extra-use-speedbar (>= emacs-major-version 31)))

(provide 'setup-grove-extra)
