;; -*- lexical-binding: t; -*-
;; early-init.el

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

(add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
