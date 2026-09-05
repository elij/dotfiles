;;; eval_deno.el --- Evaluate TypeScript and JavaScript via Deno inside VFS -*- lexical-binding: t; -*-

(require 'gptel)
(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-eval-deno-tool
      (gptel-make-tool
       :name "eval_deno"
       :description "Evaluate TypeScript or JavaScript using Deno inside the VFS."
       :category "execution"
       :include nil
       :args '((:name "script" :type "string" :description "The JavaScript or TypeScript code to evaluate"))
       :async t
       :function (macher-agent-with-presentation-context (script)
                   (let* ((native-fn (get 'macher-agent-eval-deno-tool 'ptc-function))
                          (root (or (and context (macher-agent-context-project-root context))
                                    default-directory)))
                     (funcall native-fn script context root)))))

(put 'macher-agent-eval-deno-tool 'ptc-function
     (lambda (script context _root)
       (let ((output
              (macher-agent-call-with-strict-vfs-pipeline
               context
               (lambda ()
                 (let ((cmd (format "deno eval %s 2>&1" (shell-quote-argument script))))
                   (shell-command-to-string cmd))))))
         (concat "DENO OUTPUT:\n" output))))
