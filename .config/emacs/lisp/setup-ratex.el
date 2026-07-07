;; -*- lexical-binding: t; -*-

(use-package ratex
  :ensure nil
  :load-path "lisp/"
  :after exec-path-from-shell
  :defer t
  :preface
  (defun my-ratex-add-dollar-delimiters-advice (orig-fun &rest args)
    (let ((ratex--delimiter-pairs (append '(("$$" . "$$") ("$" . "$")) ratex--delimiter-pairs)))
      (apply orig-fun args)))

  :config
  (setq ratex-dark-render-color "white")
  (setq ratex-light-render-color "black")
  (advice-add 'ratex-fragments-in-buffer :around #'my-ratex-add-dollar-delimiters-advice)
  (advice-add 'ratex-fragment-at-point :around #'my-ratex-add-dollar-delimiters-advice)
  :hook ((markdown-mode . global-ratex-mode))
  :custom
  (ratex-backend-binary "ratex-editor-backend"))


(provide 'setup-ratex)
