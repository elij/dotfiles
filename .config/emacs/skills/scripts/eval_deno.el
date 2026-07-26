(macher-agent-make-tool macher-agent-eval-deno-tool
    "Evaluate JavaScript or TypeScript code to perform maths operations, string manipulation, or data generation."
  :category "compute"
  :args '((:name "code" :type string :description "The JavaScript or TypeScript code to evaluate. Use console.log() to output the final result."))
  
  :command-fn (lambda (payload _context _root)
                (let* ((code (plist-get payload :code))
                       (temp-file (make-temp-file "macher-eval-" nil ".ts")))
                  
                  (with-temp-file temp-file
                    (insert code))
                  
                  (unwind-protect
                      (with-temp-buffer
                        (call-process "deno" nil t nil "run" temp-file)
                        (string-trim (buffer-string)))
                    (delete-file temp-file))))
  
  :success-fn (lambda (result _payload)
                (format "EVALUATION RESULT:\n%s" result)))
