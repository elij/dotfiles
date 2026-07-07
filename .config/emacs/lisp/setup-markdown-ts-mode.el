;; -*- lexical-binding: t; -*-

(use-package markdown-ts-mode
  :mode ("\\.md\\'" . markdown-ts-mode)
  :defer t
  :config
  (require 'markdown-mode)
  (when (= emacs-major-version 30)
    (derived-mode-add-parents 'markdown-ts-mode '(markdown-mode text-mode)))
  (set-keymap-parent markdown-ts-mode-map markdown-mode-map)
  (define-key markdown-ts-mode-map (kbd "C-c C-c") nil)
  (define-key markdown-ts-mode-map (kbd "C-c C-c C-c") 'markdown-ts-toggle-checkbox)
  (add-to-list 'treesit-language-source-alist '(markdown "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "v0.2.3" "tree-sitter-markdown/src"))
  (add-to-list 'treesit-language-source-alist '(markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "v0.2.3" "tree-sitter-markdown-inline/src")))

(provide 'setup-markdown-ts-mode)
