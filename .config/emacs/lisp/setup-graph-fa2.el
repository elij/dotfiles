;; -*- lexical-binding: t; -*-

(use-package graph-fa2
  :ensure nil
  :vc (:url "https://github.com/elij/graph-fa2")
  :defer t
  :config
  (setq graph-fa2-surface-constraint 'none)
  (setq graph-fa2-horizon-threshold 131768)
  :commands (graph-fa2-start graph-fa2-render))

(provide 'setup-graph-fa2)
