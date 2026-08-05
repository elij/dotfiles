(macher-agent-make-tool macher-agent-eval-deno-tool
    "Evaluate TypeScript or JavaScript using Deno inside the VFS."
  :category "execution"
  :args (list (list :name "script" :type 'string :description "The JavaScript or TypeScript code to evaluate"))
  :command-fn
  (lambda (payload context _root)
    (let ((script (plist-get payload :script)))
      (macher-agent-call-with-strict-vfs-pipeline context
                                                  (lambda ()
                                                    (let ((cmd (format "deno eval %s 2>&1" (shell-quote-argument script))))
                                                      (shell-command-to-string cmd))))))
  :success-fn
  (lambda (output)
    (concat "DENO OUTPUT:\n" output)))
