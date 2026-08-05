(macher-agent-make-tool macher-agent-get-current-datetime-tool
    "Get the current system date and time."
  :category "execution"
  :args nil
  :command-fn
  (lambda (_payload _context _root)
    (current-time-string))
  :success-fn
  (lambda (output)
    (concat "Current Date/Time: " output)))
