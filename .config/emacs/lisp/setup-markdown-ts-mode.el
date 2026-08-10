;; -*- lexical-binding: t; -*-

(use-package markdown-ts-mode
  :ensure nil
  :mode ("\\.md\\'" . markdown-ts-mode)
  :defer t)

(provide 'setup-markdown-ts-mode)
