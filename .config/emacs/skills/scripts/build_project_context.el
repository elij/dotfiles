(macher-agent-make-tool macher-agent-build-project-context-tool
                        "Generate a read-only architectural map of the entire project. This returns structural context rather than compilable source code."
                        :category "context-builder"
                        :args nil
                        :command-fn (lambda (_payload)
                                      (make-macher-agent-process-response 
                                       :payload "context-builder -y -f rs --signatures --ignore external --input . -o /dev/stdout </dev/null 2>&1"))
                        :success-fn (lambda (output)
                                      (unless (string-prefix-p "Execution failed" output)
                                        (macher-agent-add-pending-instruction
                                         "The following text is a read-only architectural map of the codebase. Do NOT write mock implementations for these signatures."))
                                      output))
