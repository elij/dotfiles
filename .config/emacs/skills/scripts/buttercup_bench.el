;;; buttercup_benchmarks.el --- Buttercup benchmark execution tool -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-buttercup-bench-tool
      (gptel-make-tool
       :name "run_buttercup_benchmarks"
       :description "Run buttercup performance benchmarks for the project inside the VFS."
       :category "execution"
       :args nil
       :async t
       :function (macher-agent-with-presentation-context ()
                   (let* ((native-fn (get 'macher-agent-buttercup-bench-tool 'ptc-function))
                          (root (or (and context (macher-agent-context-project-root context))
                                    default-directory)))
                     (funcall native-fn context root)))))

(put 'macher-agent-buttercup-bench-tool 'ptc-function
     (lambda (context _root)
       (let ((raw-output
              (macher-agent-call-with-strict-vfs-pipeline
               context
               (lambda ()
                 (let ((cmd "find . -name \"*.elc\" -delete && emacs -batch -f package-initialize -L . -f buttercup-run-benchmarks </dev/null 2>&1"))
                   (shell-command-to-string cmd))))))
         (if (string-match-p "\\(FAILED\\|Error:\\)" raw-output)
             raw-output
           (concat "SUCCESS: Benchmarks completed.\n\n=== BENCHMARK OUTPUT ===\n" raw-output)))))
