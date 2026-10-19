;; -*- lexical-binding: t; -*-

(use-package markdown-ts-appear
  :ensure t
  :pin nongnu
  :hook (markdown-mode . markdown-ts-appear-mode)
  :hook (markdown-ts-mode . markdown-ts-appear-mode)
  :config
  (defun my-mmdr-patch-make-process (orig-fn &rest args)
    (let* ((cmd (plist-get args :command))
           (filtered-cmd
            (when (and (listp cmd) (member "-b" cmd))
              (let (out (skip nil))
                (dolist (tok cmd (nreverse out))
                  (cond (skip (setq skip nil))
                        ((member tok '("-b" "-t")) (setq skip t))
                        ((equal tok "mmdc") (push "mmdr" out))
                        (t (push tok out))))))))
      (if filtered-cmd
          (apply orig-fn (plist-put (copy-sequence args) :command filtered-cmd))
        (apply orig-fn args))))

  (defun my-markdown-ts-appear-mmdc-wrapper (orig-fn &rest args)
    (unwind-protect
        (progn
          (advice-add 'make-process :around #'my-mmdr-patch-make-process)
          (apply orig-fn args))
      (advice-remove 'make-process #'my-mmdr-patch-make-process)))

  (with-eval-after-load 'markdown-ts-appear-diagram
    (advice-add 'markdown-ts-appear-diagram-mmdc :around #'my-markdown-ts-appear-mmdc-wrapper)
    (setopt markdown-ts-appear-diagram-renderers
            '(("mermaid" . markdown-ts-appear-diagram-mmdc)))))

(provide 'setup-markdown-ts-appear)
