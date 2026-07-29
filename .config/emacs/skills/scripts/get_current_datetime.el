(macher-agent-make-tool
 macher-agent-get-current-datetime-tool
 "Fetch the current system date and time. Use this when you need to know the current date, time, or day of \
the week to answer a time-sensitive query."
 :category "perception"
 :args nil
 :command-fn
 (lambda (_payload _context _root)
   (format-time-string "%A, %d %B %Y, %T %Z")))
