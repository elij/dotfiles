;;; check_parens.el --- Parenthesis checking tool -*- lexical-binding: t; -*-
(setq macher-agent-check-parens-tool
      (gptel-make-tool
       :name "check_parens"
       :description "Check a specific Emacs Lisp file for balanced parentheses. Use this tool to locate syntax errors in Elisp files."
       :category "execution"
       :args '((:name "file"
                      :type "string"
                      :description "The relative path to the Elisp file to check"))
       :async t
       :function (lambda (callback file)
                   (let ((thunk (funcall (get 'macher-agent-check-parens-tool 'ptc-function) file)))
                     (funcall thunk callback)))))

(put 'macher-agent-check-parens-tool 'ptc-function
     (lambda (file &optional context _root)
       (let ((ctx (or context (current-buffer))))
         (lambda (resolve)
           (let* ((elisp-script
                   (format
                    "(condition-case err
                         (progn
                           (find-file %S)
                           (check-parens)
                           (princ \"SUCCESS\\n\"))
                       (error
                        (let* ((pos (point))
                               (start (save-excursion (beginning-of-defun) (point)))
                               (end (save-excursion (end-of-defun) (point)))
                               (snippet (buffer-substring-no-properties start end))
                               (counter 0)
                               (stack nil)
                               (broken (replace-regexp-in-string \"[()]\"
                                         (lambda (m)
                                           (if (string= m \"(\")
                                               (let ((id (setq counter (1+ counter))))
                                                 (push id stack)
                                                 (format \"\\n(%%d\\n\" id))
                                             (let ((id (if stack (pop stack) \"?\")))
                                               (format \"\\n)%%s\\n\" id))))
                                         snippet))
                               (cleaned (replace-regexp-in-string \"\\n+\" \"\\n\" broken)))
                          (princ (format \"Error at position %%d: %%s\\n\\n=== FAULTY FUNCTION BREAKDOWN ===\\n%%s\\n\"
                                         pos
                                         (error-message-string err)
                                         cleaned)))))"
                    file))
                  (cmd (format "emacs --batch --eval %s </dev/null 2>&1"
                               (shell-quote-argument elisp-script))))
             (macher-agent-run-in-vfs-sandbox
              ctx cmd resolve
              (lambda (code output)
                (if (or (/= code 0)
                        (string-match-p "scan-error" output)
                        (string-match-p "unbalanced" (downcase output))
                        (string-match-p "error" (downcase output)))
                    (concat "ERROR: Parenthesis mismatch detected.\n\n=== EMACS OUTPUT ===\n" output)
                  (concat "SUCCESS: The file's parentheses are perfectly balanced.\n\n=== EMACS OUTPUT ===\n" output)))))))))
