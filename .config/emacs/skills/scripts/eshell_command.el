;;; eshell_command.el --- Eshell command tool for Macher Agent -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'eshell)
(require 'macher-agent-core)
(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-eshell-command-tool
      (gptel-make-tool
       :name "eshell_command"
       :description "Executes a command in an existing Eshell buffer, submitting input, capturing output, and synchronising context immediately."
       :category "execution"
       :args '((:name "buffer_name"
                      :type "string"
                      :description "Name of the target Eshell buffer")
               (:name "command"
                      :type "string"
                      :description "The shell command to execute in Eshell"))
       :async t
       :function (macher-agent-with-presentation-context (buffer-name command)
                   (let ((native-fn (get 'macher-agent-eshell-command-tool 'ptc-function)))
                     (funcall native-fn buffer-name command context)))))

(put 'macher-agent-eshell-command-tool 'ptc-function
     (lambda (buffer-name command &optional context _root)
       (let* ((resolve-buf-fn (if (fboundp 'macher-agent-resolve-buffer-name)
                                  #'macher-agent-resolve-buffer-name
                                #'macher-agent--resolve-buffer-name))
              (ensure-acc-fn (if (fboundp 'macher-agent-vfs-ensure-access)
                                 #'macher-agent-vfs-ensure-access
                               #'macher-agent--ensure-access))
              (update-ctx-fn (if (fboundp 'macher-agent-vfs-update-context-file)
                                 #'macher-agent-vfs-update-context-file
                               #'macher-agent--update-context-file))
              (auto-sync-fn (if (fboundp 'macher-agent-vfs-auto-sync-context)
                                #'macher-agent-vfs-auto-sync-context
                              #'macher-agent--auto-sync-context))
              (ctx (or (macher-agent-resolve-context context)
                       (macher-agent-resolve-context (current-buffer))
                       (macher-agent-resolve-context nil)))
              (actual-name (funcall resolve-buf-fn buffer-name))
              (was-live (get-buffer actual-name))
              (target-buffer (or was-live (get-buffer-create actual-name)))
              (access-ok nil)
              (start-pos 1)
              (delta ""))
         (unwind-protect
             (progn
               (when (macher-agent-valid-context-p ctx)
                 (funcall ensure-acc-fn ctx actual-name))
               (setq access-ok t))
           (when (and (not access-ok)
                      (not was-live)
                      (buffer-live-p target-buffer))
             (kill-buffer target-buffer)))
         (with-current-buffer target-buffer
           (unless (derived-mode-p 'eshell-mode)
             (eshell-mode))
           (goto-char (point-max))
           (setq start-pos (point))
           (insert command)
           (eshell-send-input)
           (when (> (point-max) start-pos)
             (setq delta (string-trim (buffer-substring-no-properties start-pos (point-max))))))
         (when (macher-agent-valid-context-p ctx)
           (let ((full-content (with-current-buffer target-buffer
                                 (buffer-substring-no-properties (point-min) (point-max)))))
             (funcall update-ctx-fn ctx actual-name full-content)
             (funcall auto-sync-fn ctx)))
         (if (string-empty-p delta)
             (format "SUCCESS: Executed command '%s' in Eshell buffer '%s' and synchronised memory."
                     command actual-name)
           (format "SUCCESS: Executed command '%s' in Eshell buffer '%s'.\n\n=== ESHELL OUTPUT ===\n%s"
                   command actual-name delta)))))
