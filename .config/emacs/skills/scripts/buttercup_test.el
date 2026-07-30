(macher-agent-make-tool
    macher-agent-buttercup-test-tool
    "Run buttercup-run-discover to test the project. You must use this tool to test changes made in the VFS with write to workspace tools"
  :category "execution"
  :args nil
  :command-fn
  (lambda (_payload _context _root)
    (make-macher-agent-process-response
     :payload "find . -name \"*.elc\" -delete && emacs -batch -f package-initialize -L . -f buttercup-run-discover </dev/null 2>&1"))
  :success-fn
  (lambda (output)
    (if (string-match-p "\\([1-9][0-9]* failed\\|FAILED\\|Error:\\)" output)
        output
      (concat "SUCCESS: The tests ran perfectly with no errors.

=== TEST OUTPUT ===
" output))))
