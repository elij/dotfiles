(macher-agent-make-tool
    macher-agent-build-project-context-tool
    "Generate a read-only architectural map of the entire project. This returns structural context rather than \
compilable source code."
  :category "perception"
  :args nil
  :command-fn
  (lambda (_payload context _root)
    (macher-agent-call-with-strict-vfs-pipeline
     context
     (lambda ()
       (let ((cmd "ontext-builder -y -f rs --signatures --ignore external --input . -o /dev/stdout </dev/null 2>&1"))
         (shell-command-to-string cmd)))))
  :success-fn
  (lambda (output)
    (unless (string-prefix-p "Execution failed" output)
      (macher-agent-add-pending-instruction
       "The following text is a read-only architectural map of the codebase. Do NOT write mock implementations \
for these signatures."))
    output))
