(macher-agent-make-tool
    macher-agent-check-parens-tool
    "Check a specific Emacs Lisp file for balanced parentheses. Use this tool to locate syntax errors in Elisp files."
  :category "execution"
  :args (list '(:name "file"
                      :type string
                      :description "The relative path to the Elisp file to check"))
  :command-fn
  (lambda (payload context _root)
    (let ((file (plist-get payload :file)))
      (macher-agent-call-with-strict-vfs-pipeline
       context
       (lambda ()
         (let* ((elisp-script
                 (format "(condition-case err
                             (progn
                               (find-file %S)
                               (check-parens)
                               (princ \"SUCCESS\\n\"))
                           (error
                            (let* ((pos (point))
                                   (start (save-excursion (beginning-of-defun) (point)))
                                   (end (save-excursion (end-of-defun) (point)))
                                   (snippet (buffer-substring-no-properties start end))
                                   (broken (replace-regexp-in-string \"[()]\" (lambda (m) (concat \"\\n\" m \"\\n\")) snippet))
                                   (cleaned (replace-regexp-in-string \"\\n+\" \"\\n\" broken)))
                              (princ (format \"Error at position %%d: %%s\\n\\n=== FAULTY FUNCTION BREAKDOWN ===\\n%%s\\n\" 
                                             pos 
                                             (error-message-string err) 
                                             cleaned)))))"
                         file))
                (cmd (format "emacs --batch --eval %s 2>&1"
                             (shell-quote-argument elisp-script))))
           (shell-command-to-string cmd))))))
  :success-fn
  (lambda (output)
    (if (or (string-match-p "scan-error" output)
            (string-match-p "unbalanced" (downcase output))
            (string-match-p "error" (downcase output)))
        (concat "ERROR: Parenthesis mismatch detected.\n\n=== EMACS OUTPUT ===\n" output)
      (concat "SUCCESS: The file's parentheses are perfectly balanced.\n\n=== EMACS OUTPUT ===\n" output))))
