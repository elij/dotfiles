;;; eshell_command.el --- Eshell command tool for Macher Agent -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'eshell)
(require 'macher-agent-core)
(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-eshell-command-tool
      (gptel-make-tool
       :name "eshell_command"
       :description "Executes a command in an Eshell buffer, submitting input and synchronising context immediately."
       :category "execution"
       :args '((:name "buffer_name"
                      :type "string"
                      :description "Name of the target Eshell buffer")
               (:name "command"
                      :type "string"
                      :description "The shell command to execute in Eshell"))
       :async t
       :function (lambda (callback buffer_name command)
                   (let ((thunk (funcall (get 'macher-agent-eshell-command-tool 'ptc-function)
                                         buffer_name command)))
                     (funcall thunk callback)))))

(put 'macher-agent-eshell-command-tool 'ptc-function
     (lambda (buffer-name command &optional context _root)
       (let ((ctx (or (macher-agent-resolve-context context)
                      (macher-agent-resolve-context (current-buffer)))))
         (lambda (resolve-fn)
           (condition-case err
               (let ((actual-name (macher-agent--resolve-buffer-name buffer-name)))
                 (when (macher-agent-valid-context-p ctx)
                   (macher-agent--ensure-access ctx actual-name))
                 (let ((target-buffer (get-buffer-create actual-name)))
                   (with-current-buffer target-buffer
                     (unless (derived-mode-p 'eshell-mode)
                       (eshell-mode))
                     (goto-char (point-max))
                     (insert command)
                     (eshell-send-input))
                   (when (macher-agent-valid-context-p ctx)
                     (let ((full-content (with-current-buffer target-buffer
                                           (buffer-substring-no-properties (point-min) (point-max)))))
                       (macher-agent--update-context-file ctx actual-name full-content)
                       (macher-agent--auto-sync-context ctx)))
                   (funcall resolve-fn
                            (format "SUCCESS: Executed command '%s' in Eshell buffer '%s' and synchronised memory."
                                    command
                                    actual-name))))
             (error
              (funcall resolve-fn
                       (format "ERROR: Failed to execute command in Eshell buffer: %s"
                               (error-message-string err)))))))))
