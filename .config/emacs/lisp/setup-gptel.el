;; -*- lexical-binding: t; -*-

(use-package gptel
  :ensure nil
  :vc (:url "https://github.com/karthink/gptel")
  :defer t
  :preface
  (defvar-local my-gptel--font-lock-state nil)
  (defvar-local my-gptel--font-lock-suspended-p nil)

  (defun my/gptel--suspend-font-lock ()
    (when font-lock-mode
      (setq my-gptel--font-lock-suspended-p t)
      (font-lock-mode -1)))

  (defun my/gptel--restore-font-lock (_beg _end)
    (when my-gptel--font-lock-suspended-p
      (setq my-gptel--font-lock-suspended-p nil)
      (when (buffer-live-p (current-buffer))
        (font-lock-mode 1))))
  
  (define-minor-mode gptel-performance-mode
    "Manage performance during asynchronous gptel generation."
    :init-value nil
    :lighter nil
    (if gptel-performance-mode
        (progn
          (add-hook 'gptel-pre-response-hook #'my/gptel--suspend-font-lock nil t)
          (add-hook 'gptel-post-response-functions #'my/gptel--restore-font-lock nil t))
      (remove-hook 'gptel-pre-response-hook #'my/gptel--suspend-font-lock t)
      (remove-hook 'gptel-post-response-functions #'my/gptel--restore-font-lock t)
      (when my-gptel--font-lock-suspended-p
        (setq my-gptel--font-lock-suspended-p nil)
        (when (buffer-live-p (current-buffer))
          (font-lock-mode 1)))))

  (defun my/set-gptel-default-model ()
    (if (executable-find "llama-server")
        (setq gptel-backend my-localai-backend 
              gptel-model 'qwen-35b)
      (setq gptel-backend my-gemini-backend 
            gptel-model 'gemini-flash-lite-latest)))

  :custom
  (gptel-include-reasoning t)
  (gptel-track-media t)

  :hook
  ((org-mode . gptel-performance-mode)
   (markdown-mode . gptel-performance-mode))
  
  :config
  (add-to-list 'gptel-prompt-prefix-alist '(markdown-ts-mode . "### "))
  (defvar my-gemini-backend
    (gptel-make-gemini "Gemini"
      :key (gptel-api-key-from-auth-source "generativelanguage.googleapis.com")
      :stream t))

  (defvar my-localai-backend
    (gptel-make-openai "LocalAi"
      :host "localhost:11434"
      :endpoint "/v1/chat/completions"
      :protocol "http"
      :stream t
      :key "dummy"
      :request-params '(:thinking :json-false)
      :models '(
                (gemma4-e2b)
                (qwen-27b)
                (qwen-35b
                 :capabilities (media)
                 :mime-types ("image/jpeg" "image/png" "image/gif" "image/webp")))))
  
  (my/set-gptel-default-model))

(provide 'setup-gptel)
