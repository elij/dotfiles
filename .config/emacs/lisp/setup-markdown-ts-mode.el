;; -*- lexical-binding: t; -*-

(use-package markdown-ts-mode
  :ensure nil
  :mode ("\\.md\\'" . markdown-ts-mode)
  :defer t
  :preface
  (defun my/pandoc-preprocess-mermaid (begin end output-buffer)
    (let ((input-text (buffer-substring-no-properties begin end)))
      (with-temp-buffer
        (insert input-text)
        (goto-char (point-min))
        (let ((mermaid-regex (concat "^" (make-string 3 ?\`) "mermaid[ \t]*\n\\(\\(?:.\\|\n\\)*?\\)" (make-string 3 ?\`))))
          (while (re-search-forward mermaid-regex nil t)
            (let ((mermaid-code (match-string 1))
                  (block-start (match-beginning 0))
                  (block-end (match-end 0)))
              (delete-region block-start block-end)
              (goto-char block-start)
              (insert
               (with-temp-buffer
                 (insert mermaid-code)
                 (call-process-region (point-min) (point-max) "mmdr" t t nil "-e" "svg")
                 (buffer-string))))))
        (call-process-region (point-min) (point-max) "pandoc" nil output-buffer nil "-f" "markdown" "-t" "html"))))

  (defun my/markdown-ts-convert-mermaid-override (orig-fun &rest args)
    "Intercept `markdown-ts-convert' to run custom `mmdr` + `pandoc` Elisp pipeline."
    (let* ((output-file (or (nth 1 args)
                            (read-file-name "Output file name: " nil nil nil
                                            (concat (file-name-sans-extension (buffer-name)) ".html")))))
      (with-current-buffer (get-buffer-create "*pandoc-html-output*")
        (erase-buffer))
      (my/pandoc-preprocess-mermaid (point-min) (point-max) "*pandoc-html-output*")
      (with-current-buffer "*pandoc-html-output*"
        (write-region (point-min) (point-max) output-file))
      (message "Successfully converted buffer to %s via Elisp preprocessor" output-file)))

  (defun my/markdown-ts-insert-structure-extended (orig-fun &optional char)
    "Extend `markdown-ts-insert-structure` to add checkbox choices [x] and [X]."
    (interactive
     (list (read-char "Structure [`]code [~]tilde [q]uote [d]ivider [t]able [x]box [X]box-checked:")))
    (pcase char
      (?x (insert "- [ ] "))
      (?X (insert "- [x] "))
      (_ (funcall orig-fun char))))

  :custom-face
  (markdown-ts-code ((t (:inherit fixed-pitch))))
  (markdown-ts-code-block ((t (:inherit fixed-pitch))))
  (markdown-ts-heading-1 ((t (:height 1.5 :weight bold :inherit (outline-1 variable-pitch)))))
  (markdown-ts-heading-2 ((t (:height 1.3 :weight bold :inherit (outline-2 variable-pitch)))))
  (markdown-ts-heading-3 ((t (:height 1.18 :weight bold :inherit (outline-3 variable-pitch)))))
  (markdown-ts-heading-4 ((t (:height 1.08 :weight bold :inherit (outline-4 variable-pitch)))))
  (markdown-ts-heading-5 ((t (:height 1.0 :weight bold :inherit (outline-5 variable-pitch)))))
  (markdown-ts-heading-6 ((t (:height 1.0 :weight bold :inherit (outline-6 variable-pitch)))))

  :config
  (advice-add 'markdown-ts-convert :around #'my/markdown-ts-convert-mermaid-override)
  (advice-add 'markdown-ts-insert-structure :around #'my/markdown-ts-insert-structure-extended)

  :hook
  (markdown-ts-mode . variable-pitch-mode))

(provide 'setup-markdown-ts-mode)
