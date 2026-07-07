;; -*- lexical-binding: t; -*-

(use-package calendar
  :ensure nil
  :defer t
  :config
  (calendar-set-date-style 'european))

(provide 'setup-calendar)
