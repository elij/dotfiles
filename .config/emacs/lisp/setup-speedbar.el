;; -*- lexical-binding: t; -*-

(use-package speedbar
  :ensure nil
  :defer t
  :init
  (when (= emacs-major-version 30)
    (add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))))

(provide 'setup-speedbar)
