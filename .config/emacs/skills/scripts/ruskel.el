;;; ruskel.el --- Rust skeleton generation tool -*- lexical-binding: t; -*-

(setq macher-agent-ruskel-tool
      (gptel-make-tool
       :name "ruskel"
       :description "Generate Rust skeleton/signatures for a given file or module inside the VFS."
       :category "execution"
       :args '((:name "target" :type "string" :description "The Rust module or file target to generate signatures for"))
       :async t
       :function (lambda (callback target)
                   (let ((thunk (funcall (get 'macher-agent-ruskel-tool 'ptc-function)
                                         target)))
                     (funcall thunk callback)))))

(put 'macher-agent-ruskel-tool 'ptc-function
     (lambda (target &optional context _root)
       (let ((ctx (or context (current-buffer)))
             (run-fn (if (fboundp 'macher-agent-vfs-run-in-sandbox)
                         #'macher-agent-vfs-run-in-sandbox
                       #'macher-agent-run-in-vfs-sandbox)))
         (lambda (resolve)
           (let ((cmd (format
                       (concat
                        "toml=$(find . -name 'Cargo.toml' -print "
                        "| awk '{print length($0), $0}' | sort -n | head -n1 | cut -d' ' -f2-); "
                        "if [ -z \"$toml\" ]; then "
                        "  echo 'ERROR: No Cargo.toml found. The workspace is empty or invalid.'; exit 1; "
                        "fi; "
                        "cd \"$(dirname \"$toml\")\" && ruskel %s </dev/null 2>&1")
                       (shell-quote-argument target))))
             (funcall
              run-fn ctx cmd resolve
              (lambda (code output)
                (if (or (/= code 0)
                        (string-match-p "\\(error:\\|ERROR:\\|No such file\\)" output))
                    output
                  (concat "SUCCESS: Rust skeleton generated.\n\n=== RUSKEL OUTPUT ===\n" output)))))))))
