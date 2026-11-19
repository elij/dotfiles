;;; eval_elisp_full.el --- Evaluate Emacs Lisp tool -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'subr-x)
(require 'macher-agent-tools)

(setq macher-agent-eval-elisp-full-tool
      (gptel-make-tool
       :name "eval_elisp_full"
       :description "Evaluate Emacs Lisp code inside the live running Emacs session, with direct access to open buffers, buffer-local variables, hooks, advices, and active runtime state."
       :category "execution"
       :include nil
       :args '((:name "code" :type "string" :description "Emacs Lisp expression(s) to read and evaluate sequentially in the live Emacs session."))
       :async t
       :function (lambda (callback code)
                   (let ((thunk (funcall (get 'macher-agent-eval-elisp-full-tool 'ptc-function)
                                         code)))
                     (funcall thunk callback)))))

(put 'macher-agent-eval-elisp-full-tool 'ptc-function
     (lambda (code &optional _context _root)
       (lambda (resolve-fn)
         (let ((caller-buf (current-buffer))
               (code-string (or code ""))
               (forms nil)
               (result nil)
               (msg-buffer (messages-buffer))
               (eval-fn (intern "eval")))
           (condition-case err
               (progn
                 ;; Parse all forms up front so syntax errors and runtime EOF never collide
                 (with-temp-buffer
                   (insert code-string)
                   (goto-char (point-min))
                   (let ((done nil))
                     (while (not done)
                       (skip-chars-forward " \t\n\r\f")
                       (while (looking-at ";")
                         (forward-line 1)
                         (skip-chars-forward " \t\n\r\f"))
                       (if (eobp)
                           (setq done t)
                         (push (read (current-buffer)) forms)))))
                 (setq forms (nreverse forms))
                 (let* ((msg-start (with-current-buffer msg-buffer (point-max)))
                        (message-log-max t)
                        (inhibit-message t)
                        (std-out
                         (with-output-to-string
                           (with-current-buffer caller-buf
                             (dolist (form forms)
                               (setq result (funcall eval-fn form t))))))
                        (msg-text (with-current-buffer msg-buffer
                                    (when (> (point-max) msg-start)
                                      (string-trim-right
                                       (buffer-substring-no-properties msg-start (point-max))
                                       "\n"))))
                        (out-text (string-join
                                   (delq nil (list (and msg-text (not (string-empty-p msg-text)) msg-text)
                                                   (and (not (string-empty-p std-out))
                                                        (string-trim-right std-out "\n"))))
                                   "\n"))
                        (res-text (let ((print-circle t))
                                    (unless (and msg-text (equal (format "%s" result) msg-text))
                                      (prin1-to-string result))))
                        (raw-output
                         (cond
                          ((and (not (string-empty-p out-text)) res-text (not (null result)))
                           (format "%s\n%s" out-text res-text))
                          ((not (string-empty-p out-text)) out-text)
                          (t (or res-text "nil"))))
                        (max-chars (bound-and-true-p macher-agent-max-tool-output-chars))
                        (final-output
                         (if (and (integerp max-chars) (> (length raw-output) max-chars))
                             (let ((half (/ max-chars 2)))
                               (format "%s\n\n[... TRUNCATED %d CHARS ...]\n\n%s"
                                       (substring raw-output 0 half)
                                       (- (length raw-output) max-chars)
                                       (substring raw-output (- (length raw-output) half))))
                           raw-output)))
                   (funcall resolve-fn final-output)))
             (error
              (funcall resolve-fn
                       (format "ERROR (%S): %s" (car err) (error-message-string err)))))))))
