;;; buttercup_benchmarks.el --- Buttercup benchmark execution tool -*- lexical-binding: t; -*-
(setq macher-agent-buttercup-bench-tool
      (gptel-make-tool
       :name "run_buttercup_benchmarks"
       :description "Run buttercup performance benchmarks for the project inside the VFS."
       :category "execution"
       :args nil
       :async t
       :function (lambda (callback)
                   (let ((thunk (funcall (get 'macher-agent-buttercup-bench-tool 'ptc-function))))
                     (funcall thunk callback)))))

(put 'macher-agent-buttercup-bench-tool 'ptc-function
     (lambda (&optional context _root)
       (let ((ctx (or context (current-buffer))))
         (lambda (resolve)
           (let ((cmd "find . -name \"*.elc\" -delete && emacs -batch -f package-initialize -L . -f buttercup-run-benchmarks </dev/null 2>&1"))
             (macher-agent-run-in-vfs-sandbox
              ctx cmd resolve
              (lambda (code output)
                (if (or (/= code 0)
                        (string-match-p "\\(FAILED\\|Error:\\)" output))
                    output
                  (concat "SUCCESS: Benchmarks completed.\n\n=== BENCHMARK OUTPUT ===\n" output)))))))))
```
