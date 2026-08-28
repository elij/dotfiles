;; -*- lexical-binding: t; -*-
(require 'macher-agent-vfs)

(macher-agent-make-tool
    macher-agent-elisp-lsp-tool
    "An Emacs Lisp Language Server to inspect the uncommitted workspace, please use to search codebase. 
Query types:
- 'hover': Returns function signature and documentation for a symbol.
- 'definition': Returns the file and line number where a symbol is defined.
- 'diagnostics': Runs the byte-compiler on a file to catch syntax and reference errors."
  :category "execution"
  :args '((:name "query_type" :type "string" :description "The type of query: 'hover', 'definition', or 'diagnostics'")
          (:name "target_file" :type "string" :description "The relative path to the Elisp file to load or analyze")
          (:name "symbol" :type "string" :optional t :description "The Elisp symbol to inspect (required for hover and definition)"))
  :command-fn
  (lambda (payload context _root)
    (let ((query-type (plist-get payload :query_type))
          (target-file (plist-get payload :target_file))
          (symbol (plist-get payload :symbol)))
      (macher-agent-call-with-strict-vfs-pipeline
       context
       (lambda ()
         (let* ((elisp-script
                 (format "(condition-case err
                             (progn
                               (setq byte-compile-error-on-warn nil)
                               (add-to-list 'load-path default-directory)
                               (pcase %S
                                 (\"hover\"
                                  (load-file %S)
                                  (let* ((sym (intern %S))
                                         (sig (ignore-errors (help-function-arglist sym)))
                                         (doc (ignore-errors (documentation sym t))))
                                    (princ (format \"SIGNATURE: %%S\\nDOCSTRING:\\n%%s\\n\" sig doc))))
                                 (\"definition\"
                                  (require 'find-func)
                                  (load-file %S)
                                  (let* ((sym (intern %S))
                                         (loc (ignore-errors (find-function-noselect sym))))
                                    (if loc
                                        (with-current-buffer (car loc)
                                          (princ (format \"FILE: %%s\\nLINE: %%d\\n\"
                                                         (file-relative-name (buffer-file-name) default-directory)
                                                         (line-number-at-pos (cdr loc)))))
                                      (princ \"ERROR: Definition not found.\\n\"))))
                                 (\"diagnostics\"
                                  (let* ((standard-output (current-buffer))
                                         (standard-error (current-buffer)))
                                    (ignore-errors (byte-compile-file %S))
                                    (princ (buffer-string))))
                                 (_ (princ \"ERROR: Unknown query type.\\n\"))))
                           (error
                            (princ (format \"ERROR during LSP execution: %%s\\n\" (error-message-string err)))))"
                         query-type target-file (or symbol "") target-file (or symbol "") target-file))
                (cmd (format "emacs --batch -Q --eval %s 2>&1"
                             (shell-quote-argument elisp-script))))
           (shell-command-to-string cmd))))))
  :success-fn
  (lambda (output _payload)
    (format "=== LSP QUERY RESULT ===\n%s" (string-trim output))))
