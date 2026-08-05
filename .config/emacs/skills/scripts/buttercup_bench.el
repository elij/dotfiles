(macher-agent-make-tool macher-agent-buttercup-bench-tool
    "Run buttercup performance benchmarks for the project inside the VFS."
  :category "execution"
  :args nil
  :command-fn
  (lambda (_payload context _root)
    (macher-agent-call-with-strict-vfs-pipeline
     context
     (lambda ()
       (let ((cmd "find . -name \"*.elc\" -delete && emacs -batch -f package-initialize -L . -f buttercup-run-benchmarks </dev/null 2>&1"))
         (shell-command-to-string cmd)))))
  :success-fn
  (lambda (output)
    (if (string-match-p "\\(FAILED\\Vert{}Error:\\)" output)
        output
      (concat "SUCCESS: Benchmarks completed.\n\n=== BENCHMARK OUTPUT ===\n" output))))
