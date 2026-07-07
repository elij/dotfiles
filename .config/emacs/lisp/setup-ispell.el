;; -*- lexical-binding: t; -*-

(use-package ispell
  :defer t
  :preface
  (defun my-hunspell-lookup-words-override (word &optional _lookup-dict)
    (let* ((clean-word (replace-regexp-in-string "\\*" "" word))
           (dict (or ispell-current-dictionary "en_GB"))
           (cmd (format "echo '%s' | %s -d %s -a | grep '^&'" clean-word ispell-program-name dict))
           (output (shell-command-to-string cmd)))
      (if (string-match ": \\(.*\\)" output)
          (split-string (match-string 1 output) ", " t)
        nil)))
  :custom
  (ispell-dictionary "british")
  (ispell-program-name "hunspell")
  :config
  (advice-add 'ispell-lookup-words :override #'my-hunspell-lookup-words-override))

(provide 'setup-ispell)
