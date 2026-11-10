;;; eval_elisp_full.el --- Evaluate Emacs Lisp tool -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'subr-x)
(require 'macher-agent-tools)

(setq macher-agent-eval-elisp-full-tool
      (gptel-make-tool
       :name "eval_elisp_full"
       :description "Evaluate a full Emacs Lisp buffer string."
       :category "execution"
       :args '((:name "code" :type "string" :description "The full Emacs Lisp buffer string to evaluate"))
       :async t
       :function (lambda (callback code)
                   (let ((thunk (funcall (get 'macher-agent-eval-elisp-full-tool 'ptc-function)
                                         code)))
                     (funcall thunk callback)))))

(put 'macher-agent-eval-elisp-full-tool 'ptc-function
     (lambda (code &optional _context _root)
       (lambda (resolve-fn)
         (let ((code-string (or code ""))
               (result nil)
               (msg-buffer (messages-buffer)))
           (condition-case err
               (let ((msg-start (with-current-buffer msg-buffer (point-max)))
                     (message-log-max t)
                     (inhibit-message t))
                 (let ((std-out
                        (with-output-to-string
                          (with-temp-buffer
                            (insert code-string)
                            (goto-char (point-min))
                            (condition-case nil
                                (while t
                                  (setq result (funcall (intern "eval") (read (current-buffer)) t)))
                              (end-of-file nil))))))
                   (let* ((msg-text (with-current-buffer msg-buffer
                                      (when (> (point-max) msg-start)
                                        (string-trim-right
                                         (buffer-substring-no-properties msg-start (point-max))
                                         "\n"))))
                          (out-text (string-join
                                     (delq nil (list (and msg-text (not (string-empty-p msg-text)) msg-text)
                                                     (and (not (string-empty-p std-out))
                                                          (string-trim-right std-out "\n"))))
                                     "\n"))
                          (res-text (unless (equal (format "%s" result) msg-text)
                                      (prin1-to-string result))))
                     (funcall resolve-fn
                              (cond
                               ((and (not (string-empty-p out-text)) res-text (not (null result)))
                                (format "%s\n%s" out-text res-text))
                               ((not (string-empty-p out-text)) out-text)
                               (t (or res-text "nil")))))))
             (error
              (funcall resolve-fn (format "ERROR: %s" (error-message-string err)))))))))
