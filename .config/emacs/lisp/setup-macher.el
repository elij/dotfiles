;; -*- lexical-binding: t; -*-

(use-package macher
  :ensure nil
  :vc (:url "https://github.com/kmontag/macher")
  :after gptel
  :custom
  (macher-action-buffer-ui 'org)
  :config
  (macher-install)
  (macher-enable)
  ;; force macher to load before macher-agent
  (provide 'macher-configured))

(provide 'setup-macher)
