;;; get_current_datetime.el --- Current date and time tool -*- lexical-binding: t; -*-

(require 'macher-agent-tools)

(setq macher-agent-get-current-datetime-tool
      (gptel-make-tool
       :name "get_current_datetime"
       :description "Get the current system date and time."
       :category "execution"
       :args nil
       :async t
       :function (macher-agent-with-presentation-context ()
                   (let* ((native-fn (get 'macher-agent-get-current-datetime-tool 'ptc-function))
                          (root (or (and context (macher-agent-context-project-root context))
                                    default-directory))
                          (raw-output (funcall native-fn nil context root)))
                     (concat "Current Date/Time: " raw-output)))))

(put 'macher-agent-get-current-datetime-tool 'ptc-function
     (lambda (_payload _context _root)
       (current-time-string)))
