;; -*- lexical-binding: t; -*-

(use-package rust-ts-mode
  :defer t
  :mode ("\\.rs\\'" . rust-ts-mode)
  :hook (rust-ts-mode . eglot-ensure))

(provide 'setup-rust-ts-mode)
