;; -*- lexical-binding: t; -*-

(use-package ratex
  :vc (:url "https://github.com/elij/ratex.el")
  :after exec-path-from-shell
  :defer t
  :preface
  (defun my/ratex-setup-gptel ()
    (add-hook 'gptel-post-response-functions
              (lambda (_beg _end)
                (when (bound-and-true-p ratex-mode)
                  (ratex-refresh-previews)))
              nil t))
  :hook
  ((markdown-mode markdown-ts-mode) . ratex-mode)
  (gptel-mode . my/ratex-setup-gptel))

(provide 'setup-ratex)
