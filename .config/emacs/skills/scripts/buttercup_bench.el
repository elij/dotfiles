(macher-agent-make-tool macher-agent-buttercup-bench-tool
    "Run buttercup-run-discover to test the project benchmarks. You must use this tool to test changes made in the VFS with write to workspace tools"
  :category "compute"
  :args nil
  :command-fn (lambda (_payload _context _root)
                (make-macher-agent-process-response 
                 :payload "find . -name \"*.elc\" -delete && emacs -batch -f package-initialize -L . -L bench -l buttercup --eval '(let ((default-directory (expand-file-name \"bench/\"))) (buttercup-run-discover))' </dev/null 2>&1"))
  :success-fn (lambda (output)
                (if (string-match-p "\\([1-9][0-9]* failed\\|FAILED\\|Error:\\)" output)
                    output
                  (concat "SUCCESS: The benchmarks ran perfectly with no errors.\n\n=== TEST OUTPUT ===\n" output))))
