;;; elisp_make_lint.el --- Elisp project make lint tool -*- lexical-binding: t; -*-
(setq macher-agent-elisp-make-lint-tool
      (gptel-make-tool
       :name "elisp_make_lint"
       :description "Run make lint in an Elisp project. You must use this tool to check lint and checkdoc to changes made in the VFS with write to workspace tools. No other tool should be used for Elisp testing."
       :category "execution"
       :args nil
       :async t
       :function (lambda (callback)
                   (let ((thunk (funcall (get 'macher-agent-elisp-make-lint-tool 'ptc-function))))
                     (funcall thunk callback)))))

(put 'macher-agent-elisp-make-lint-tool 'ptc-function
     (lambda (&optional context _root)
       (let ((ctx (or context (current-buffer))))
         (lambda (resolve)
           (let ((cmd "make lint </dev/null 2>&1"))
             (macher-agent-run-in-vfs-sandbox
              ctx cmd resolve
              (lambda (code output)
                (if (or (/= code 0)
                        (string-match-p "\\([1-9][0-9]* failed\\|FAILED\\|Error:\\)" output))
                    output
                  (concat "SUCCESS: The lints ran with zero errors.\n\n=== LINT OUTPUT ===\n" output)))))))))
