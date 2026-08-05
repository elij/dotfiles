(macher-agent-make-tool macher-agent-cargo-check-tool
    "Run 'cargo check' inside the VFS."
  :category "execution"
  :args nil
  :command-fn
  (lambda (_payload context _root)
    (macher-agent-call-with-strict-vfs-pipeline
     context
     (lambda ()
       (let ((cmd "find . -name \"Cargo.toml\" -exec dirname {} \\; | head -n 1 | xargs -I {} sh -c 'cd {} && cargo check 2>&1'"))
         (shell-command-to-string cmd)))))
  :success-fn
  (lambda (output)
    (if (string-match-p "\\(error:\\|could not compile\\)" output)
        output
      (concat "SUCCESS: Cargo check completed with no errors.\n\n=== OUTPUT ===\n" output))))
