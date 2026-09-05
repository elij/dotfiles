;;; elisp_lsp.el --- Emacs Lisp inspection tool -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'macher-agent-core)
(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-elisp-lsp-tool
      (gptel-make-tool
       :name "elisp_lsp"
       :description "An Emacs Lisp Language Server to inspect the uncommitted workspace, please use to search codebase.
Query types:
- 'hover': Returns function signature and documentation for a symbol.
- 'definition': Returns the file and line number where a symbol is defined.
- 'diagnostics': Runs the byte-compiler on a file to catch syntax and reference errors."
       :category "execution"
       :args '((:name "query_type" :type "string" :description "The type of query: 'hover', 'definition', or 'diagnostics'")
               (:name "target_file" :type "string" :description "The relative path to the Elisp file to load or analyse")
               (:name "symbol" :type "string" :optional t :description "The Elisp symbol to inspect (required for hover and definition)"))
       :async t
       :function (macher-agent-with-presentation-context (query_type target_file &optional symbol)
                   (let* ((native-fn (get 'macher-agent-elisp-lsp-tool 'ptc-function))
                          (root (or (and context (macher-agent-context-project-root context))
                                    default-directory)))
                     (funcall native-fn query_type target_file symbol context root)))))

(put 'macher-agent-elisp-lsp-tool 'ptc-function
     (lambda (query-type target-file symbol context _root)
       (let ((output
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
         (format "=== LSP QUERY RESULT ===\n%s" (string-trim output)))))
