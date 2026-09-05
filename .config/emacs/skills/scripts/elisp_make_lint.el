;;; elisp_make_lint.el --- Elisp project make lint tool -*- lexical-binding: t; -*-

(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-elisp-make-lint-tool
      (gptel-make-tool
       :name "elisp_make_lint"
       :description "Run make lint in an Elisp project. You must use this tool to check lint and checkdoc to changes made in the VFS with write to workspace tools. No other tool should be used for Elisp testing."
       :category "execution"
       :args nil
       :async t
       :function (macher-agent-with-presentation-context ()
                   (let* ((native-fn (get 'macher-agent-elisp-make-lint-tool 'ptc-function))
                          (root (or (and context (macher-agent-context-project-root context))
                                    default-directory)))
                     (funcall native-fn context root)))))

(put 'macher-agent-elisp-make-lint-tool 'ptc-function
     (lambda (context _root)
       (let ((output
              (macher-agent-call-with-strict-vfs-pipeline
               context
               (lambda ()
                 (let ((cmd "make lint </dev/null 2>&1"))
                   (shell-command-to-string cmd))))))
         (if (string-match-p "\\([1-9][0-9]* failed\\|FAILED\\|Error:\\)" output)
             output
           (concat "SUCCESS: The lints ran with zero errors.\n\n=== LINT OUTPUT ===\n" output)))))
