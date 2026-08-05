(macher-agent-make-tool macher-agent-buttercup-test-tool
    "Run buttercup-run-discover to test the project. You must use this tool to test changes made in the VFS with write to workspace tools"
  :category "execution"
  :args nil
  :command-fn
  (lambda (_payload context _root)
    (macher-agent-call-with-strict-vfs-pipeline
     context
     (lambda ()
       (let ((cmd "find . -name \"*.elc\" -delete && emacs -batch -f package-initialize -L . -f buttercup-run-discover </dev/null 2>&1"))
         (shell-command-to-string cmd)))))
  :success-fn
  (lambda (output)
    (if (string-match-p "\\([1-9][0-9]* failed\\|FAILED\\|Error:\\)" output)
        output
      (concat "SUCCESS: The tests ran perfectly with no errors.\n\n=== TEST OUTPUT ===\n" output))))
