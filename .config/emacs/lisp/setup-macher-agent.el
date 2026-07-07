;; -*- lexical-binding: t; -*-

(use-package macher-agent
  :ensure nil
  :vc (:url "https://github.com/elij/macher-agent")
  :after macher-configured
  :preface
  (defun my-macher-show-agent-window (buf)
    (let* ((buffer (get-buffer buf))
           (window (when buffer (display-buffer buffer '(display-buffer-below-selected (window-height . 5) (dedicated . t))))))
      (when window (set-window-point window (with-current-buffer buffer (point-max))))))

  (defun my-macher-hide-agent-window (buf)
    (let ((win (get-buffer-window buf)))
      (when win (delete-window win))))
  :custom
  (macher-agent-skill-directories (list (expand-file-name "skills" user-emacs-directory)))
  (macher-agent-display-subagent-fn #'my-macher-show-agent-window)
  (macher-agent-hide-subagent-fn #'my-macher-hide-agent-window)
  (macher-agent-initialize-skills)
  :config
  (when-let* ((default-val (alist-get 'default gptel-directives))
              (default-prompt (if (listp default-val) (plist-get default-val :system) default-val)))
    (setq-default gptel-system-prompt default-prompt)))

(provide 'setup-macher-agent)
