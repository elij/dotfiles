;;; ruskel.el --- Rust skeleton generation tool -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'subr-x)
(require 'macher-agent-core)
(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-ruskel-tool
      (gptel-make-tool
       :name "ruskel"
       :description "Generate Rust skeleton/signatures for a given file or module inside the VFS."
       :category "execution"
       :args '((:name "target" :type "string" :description "The Rust module or file target to generate signatures for"))
       :async t
       :function (macher-agent-with-presentation-context (target)
                   (let* ((native-fn (get 'macher-agent-ruskel-tool 'ptc-function))
                          (root (or (and context (macher-agent-context-project-root context))
                                    default-directory)))
                     (funcall native-fn target context root)))))

(put 'macher-agent-ruskel-tool 'ptc-function
     (lambda (target context _root)
       (let ((output
              (macher-agent-call-with-strict-vfs-pipeline
               context
               (lambda ()
                 (let ((cmd (format "find . -name \"Cargo.toml\" -exec dirname {} \\; | head -n 1 | xargs -I {} sh -c 'cd {} && ruskel %s 2>&1'"
                                    (shell-quote-argument target))))
                   (shell-command-to-string cmd))))))
         (if (string-match-p "\\(error:\\|No such file\\)" output)
             output
           (concat "SUCCESS: Rust skeleton generated.\n\n=== RUSKEL OUTPUT ===\n" output)))))
