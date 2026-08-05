(macher-agent-make-tool macher-agent-ruskel-tool
    "Generate Rust skeleton/signatures for a given file or module inside the VFS."
  :category "execution"
  :args (list (list :name "target" :type 'string :description "The Rust module or file target to generate signatures for"))
  :command-fn
  (lambda (payload context _root)
    (let ((target (plist-get payload :target)))
      (macher-agent-call-with-strict-vfs-pipeline
       context
       (lambda ()
         (let ((cmd (format "find . -name \"Cargo.toml\" -exec dirname {} \\; | head -n 1 | xargs -I {} sh -c 'cd {} && ruskel %s 2>&1'"
                            (shell-quote-argument target))))
           (shell-command-to-string cmd))))))
  :success-fn
  (lambda (output)
    (if (string-match-p "\\(error:\\|No such file\\)" output)
        output
      (concat "SUCCESS: Rust skeleton generated.\n\n=== RUSKEL OUTPUT ===\n" output))))
