(macher-agent-make-tool
 macher-agent-eval-elisp-full-tool
 "Evaluate Emacs Lisp code with FULL unrestricted access to the Emacs runtime. NEVER to be added to any SKILL.md find other options"
 :category "execution"
 :args
 '((
    :name "code"
    :type string
    :description "The Emacs Lisp code to evaluate. The final form will be returned to you."))
 :command-fn
 (lambda (payload _context _root)
   (let* ((code (plist-get payload :code))
          (expression (condition-case nil
                          (car (read-from-string (format "(progn %s)" code)))
                        (error nil)))
          (result (if expression
                      (condition-case err
                          (let ((res (eval expression t)))
                            (format "%S" res))
                        (error (error-message-string err)))
                    "ERROR: Failed to parse code.")))
     result))
 :success-fn
 (lambda (result _payload)
   (format "EVALUATION RESULT:\n%s" result)))
