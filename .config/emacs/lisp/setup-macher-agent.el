;; -*- lexical-binding: t; -*-

(require 'setup-macher)

(use-package macher-agent
  :ensure nil
  :vc (:url "https://github.com/elij/macher-agent"
       :lisp-dir "packages/macher-agent"
       :rev :newest)
  :after macher-configured
  :preface
  (defun my/macher-show-agent-window (buf)
    (when-let*
        ((buffer (get-buffer buf))
         (window (display-buffer buffer '(display-buffer-below-selected
                                          (window-height . 5)
                                          (dedicated . t)))))
      (set-window-point window (with-current-buffer buffer (point-max)))))

  (defun my/macher-hide-agent-window (buf)
    (when-let* ((win (get-buffer-window buf)))
      (delete-window win)))

  :custom
  (macher-agent-skill-directories (list (expand-file-name "skills" user-emacs-directory)))
  (macher-agent-harness-issue-log-file (expand-file-name "harness-issues.md" user-emacs-directory))
  (macher-agent-display-subagent-fn #'my/macher-show-agent-window)
  (macher-agent-hide-subagent-fn #'my/macher-hide-agent-window)
  (macher-agent-max-context-chars
   '((qwen-35b . 32768)
     (gemini-flash-latest . 1000000)
     (gemini-3.1-pro-preview . 1000000)
     (gemini-flast-lite-last . 1000000)
     (nil . 2000000)))
  :config
  (macher-agent-install)
  (macher-agent-initialize-skills)
  (add-hook 'gptel-mode-hook #'macher-agent-mode)
  (when-let*
      ((default-val (alist-get 'default gptel-directives))
       (default-prompt (if (listp default-val)
                           (plist-get default-val :system)
                         default-val)))
    (setq-default gptel-system-prompt default-prompt)))

(use-package macher-agent-wire
  :ensure nil
  :vc (:url "https://github.com/elij/macher-agent"
       :lisp-dir "packages/macher-agent-wire"
       :rev :newest)
  :after macher-agent
  :config
  (macher-agent-wire-install))

(use-package macher-agent-zero-mem
  :ensure nil
  :vc (:url "https://github.com/elij/macher-agent"
       :lisp-dir "packages/macher-agent-zero-mem"
       :rev :newest)
  :after macher-agent
  :config
  (macher-agent-zero-mem-install))

(use-package macher-agent-sandbox
  :ensure nil
  :vc (:url "https://github.com/elij/macher-agent"
       :lisp-dir "packages/macher-agent-sandbox"
       :rev :newest)
  :after macher-agent
  :config
  (macher-agent-sandbox-install))

(use-package macher-agent-vfs
  :ensure nil
  :vc (:url "https://github.com/elij/macher-agent"
       :lisp-dir "packages/macher-agent-vfs"
       :rev :newest)
  :after (macher-agent macher-agent-sandbox)
  :config
  (macher-agent-vfs-install)
  (macher-agent-initialize-skills))

(provide 'setup-macher-agent)
