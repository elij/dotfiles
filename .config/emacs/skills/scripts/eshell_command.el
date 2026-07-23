(macher-agent-make-tool macher-agent-submit-eshell-command-tool
                        "Submit a command in an Eshell session. Use this tool to execute a command AFTER you have already written the command text to the shell buffer."
                        :category "system"
                        :args (list '(:name "buffer_name" 
                                            :type string 
                                            :description "The exact name of the eshell buffer where the command was written (e.g., \"*eshell*\")."))
                        :command-fn (lambda (payload _context _root)
                                      (let ((buf-name (plist-get payload :buffer_name)))
                                        (if-let* ((buf (get-buffer buf-name)))
                                            (with-current-buffer buf
                                              (if (derived-mode-p 'eshell-mode)
                                                  (progn
                                                    (goto-char (point-max))
                                                    (eshell-send-input)
                                                    (make-macher-agent-lisp-result-response 
                                                     :payload (format "Successfully submitted the command in Eshell buffer: %s" buf-name)))
                                                (make-macher-agent-lisp-result-response 
                                                 :payload (format "Error: Buffer '%s' exists but is not in eshell-mode." buf-name))))
                                          (make-macher-agent-lisp-result-response 
                                           :payload (format "Error: Could not find a buffer named '%s'." buf-name))))))
