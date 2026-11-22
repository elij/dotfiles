;;; early-init.el --- Early initialization -*- lexical-binding: t; -*-

(if (eq system-type 'android)
    (let ((termux-bin "/data/data/com.termux/files/usr/bin")
          (termux-lib "/data/data/com.termux/files/usr/lib")
          (current-path (getenv "PATH"))
          (current-ld (getenv "LD_LIBRARY_PATH")))
      (setenv "PATH"
              (if (and current-path (not (string-empty-p current-path)))
                  (concat termux-bin ":" current-path)
                termux-bin))
      (setenv "LD_LIBRARY_PATH"
              (if (and current-ld (not (string-empty-p current-ld)))
                  (concat termux-lib ":" current-ld)
                termux-lib))
      (add-to-list 'exec-path termux-bin))

  (push '(menu-bar-lines . 0) default-frame-alist)
  (push '(tool-bar-lines . 0) default-frame-alist)
  (push '(vertical-scroll-bars . nil) default-frame-alist)

  (setq menu-bar-mode nil
        tool-bar-mode nil
        scroll-bar-mode nil)

  (setq frame-background-mode 'dark)

  (add-to-list 'default-frame-alist '(font . "Iosevka Fixed-13"))
  (add-to-list 'default-frame-alist '(width . 200))
  (add-to-list 'default-frame-alist '(height . 60))
  (add-to-list 'initial-frame-alist '(width . 200))
  (add-to-list 'initial-frame-alist '(height . 60))

  (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t)))

;;; early-init.el ends here
