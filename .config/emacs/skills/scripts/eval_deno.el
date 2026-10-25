;;; eval_deno.el --- Evaluate TypeScript and JavaScript via Deno inside VFS -*- lexical-binding: t; -*-
(setq macher-agent-eval-deno-tool
      (gptel-make-tool
       :name "eval_deno"
       :description "Evaluate TypeScript or JavaScript using Deno inside the VFS."
       :category "execution"
       :include nil
       :args '((:name "script" :type "string" :description "The JavaScript or TypeScript code to evaluate"))
       :async t
       :function (lambda (callback script)
                   (let ((thunk (funcall (get 'macher-agent-eval-deno-tool 'ptc-function)
                                         script)))
                     (funcall thunk callback)))))

(put 'macher-agent-eval-deno-tool 'ptc-function
     (lambda (script &optional context _root)
       (let ((ctx (or context (current-buffer))))
         (lambda (resolve)
           (let ((cmd (format "deno eval %s </dev/null 2>&1" (shell-quote-argument script))))
             (macher-agent-run-in-vfs-sandbox
              ctx cmd resolve
              (lambda (_code output)
                (concat "DENO OUTPUT:\n" output))))))))
