;;; eval_elisp_full.el --- Evaluate Emacs Lisp tool -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'subr-x)
(require 'macher-agent-tools)

(setq macher-agent-eval-elisp-full-tool
      (gptel-make-tool
       :name "eval_elisp_full"
       :description "Evaluate a full Emacs Lisp buffer string."
       :category "execution"
       :args '((:name "code" :type "string" :description "The full Emacs Lisp buffer string to evaluate"))
       :async t
       :function (lambda (callback code)
                   (let ((thunk (funcall (get 'macher-agent-eval-elisp-full-tool 'ptc-function)
                                         code)))
                     (funcall thunk callback)))))

(put 'macher-agent-eval-elisp-full-tool 'ptc-function
     (lambda (code &optional _context _root)
       (lambda (resolve-fn)
         (let* ((code-string (or code ""))
                (temp-buffer (generate-new-buffer " *elisp-eval*")))
           (condition-case err
               (unwind-protect
                   (with-current-buffer temp-buffer
                     (insert code-string)
                     (eval-buffer)
                     (funcall resolve-fn "SUCCESS: Buffer evaluated without errors."))
                 (when (buffer-live-p temp-buffer)
                   (kill-buffer temp-buffer)))
             (error
              (when (buffer-live-p temp-buffer)
                (kill-buffer temp-buffer))
              (funcall resolve-fn (format "ERROR: Failed to evaluate buffer: %s"
                                          (error-message-string err)))))))))
