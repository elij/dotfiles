;;; buttercup_test.el --- Buttercup test execution tool -*- lexical-binding: t; -*-
(setq macher-agent-buttercup-test-tool
      (gptel-make-tool
       :name "buttercup_test"
       :description "Run buttercup-run-discover to test the project. You must use this tool to test changes made in the VFS with write to workspace tools. No other tool should be used for Elisp testing."
       :category "execution"
       :args nil
       :async t
       :function (lambda (callback)
                   (let ((thunk (funcall (get 'macher-agent-buttercup-test-tool 'ptc-function))))
                     (funcall thunk callback)))))

(put 'macher-agent-buttercup-test-tool 'ptc-function
     (lambda (&optional context)
       (let ((ctx (or context (current-buffer))))
         (lambda (resolve)
           (let ((cmd "find . -name \"*.elc\" -delete && emacs -batch -f package-initialize -L . -L tests -f buttercup-run-discover </dev/null 2>&1"))
             (macher-agent-run-in-vfs-sandbox
              ctx cmd resolve
              (lambda (_code output)
                (if (string-match-p "\\([1-9][0-9]* failed\\|FAILED\\|Error:\\)" output)
                    output
                  (concat "SUCCESS: The tests ran perfectly with no errors.\n\n=== TEST OUTPUT ===\n" output)))))))))
