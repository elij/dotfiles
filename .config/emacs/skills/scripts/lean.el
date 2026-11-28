;;; lean.el --- Lean4 proof tool -*- lexical-binding: t; -*-

(setq macher-agent-lean-tool
      (gptel-make-tool
       :name "lean"
       :description "Run a lean4 proof inside the VFS."
       :category "execution"
       :args '((:name "target" :type "string" :description "The lean4 module or file target"))
       :async t
       :function (lambda (callback target)
                   (let ((thunk (funcall (get 'macher-agent-lean-tool 'ptc-function)
                                         target)))
                     (funcall thunk callback)))))

(put 'macher-agent-lean-tool 'ptc-function
     (lambda (target &optional context _root)
       (let ((ctx (or context (current-buffer)))
             (run-fn (if (fboundp 'macher-agent-vfs-run-in-sandbox)
                         #'macher-agent-vfs-run-in-sandbox
                       #'macher-agent-run-in-vfs-sandbox)))
         (lambda (resolve)
           (let ((cmd (format "lean %s </dev/null 2>&1" (shell-quote-argument target))))
             (funcall
              run-fn ctx cmd resolve
              (lambda (code output)
                (if (or (/= code 0)
                        (string-match-p "\\(error:\\|No such file\\)" output))
                    output
                  (concat "SUCCESS: Lean proof ran.\n\n=== LEAN OUTPUT ===\n" output)))))))))
