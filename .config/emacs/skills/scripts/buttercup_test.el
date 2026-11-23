;;; buttercup_test.el --- Buttercup test execution tool -*- lexical-binding: t; -*-

(setq macher-agent-buttercup-test-tool
      (gptel-make-tool
       :name "buttercup_test"
       :description "Run buttercup-run-discover to test the project. You must use this tool to test changes made in the VFS with write to workspace tools. No other tool should be used for Elisp testing."
       :category "execution"
       :args '((:name "search_path"
                :type "string"
                :optional t
                :description "Optional workspace-relative directory path to search for tests (defaults to \"tests\")."))
       :async t
       :function (lambda (callback &optional search-path)
                   (let ((thunk (funcall (get 'macher-agent-buttercup-test-tool 'ptc-function)
                                         search-path)))
                     (funcall thunk callback)))))

(put 'macher-agent-buttercup-test-tool 'ptc-function
     (lambda (&optional search-path context)
       ;; When called with 0 arguments from PTC as `(buttercup-test)',
       ;; `macher-agent--dispatch-ptc-primitive' appends `context' to an empty
       ;; argument list, placing `context' in the `search-path' slot.
       (let* ((ctx-in-first-arg (and (null context)
                                     (not (null search-path))
                                     (not (stringp search-path))))
              (raw-path (if ctx-in-first-arg nil search-path))
              (ctx (or (if ctx-in-first-arg search-path context)
                       (current-buffer)))
              (target-dir (if (and (stringp raw-path)
                                   (not (string-empty-p (string-trim raw-path))))
                              (string-trim raw-path)
                            "tests"))
              (quoted-dir (shell-quote-argument target-dir)))
         (lambda (resolve)
           (let ((cmd (format "find . -name \"*.elc\" -delete && emacs -batch -f package-initialize -L . -L %s -f buttercup-run-discover %s </dev/null 2>&1"
                              quoted-dir quoted-dir)))
             (macher-agent-run-in-vfs-sandbox
              ctx cmd resolve
              (lambda (_code output)
                (if (string-match-p "\\([1-9][0-9]* failed\\|FAILED\\|Error:\\)" output)
                    output
                  (concat "SUCCESS: The tests ran perfectly with no errors.\n\n=== TEST OUTPUT ===\n" output)))))))))
