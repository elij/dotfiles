;; -*- lexical-binding: t; -*-

(require 'setup-macher-agent)

(use-package macher-agent-skills
  :ensure nil
  :vc (:url "https://github.com/elij/macher-agent"
       :lisp-dir "packages/macher-agent-skills"
       :rev :newest)
  :after macher-agent
  :preface
  (defun enable-default-agent-tools ()
    (dolist (tool-name '("get_current_datetime"))
      (when-let* ((tool (ignore-errors (gptel-get-tool tool-name))))
        (add-to-list 'gptel-tools tool))))
  :config
  (macher-agent-skills-install)
  (macher-agent-initialize-skills)
  ;;(add-hook 'macher-agent-before-restore-hook #'enable-default-agent-tools)
  (add-hook 'gptel-mode-hook #'enable-default-agent-tools 100))

(provide 'setup-macher-agent-skills)
