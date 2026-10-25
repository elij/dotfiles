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
       (let ((ctx (or context (current-buffer))))
         (lambda (resolve)
           (let ((cmd (format "find . -name \"Cargo.toml\" -exec dirname {} \\; | head -n 1 | xargs -I {} sh -c 'cd {} && ruskel %s </dev/null 2>&1'"
                              (shell-quote-argument target))))
             (macher-agent-run-in-vfs-sandbox
              ctx cmd resolve
              (lambda (code output)
                (if (or (/= code 0)
                        (string-match-p "\\(error:\\|No such file\\)" output))
                    output
                  (concat "SUCCESS: Rust skeleton generated.\n\n=== RUSKEL OUTPUT ===\n" output)))))))))
