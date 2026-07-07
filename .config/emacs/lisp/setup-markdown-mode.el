;; -*- lexical-binding: t; -*-

(use-package markdown-mode
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

  :custom
  (markdown-command 'my/pandoc-preprocess-mermaid)
  (markdown-enable-math t)
  (markdown-math-scale-factor 1.5)
  :config
  (setq markdown-unordered-list-item-prefix "- "))

(provide 'setup-markdown-mode)
