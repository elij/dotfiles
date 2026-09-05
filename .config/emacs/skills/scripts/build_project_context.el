;;; build_project_context.el --- Project structural map tool -*- lexical-binding: t; -*-

(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-build-project-context-tool
      (gptel-make-tool
       :name "build_project_context"
       :description "Generate a read-only architectural map of the entire project. This returns structural context rather than compilable source code."
       :category "perception"
       :args nil
       :async t
       :function (macher-agent-with-presentation-context ()
                   (let* ((native-fn (get 'macher-agent-build-project-context-tool 'ptc-function))
                          (root (or (and context (macher-agent-context-project-root context))
                                    default-directory)))
                     (funcall native-fn context root)))))

(put 'macher-agent-build-project-context-tool 'ptc-function
     (lambda (context _root)
       (let ((output
              (macher-agent-call-with-strict-vfs-pipeline
               context
               (lambda ()
                 (let ((cmd "context-builder -y -f rs --signatures --ignore external --input . -o /dev/stdout </dev/null 2>&1"))
                   (shell-command-to-string cmd))))))
         (unless (string-prefix-p "Execution failed" output)
           (when (fboundp 'macher-agent-add-pending-instruction)
             (macher-agent-add-pending-instruction
              "The following text is a read-only architectural map of the codebase. Do NOT write mock implementations for these signatures.")))
         output)))
