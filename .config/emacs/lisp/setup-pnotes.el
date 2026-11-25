;; -*- lexical-binding: t; -*-

(use-package pnotes
  :ensure nil
  :vc (:url "https://github.com/elij/pnotes")
  :defer t
  :preface
  (defun my-pnotes-layout ()
    "Open the default PNotes workspace layout."
    (interactive)
    (delete-other-windows)
    (pnotes-daily)
    (pnotes-speedbar-open "PNotes")
    (pnotes-graph)
    (select-window (pnotes--main-window)))
  :config
  (defcustom pnotes-graph-max-distance 1
    "Integer hop limit for local graphs, or nil for the full repository graph."
    :type '(choice (const :tag "Full graph" nil) integer)
    :group 'pnotes)
  (keymap-set pnotes-command-map "l" #'my-pnotes-layout))

(provide 'setup-pnotes)
