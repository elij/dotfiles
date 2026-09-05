;;; buttercup_test.el --- Buttercup test execution tool -*- lexical-binding: t; -*-

(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-buttercup-test-tool
      (gptel-make-tool
       :name "buttercup_test"
       :description "Run buttercup-run-discover to test the project. You must use this tool to test changes made in the VFS with write to workspace tools. No other tool should be used for Elisp testing."
       :category "execution"
       :args nil
       :async t
       :function (macher-agent-with-presentation-context ()
                   (let ((native-fn (get 'macher-agent-buttercup-test-tool 'ptc-function)))
                     (funcall native-fn context)))))

(put 'macher-agent-buttercup-test-tool 'ptc-function
     (lambda (context)
       (let ((output
              (macher-agent-call-with-strict-vfs-pipeline
               context
               (lambda ()
                 (let ((cmd "find . -name \"*.elc\" -delete && emacs -batch -f package-initialize -L . -f buttercup-run-discover </dev/null 2>&1"))
                   (shell-command-to-string cmd))))))
         (if (string-match-p "\\([1-9][0-9]* failed\\|FAILED\\|Error:\\)" output)
             output
           (concat "SUCCESS: The tests ran perfectly with no errors.\n\n=== TEST OUTPUT ===\n" output)))))
