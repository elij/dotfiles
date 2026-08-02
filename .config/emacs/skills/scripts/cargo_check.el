(macher-agent-make-tool
    macher-agent-cargo-check-tool
    "Run 'cargo check' to compile the project. This is used to ensure code is correct by \
coders"
  :category "execution"
  :args nil
  :command-fn
  (lambda (_payload _context _root)
    (make-macher-agent-process-response
     :payload "rtk cargo check </dev/null 2>&1"))
  :success-fn
  (lambda (output)
    (if (string-match-p "error\\[" output)
        output
      (concat "SUCCESS: The code compiled perfectly with no errors.
=== COMPILER OUTPUT ===
" output))))
