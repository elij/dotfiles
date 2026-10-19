;; -*- lexical-binding: t; -*-

(use-package markdown-ts-appear
  :ensure t
  :pin nongnu
  :hook (markdown-mode . markdown-ts-appear-mode)
  :hook (markdown-ts-mode . markdown-ts-appear-mode))

(provide 'setup-markdown-ts-appear)
