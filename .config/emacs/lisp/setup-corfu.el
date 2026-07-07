;; -*- lexical-binding: t; -*-

(use-package corfu
  :defer t
  :custom (corfu-auto t)
  :hook (window-setup . global-corfu-mode))

(provide 'setup-corfu)
