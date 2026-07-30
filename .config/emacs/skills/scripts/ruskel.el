(macher-agent-make-tool
    macher-agent-ruskel-tool
    "Run ruskel to inspect the public API of a Rust crate."
  :category "perception"
  :args '((:name "crate_name" :type string :description "The name of the crate to inspect"))
  :command-fn (lambda (payload _context _root)
                (let ((crate (plist-get payload :crate_name)))
                  (make-macher-agent-process-response 
                   :payload (format "ruskel %s --no-page --color never </dev/null 2>&1"
                                    (shell-quote-argument crate))))))
