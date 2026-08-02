;;; setup-minibuffer.el -*- lexical-binding: t -*-

(use-package minibuffer
  :ensure nil
  :preface
  (defun my/completion-in-region-minibuffer (start end collection &optional predicate)
    "Divert `completion-at-point' to the minibuffer, respecting Eglot/LSP metadata."
    (let* ((initial (buffer-substring-no-properties start end))

           (exit-func (plist-get completion-extra-properties :exit-function))

           (result (completing-read "Complete: " collection predicate t initial)))
      
      (when result
        (delete-region start end)
        (insert result)
        
        ;; 3. If Eglot gave us an exit function (like an auto-import), run it now!
        (when exit-func
          (funcall exit-func result 'finished))
        t)))

  :hook (minibuffer-setup . cursor-intangible-mode)
  
  :custom
  (tab-always-indent 'complete)
  (enable-recursive-minibuffers t)
  (read-buffer-completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (minibuffer-depth-indicate-mode t)
  (minibuffer-electric-default-mode t)
  (minibuffer-prompt-properties
   '(read-only t intangible t cursor-intangible t face minibuffer-prompt))
  
  :config
  (setq completion-in-region-function #'my/completion-in-region-minibuffer))

(provide 'setup-minibuffer)
