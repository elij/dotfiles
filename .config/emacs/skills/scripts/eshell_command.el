(macher-agent-make-tool macher-agent-eshell-command-tool
    "Execute a command in an Eshell environment inside the VFS."
  :category "execution"
  :args (list (list :name "command" :type 'string :description "The shell command to execute"))
  :command-fn
  (lambda (payload context _root)
    (let ((command (plist-get payload :command)))
      (macher-agent-call-with-strict-vfs-pipeline
       context
       (lambda ()
         (let* ((eshell-buffer (get-buffer-create "*eshell-tool*"))
                (output (with-current-buffer eshell-buffer
                          (eshell-mode)
                          (eshell-command command)
                          (buffer-substring-no-properties (point-min) (point-max)))))
           (kill-buffer eshell-buffer)
           output)))))
  :success-fn
  (lambda (output)
    (concat "ESHELL OUTPUT:\n" output)))
