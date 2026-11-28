;;; http_head.el --- Asynchronous HTTP HEAD probe tool -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'gptel)

(setq macher-agent-http-head-tool
      (gptel-make-tool
       :name "http_head"
       :description "Send an HTTP HEAD request with curl to inspect status codes, content types, cache headers, and redirects."
       :category "perception"
       :include nil
       :args '((:name "url"
                :type "string"
                :description "Full http:// or https:// URL to inspect (for example, 'https://www.lypy.com').")
               (:name "follow_redirects"
                :type "boolean"
                :optional t
                :description "Whether to follow HTTP redirects (defaults to false so 301/302 Location headers are visible)."))
       :async t
       :function (lambda (callback url &optional follow_redirects)
                   (let ((thunk (funcall (get 'macher-agent-http-head-tool 'ptc-function)
                                         url follow_redirects)))
                     (funcall thunk callback)))))

(put 'macher-agent-http-head-tool 'ptc-function
     (lambda (url &optional follow-redirects _context _root)
       (let* ((clean-url (if (stringp url) (string-trim url) ""))
              (follow (and (booleanp follow-redirects)
                           follow-redirects)))
         (lambda (resolve)
           (cond
            ((not (string-match-p "\\`https?://[^[:space:][:cntrl:]]+\\'" clean-url))
             (funcall resolve
                      (format "ERROR: Invalid HTTP(S) URL '%s'." clean-url)))
            ((not (executable-find "curl"))
             (funcall resolve "ERROR: 'curl' executable not found in PATH."))
            (t
             (let ((out-buf (generate-new-buffer " *macher-http-head*"))
                   (argv (append (list "curl" "-sS" "-I" "--max-time" "15")
                                 (when follow (list "-L"))
                                 (list "--" clean-url))))
               (make-process
                :name "macher-http-head"
                :buffer out-buf
                :noquery t
                :connection-type 'pipe
                :command argv
                :sentinel
                (lambda (proc _event)
                  (when (memq (process-status proc) '(exit signal))
                    (let* ((code (process-exit-status proc))
                           (output (if (buffer-live-p out-buf)
                                       (with-current-buffer out-buf
                                         (replace-regexp-in-string "\r" "" (string-trim (buffer-string))))
                                     "")))
                      (when (buffer-live-p out-buf)
                        (kill-buffer out-buf))
                      (if (/= code 0)
                          (funcall resolve
                                   (format "ERROR: curl exited with code %d for %s.\n%s"
                                           code clean-url output))
                        (funcall resolve
                                 (format "HTTP HEAD %s:\n%s"
                                         clean-url output))))))))))))))
