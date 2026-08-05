(macher-agent-make-tool macher-agent-cargo-test-tool
    "Run 'cargo test' inside the VFS."
  :category "execution"
  :args nil
  :command-fn
  (lambda (_payload context _root)
    (macher-agent-call-with-strict-vfs-pipeline
     context
     (lambda ()
       (let ((cmd "find . -name \"Cargo.toml\" -exec dirname {} \\; | head -n 1 | xargs -I {} sh -c 'cd {} && cargo test 2>&1'"))
         (shell-command-to-string cmd)))))
  :success-fn
  (lambda (output)
    (if (string-match-p "\\(FAILED\\|error:\\)" output)
        output
      (concat "SUCCESS: All tests passed.\n\n=== OUTPUT ===\n" output))))
