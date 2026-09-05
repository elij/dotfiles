;;; check_parens.el --- Parenthesis checking tool -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-check-parens-tool
      (gptel-make-tool
       :name "check_parens"
       :description "Check a specific Emacs Lisp file for balanced parentheses. Use this tool to locate syntax errors in Elisp files."
       :category "execution"
       :args '((:name "file"
                      :type "string"
                      :description "The relative path to the Elisp file to check"))
       :async t
       :function (macher-agent-with-presentation-context (file)
                   (let* ((native-fn (get 'macher-agent-check-parens-tool 'ptc-function))
                          (root (or (and context (macher-agent-context-project-root context))
                                    default-directory)))
                     (funcall native-fn file context root)))))

(put 'macher-agent-check-parens-tool 'ptc-function
     (lambda (file context _root)
       (let* ((raw-output
               (macher-agent-call-with-strict-vfs-pipeline
                context
                (lambda ()
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
                         (cmd (format "emacs --batch --eval %s 2>&1"
                                      (shell-quote-argument elisp-script))))
                    (shell-command-to-string cmd))))))
         (if (or (string-match-p "scan-error" raw-output)
                 (string-match-p "unbalanced" (downcase raw-output))
                 (string-match-p "error" (downcase raw-output)))
             (concat "ERROR: Parenthesis mismatch detected.\n\n=== EMACS OUTPUT ===\n" raw-output)
           (concat "SUCCESS: The file's parentheses are perfectly balanced.\n\n=== EMACS OUTPUT ===\n" raw-output)))))
