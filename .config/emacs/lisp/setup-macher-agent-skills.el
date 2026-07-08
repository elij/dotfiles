;; -*- lexical-binding: t; -*-

(use-package macher-agent-skills
  :ensure nil
  :vc (:url "https://github.com/elij/macher-agent-skills")
  :after macher-agent
  :preface
  (defun enable-default-agent-tools ()
    (dolist (tool-name '("get_current_datetime" "eval_elisp"))
      (when-let* ((tool (ignore-errors (gptel-get-tool tool-name))))
        (add-to-list 'gptel-tools tool))))
  :config
  (add-hook 'gptel-mode-hook #'enable-default-agent-tools 100))

(provide 'setup-macher-agent-skills)
