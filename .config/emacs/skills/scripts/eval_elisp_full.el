(macher-agent-make-tool macher-agent-eval-elisp-full-tool
    "Evaluate a full Emacs Lisp buffer string."
  :category "execution"
  :args (list (list :name "code" :type 'string :description "The full Emacs Lisp buffer string to evaluate"))
  :command-fn
  (lambda (payload _context _root)
    (let* ((code-string (plist-get payload :code))
           (temp-buffer (generate-new-buffer " *elisp-eval*"))
           (output ""))
      (unwind-protect
          (with-current-buffer temp-buffer
            (insert code-string)
            (eval-buffer)
            (setq output "SUCCESS: Buffer evaluated without errors."))
        (kill-buffer temp-buffer))
      output))
  :success-fn
  (lambda (output) output))
