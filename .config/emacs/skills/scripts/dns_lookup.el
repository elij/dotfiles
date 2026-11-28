;;; dns_lookup.el --- Asynchronous DNS lookup tool -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'gptel)

(setq macher-agent-dns-lookup-tool
      (gptel-make-tool
       :name "dns_lookup"
       :description "Query DNS records for a hostname using dig without invoking a shell."
       :category "perception"
       :include nil
       :args '((:name "host"
                :type "string"
                :description "Hostname or domain name to query (for example, 'assets.lypy.com').")
               (:name "record_type"
                :type "string"
                :optional t
                :enum ["A" "AAAA" "CNAME" "TXT" "MX" "NS" "SOA" "SRV" "CAA"]
                :description "Optional DNS record type to query (defaults to 'A')."))
       :async t
       :function (lambda (callback host &optional record_type)
                   (let ((thunk (funcall (get 'macher-agent-dns-lookup-tool 'ptc-function)
                                         host record_type)))
                     (funcall thunk callback)))))

(put 'macher-agent-dns-lookup-tool 'ptc-function
     (lambda (host &optional record-type _context _root)
       (let* ((allowed-types '("A" "AAAA" "CNAME" "TXT" "MX" "NS" "SOA" "SRV" "CAA"))
              (raw-type (if (stringp record-type)
                            (upcase (string-trim record-type))
                          "A"))
              (clean-type (if (string-empty-p raw-type) "A" raw-type))
              (clean-host (if (stringp host) (string-trim host) "")))
         (lambda (resolve)
           (cond
            ((not (string-match-p "\\`[A-Za-z0-9._-]+\\'" clean-host))
             (funcall resolve (format "ERROR: Invalid hostname '%s'." clean-host)))
            ((not (member clean-type allowed-types))
             (funcall resolve (format "ERROR: Unsupported DNS record type '%s'." clean-type)))
            ((not (executable-find "dig"))
             (funcall resolve "ERROR: 'dig' executable not found in PATH."))
            (t
             (let ((out-buf (generate-new-buffer " *macher-dns-lookup*")))
               (make-process
                :name "macher-dns-lookup"
                :buffer out-buf
                :noquery t
                :connection-type 'pipe
                :command (list "dig" "+noall" "+answer" "+time=5" "+tries=2"
                               clean-host clean-type)
                :sentinel
                (lambda (proc _event)
                  (when (memq (process-status proc) '(exit signal))
                    (let* ((code (process-exit-status proc))
                           (output (if (buffer-live-p out-buf)
                                       (with-current-buffer out-buf
                                         (string-trim (buffer-string)))
                                     "")))
                      (when (buffer-live-p out-buf)
                        (kill-buffer out-buf))
                      (cond
                       ((/= code 0)
                        (funcall resolve
                                 (format "ERROR: dig exited with code %d for %s (%s).\n%s"
                                         code clean-host clean-type output)))
                       ((string-empty-p output)
                        (funcall resolve
                                 (format "NO RECORDS: No %s records returned for %s."
                                         clean-type clean-host)))
                       (t
                        (funcall resolve
                                 (format "DNS %s records for %s:\n%s"
                                         clean-type clean-host output)))))))))))))))
