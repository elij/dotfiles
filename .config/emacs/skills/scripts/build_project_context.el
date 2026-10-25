;;; build_project_context.el --- Project structural map tool -*- lexical-binding: t; -*-
(setq macher-agent-build-project-context-tool
      (gptel-make-tool
       :name "build_project_context"
       :description "Generate a read-only architectural map of the entire project. This returns structural context rather than compilable source code."
       :category "perception"
       :args nil
       :async t
       :function (lambda (callback)
                   (let ((thunk (funcall (get 'macher-agent-build-project-context-tool 'ptc-function))))
                     (funcall thunk callback)))))

(put 'macher-agent-build-project-context-tool 'ptc-function
     (lambda (&optional context _root)
       (let ((ctx (or context (current-buffer))))
         (lambda (resolve)
           (let ((cmd "context-builder -y -f rs --signatures --ignore external --input . -o /dev/stdout </dev/null 2>&1"))
             (macher-agent-run-in-vfs-sandbox
              ctx cmd resolve
              (lambda (code output)
                (if (or (/= code 0)
                        (string-prefix-p "Execution failed" output))
                    output
                  (when (fboundp 'macher-agent-add-pending-instruction)
                    (macher-agent-add-pending-instruction
                     "The following text is a read-only architectural map of the codebase. Do NOT write mock implementations for these signatures."))
                  output))))))))
