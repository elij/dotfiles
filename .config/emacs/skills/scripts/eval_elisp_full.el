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
       :function (macher-agent-with-presentation-context (code)
                   (let ((native-fn (get 'macher-agent-eval-elisp-full-tool 'ptc-function)))
                     (funcall native-fn code context (and context (macher-agent-context-project-root context)))))))

(put 'macher-agent-eval-elisp-full-tool 'ptc-function
     (lambda (code _context _root)
       (let* ((code-string (or code ""))
              (temp-buffer (generate-new-buffer " *elisp-eval*"))
              (output ""))
         (unwind-protect
             (with-current-buffer temp-buffer
               (insert code-string)
               (eval-buffer)
               (setq output "SUCCESS: Buffer evaluated without errors."))
           (when (buffer-live-p temp-buffer)
             (kill-buffer temp-buffer)))
         output)))
