(macher-agent-make-tool macher-agent-elisp-make-lint-tool
    "Run make lint in an Elisp project. You must use this tool to check lint and checkdoc tp changes made in the VFS with write to workspace tools. No other tool should be used for Elisp testsing."
  :category "execution"
  :args nil
  :command-fn
  (lambda (_payload context _root)
    (macher-agent-call-with-strict-vfs-pipeline
     context
     (lambda ()
       (let ((cmd "make lint </dev/null 2>&1"))
         (shell-command-to-string cmd)))))
  :success-fn
  (lambda (output)
    (if (string-match-p "\\([1-9][0-9]* failed\\|FAILED\\|Error:\\)" output)
        output
      (concat "SUCCESS: The lintss ran perfectly with no errors.\n\n=== LINT OUTPUT ===\n" output))))
