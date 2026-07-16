;; -*- lexical-binding: t; -*-

(use-package ratex
  :vc (:url "https://github.com/elij/ratex.el")
  :after exec-path-from-shell
  :defer t
  :config
  (setq ratex-dark-render-color "white"
        ratex-light-render-color "black")
  :hook ((markdown-mode . global-ratex-mode)
         (markdown-ts-mode . global-ratex-mode)
         (gptel-mode . (lambda ()
                         (add-hook 'gptel-post-response-functions
                                   (lambda (_beg _end)
                                     (when (bound-and-true-p ratex-mode)
                                       (ratex-refresh-previews)))
                                   nil t)))))

(provide 'setup-ratex)
