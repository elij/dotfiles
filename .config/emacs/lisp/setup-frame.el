;; -*- lexical-binding: t; -*-

(use-package frame
  :ensure nil
  :defer t
  :preface
  (defun my/layout-new-frame (frame)
    (run-with-timer 0.05 nil
                    (lambda (f)
                      (when (and (frame-live-p f)
                                 (not (frame-parameter f 'parent-frame)))
                        (with-selected-frame f
                          (when (eq system-type 'darwin)
                            (set-frame-parameter f 'alpha-background 0.7)
                            (set-frame-parameter f 'ns-alpha-elements '(ns-alpha-all)))
                          (delete-other-windows)
                          (switch-to-buffer (get-buffer-create "*GNU Emacs*"))
                          (when-let* ((graphic (display-graphic-p f))
                                      (right-window (split-window-right)))
                            (set-window-buffer right-window (get-buffer-create "*scratch*"))
                            (balance-windows)))))
                    frame))
  :custom
  (ns-right-alternate-modifier 'none)
  :hook
  ((after-make-frame-functions . (lambda (f) 
                                   (when (display-graphic-p f) 
                                     (my/layout-new-frame f))))
   (window-setup . (lambda () 
                     (when (display-graphic-p) 
                       (my/layout-new-frame (selected-frame))))))
  :config
  (set-face-attribute 'default nil
                      :family "Iosevka Fixed"
                      :height 130
                      :weight 'normal))

(provide 'setup-frame)
