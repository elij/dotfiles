;; -*- lexical-binding: t; -*-

(use-package ratex
  :vc (:url "https://github.com/elij/ratex.el")
  :after exec-path-from-shell
  :defer t
  :commands (global-ratex-mode)
  
  :hook ((after-init . global-ratex-mode)
         (markdown-ts-mode . ratex-mode)
         (gptel-mode . (lambda ()
                         (add-hook 'gptel-post-response-functions
                                   (lambda (_beg _end)
                                     (when (bound-and-true-p ratex-mode)
                                       (ratex-refresh-previews)))
                                   nil t)))))

(provide 'setup-ratex)
