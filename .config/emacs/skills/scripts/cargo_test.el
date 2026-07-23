(macher-agent-make-tool macher-agent-cargo-test-tool
                        "Run 'cargo test' to test the project."
                        :category "rust"
                        :args nil
                        :command-fn (lambda (_payload _context _root)
                                      (make-macher-agent-process-response 
                                       :payload "rtk cargo test </dev/null 2>&1"))
                        :success-fn (lambda (output)
                                      (if (string-match-p "\\(test result: FAILED\\|error\\[\\)" output)
                                          output
                                        (concat "SUCCESS: The tests ran perfectly with no errors.\n\n=== TEST OUTPUT ===\n" output))))
