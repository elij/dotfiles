;; -*- lexical-binding: t; -*-

(use-package grove
  :ensure nil
  :vc (:url "https://github.com/jonathanchu/grove")
  :defer t
  :bind-keymap ("C-c v" . grove-command-map)
  :custom
  (grove-graph-bg-color "#282c34")
  (grove-graph-node-color "#bbc2cf")
  (grove-directory "~/Documents/knowledge-base/") 
  (grove-tree-icons t)
  :config
  (global-grove-mode))

(provide 'setup-grove)
