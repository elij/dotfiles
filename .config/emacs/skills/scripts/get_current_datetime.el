;;; get_current_datetime.el --- Current date and time tool -*- lexical-binding: t; -*-

(require 'macher-agent-tools)

(setq macher-agent-get-current-datetime-tool
      (gptel-make-tool
       :name "get_current_datetime"
       :description "Get the current system date and time."
       :category "execution"
       :args nil
       :async t
       :function (lambda (callback)
                   (let ((thunk (funcall (get 'macher-agent-get-current-datetime-tool 'ptc-function))))
                     (funcall thunk callback)))))

(put 'macher-agent-get-current-datetime-tool 'ptc-function
     (lambda (&optional _payload _context _root)
       (lambda (resolve-fn)
         (funcall resolve-fn (concat "Current Date/Time: " (current-time-string))))))
