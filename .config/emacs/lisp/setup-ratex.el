;; -*- lexical-binding: t; -*-

(use-package ratex
  :vc (:url "https://github.com/elij/ratex.el" 
            :lisp-dir "lisp")
  :after exec-path-from-shell
  :defer t
  :config
  (setq ratex-dark-render-color "white"
        ratex-light-render-color "black")
  :hook ((markdown-mode . global-ratex-mode)
         (markdown-ts-mode . global-ratex-mode)))

(provide 'setup-ratex)
