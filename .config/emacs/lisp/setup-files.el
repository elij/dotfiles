;; -*- lexical-binding: t; -*-

(use-package files
  :ensure nil
  :preface
  (defun my/markdown-gptel-mode-switch ()
    "Switch mode if a gptel local variable exists."
    (when (local-variable-p 'gptel-model)
      (let ((saved-tools (when (local-variable-p 'gptel--tool-names)
                           gptel--tool-names)))
        (when saved-tools
          (setq-local gptel--tool-names nil))
        (gptel-mode)
        (when saved-tools
          (setq-local gptel--tool-names saved-tools)
          (when (fboundp 'gptel--restore-state)
            (ignore-errors (gptel--restore-state)))
          ))))
  :custom
  (backup-directory-alist `(("." . ,(expand-file-name "backup" user-emacs-directory))))
  (backup-by-copying t)
  (version-control t)
  (delete-old-versions t)
  (kept-new-versions 20)
  (kept-old-versions 5)
  (auto-save-file-name-transforms `((".*" ,(expand-file-name "backup" user-emacs-directory) t)))
  :hook
  (hack-local-variables . my/markdown-gptel-mode-switch))

(provide 'setup-files)
