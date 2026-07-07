;; -*- lexical-binding: t; -*-

(use-package exec-path-from-shell
  :demand t
  :preface
  (defun chomp (str)
    (replace-regexp-in-string (rx (* (any " \t\n")) eos) "" str))
  
  (defun my/init-gpg-agent ()
    "Safely resolve GPG/SSH environments globally."
    (let ((ssh-auth-sock (chomp (shell-command-to-string "gpgconf --list-dirs agent-ssh-socket")))
          (gpg-agent-info (chomp (shell-command-to-string "gpgconf --list-dirs agent-info"))))
      (setenv "SSH_AUTH_SOCK" ssh-auth-sock)
      (setenv "GPG_AGENT_INFO" gpg-agent-info)))
  (defun my/start-local-llama-server ()
    (let ((process-name "llama-server")
          (buffer-name "*llama-server-log*"))
      (if (get-process process-name)
          (message "Local llama-server is already running.")
        (let ((process (start-process process-name buffer-name "llama-server" "--port" "11434" "-c" "65536" "-ngl" "99" "--models-preset" (expand-file-name "~/.llama-models.ini"))))
          (set-process-query-on-exit-flag process nil)
          (message "Started local llama-server in background buffer %s using router mode." buffer-name)))))

  :hook
  ((emacs-startup . (lambda () (when (executable-find "llama-server") (my/start-local-llama-server))))
   (kill-emacs . (lambda () (when-let* ((proc (get-process "llama-server"))) (message "Shutting down local llama-server...") (kill-process proc)))))
  :custom
  (exec-path-from-shell-arguments '("-l"))
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize))
  (when (executable-find "gpgconf")
    (my/init-gpg-agent))
  (run-with-idle-timer 2.0 nil (lambda () 
                                 (when (executable-find "llama-server") 
                                   (my/start-local-llama-server)))))

(provide 'setup-exec-path-from-shell)
