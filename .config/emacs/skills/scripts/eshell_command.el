(macher-agent-make-tool
 macher-agent-eshell-command-tool
 "Executes a command in an Eshell buffer, submitting input and synchronising context immediately."
 :category "execution"
 :args (list '(:name "buffer_name" :type string)
             '(:name "command" :type string))
 :command-fn
 (lambda (payload context _root)
   (let* ((buffer-name (plist-get payload :buffer_name))
          (command (plist-get payload :command))
          (actual-name (macher-agent--resolve-buffer-name buffer-name)))
     (macher-agent--ensure-access context actual-name)
     (let ((target-buffer (get-buffer-create actual-name)))
       (with-current-buffer target-buffer
         (unless (derived-mode-p 'eshell-mode)
           (eshell-mode))
         (goto-char (point-max))
         (insert command)
         (eshell-send-input))
       (when context
         (let ((full-content (with-current-buffer target-buffer
                               (buffer-substring-no-properties (point-min) (point-max)))))
           (macher-agent--update-context-file context actual-name full-content)
           (macher-agent--auto-sync-context context)))
       `((status . "success") (buffer . ,actual-name) (command . ,command)))))
 :success-fn
 (lambda (res _payload)
   (format "SUCCESS: Executed command '%s' in Eshell buffer '%s' and synchronised memory."
           (cdr (assoc 'command res))
           (cdr (assoc 'buffer res)))))
