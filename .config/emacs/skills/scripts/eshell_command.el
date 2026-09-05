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
       :function (macher-agent-with-presentation-context (buffer_name command)
                   (let* ((native-fn (get 'macher-agent-eshell-command-tool 'ptc-function))
                          (root (or (and context (macher-agent-context-project-root context))
                                    default-directory)))
                     (funcall native-fn buffer_name command context root)))))

(put 'macher-agent-eshell-command-tool 'ptc-function
     (lambda (buffer-name command context _root)
       (let ((actual-name (macher-agent--resolve-buffer-name buffer-name)))
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
           (format "SUCCESS: Executed command '%s' in Eshell buffer '%s' and synchronised memory."
                   command
                   actual-name)))))
