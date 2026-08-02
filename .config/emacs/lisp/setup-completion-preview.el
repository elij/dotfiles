;; -*- lexical-binding: t; -*-

(use-package completion-preview
  :defer t
  :hook (after-init . global-completion-preview-mode)

  :preface
  (defun my/completion-preview-to-fido ()
    "Dismiss the inline preview and open our custom Fido minibuffer."
    (interactive)
    (completion-preview-active-mode -1)
    (completion-at-point))
  
  :config
  (add-to-list 'completion-category-overrides '(eglot-capf (styles flex-noinsert basic)))
  
  :bind (
         :map completion-preview-active-mode-map
         ("<tab>" . my/completion-preview-to-fido)
         ("TAB"   . my/completion-preview-to-fido)
         ("RET" . completion-preview-insert)))

(provide 'setup-completion-preview)
