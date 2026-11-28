;;; deno_doc.el --- Inspect Deno module documentation and type signatures -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'ansi-color)
(require 'gptel)

(setq macher-agent-deno-doc-tool
      (gptel-make-tool
       :name "deno_doc"
       :description "Inspect TypeScript or JavaScript module exports and type signatures using 'deno doc' inside the VFS."
       :category "perception"
       :include nil
       :args '((:name "specifier"
                :type "string"
                :description "Module specifier or workspace file path (for example, 'jsr:@fresh/core@2.2.2' or './utils.ts').")
               (:name "filter"
                :type "string"
                :optional t
                :description "Optional symbol name filter passed to '--filter' (for example, 'Context').")
               (:name "cwd"
                :type "string"
                :optional t
                :description "Optional workspace-relative directory (defaults to '.')."))
       :async t
       :function (lambda (callback specifier &optional filter cwd)
                   (let ((thunk (funcall (get 'macher-agent-deno-doc-tool 'ptc-function)
                                         specifier filter cwd)))
                     (funcall thunk callback)))))

(put 'macher-agent-deno-doc-tool 'ptc-function
     (lambda (specifier &optional filter cwd context _root)
       (let* ((ctx-in-filter (and (null context)
                                  (null cwd)
                                  (not (null filter))
                                  (not (stringp filter))))
              (ctx-in-cwd (and (not ctx-in-filter)
                               (null context)
                               (not (null cwd))
                               (not (stringp cwd))))
              (raw-filter (if ctx-in-filter nil filter))
              (raw-cwd (if (or ctx-in-filter ctx-in-cwd) nil cwd))
              (ctx (or (cond
                        (ctx-in-filter filter)
                        (ctx-in-cwd cwd)
                        (t context))
                       (current-buffer)))
              (clean-spec (if (stringp specifier) (string-trim specifier) ""))
              (clean-filter (if (and (stringp raw-filter)
                                     (not (string-empty-p (string-trim raw-filter))))
                                (string-trim raw-filter)
                              nil))
              (clean-cwd (if (and (stringp raw-cwd)
                                  (not (string-empty-p (string-trim raw-cwd))))
                             (string-trim raw-cwd)
                           "."))
              (run-fn (if (fboundp 'macher-agent-vfs-run-in-sandbox)
                          #'macher-agent-vfs-run-in-sandbox
                        #'macher-agent-run-in-vfs-sandbox)))
         (lambda (resolve)
           (cond
            ((string-empty-p clean-spec)
             (funcall resolve "ERROR: Module specifier must be a non-empty string."))
            ((or (string-prefix-p "/" clean-cwd)
                 (string-match-p "\\(^\\|/\\)\\.\\.\\(/\\|$\\)" clean-cwd))
             (funcall resolve
                      (format "ERROR: Invalid workspace-relative cwd '%s'." clean-cwd)))
            (t
             (let* ((filter-arg (if clean-filter
                                    (format " --filter %s" (shell-quote-argument clean-filter))
                                  ""))
                    (cmd (format "cd %s && NO_COLOR=1 deno doc -q%s %s </dev/null 2>&1"
                                 (shell-quote-argument clean-cwd)
                                 filter-arg
                                 (shell-quote-argument clean-spec))))
               (funcall
                run-fn ctx cmd resolve
                (lambda (code output)
                  (let ((clean-out (replace-regexp-in-string
                                    "\r" ""
                                    (ansi-color-filter-apply output))))
                    (if (/= code 0)
                        (format "ERROR: deno doc failed (exit code %d).\n\n=== OUTPUT ===\n%s"
                                code clean-out)
                      (concat "=== DENO DOC ===\n" clean-out))))))))))))
