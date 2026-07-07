;; -*- lexical-binding: t; -*-

(use-package files
  :ensure nil
  :preface
  (defun my/markdown-ggtel-mode-switch ()
    "Switch mode if a gptel local variable exists."
    (when (local-variable-p 'gptel-model)
      (gptel-mode)))
  :custom
  (backup-directory-alist `(("." . ,(expand-file-name "backup" user-emacs-directory))))
  (backup-by-copying t)
  (version-control t)
  (delete-old-versions t)
  (kept-new-versions 20)
  (kept-old-versions 5)
  (auto-save-file-name-transforms `((".*" ,(expand-file-name "backup" user-emacs-directory) t)))
  :hook
  (hack-local-variables . my/markdown-ggtel-mode-switch))

(provide 'setup-files)
