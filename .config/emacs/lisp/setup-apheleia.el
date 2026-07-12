;; -*- lexical-binding: t; -*-

(use-package apheleia
  :defer t
  :hook (window-setup . apheleia-global-mode)
  :config
  (setf (alist-get 'rustfmt apheleia-formatters)
        '("rustfmt" "--quiet" "--emit" "stdout" "--edition" "2024"))
  (dolist (mapping '((tsx-ts-mode . prettier)
                     (js-json-mode . prettier)
                     (js-mode . prettier)
                     (json-mode . prettier)
                     (html-mode . prettier)))
    (setf (alist-get (car mapping) apheleia-mode-alist) (cdr mapping))))


(provide 'setup-apheleia)
