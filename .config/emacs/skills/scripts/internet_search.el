;;; internet_search.el --- Internet search via google_search sub-agent -*- lexical-binding: t; -*-

(setq macher-agent-internet-search-tool
      (gptel-make-tool
       :name "internet_search"
       :description "Search the internet for up-to-date information by delegating the query to a search sub-agent and returning the synthesised findings."
       :category "perception"
       :args '((:name "query"
                      :type "string"
                      :description "The search query or instructions for the internet search sub-agent."))
       :async t
       :function (lambda (callback query)
                   (let ((thunk (funcall (get 'macher-agent-internet-search-tool 'ptc-function)
                                         query)))
                     (funcall thunk callback)))))

(put 'macher-agent-internet-search-tool 'ptc-function
     (lambda (query &optional context)
       (let ((ctx (or (macher-agent-resolve-context context)
                      (macher-agent-resolve-context (current-buffer)))))
         (lambda (resolve-fn)
           (if (not (and (stringp query)
                         (not (string-empty-p (string-trim query)))))
               (funcall resolve-fn "ERROR: Search query must be a non-empty string.")
             (let* ((delegate-fn
                     (or (get 'macher-agent-delegate-tasks-to-subagents-tool 'ptc-function)
                         (progn
                           (when (fboundp 'macher-agent-resolve-tool)
                             (macher-agent-resolve-tool
                              "delegate_tasks_to_subagents" nil nil ctx))
                           (get 'macher-agent-delegate-tasks-to-subagents-tool 'ptc-function))))
                    (uid (cond
                          ((fboundp 'macher-agent-generate-uuid)
                           (macher-agent-generate-uuid))
                          ((fboundp 'macher-agent--generate-uuid)
                           (macher-agent--generate-uuid))
                          (t (format "%04x%04x" (random #xffff) (random #xffff)))))
                    (buf-name (format "*macher-search-%s*" uid))
                    (tasks (vector (list :buffer_name buf-name
                                         :presets (vector "google-search")
                                         :instructions query))))
               (if (not (functionp delegate-fn))
                   (funcall resolve-fn "ERROR: delegate_tasks_to_subagents tool is not available.")
                 (let ((delegate-thunk (funcall delegate-fn tasks ctx)))
                   (funcall delegate-thunk
                            (lambda (res)
                              (funcall resolve-fn
                                       (cond
                                        ((stringp res) res)
                                        ((and (listp res) (= (length res) 1) (stringp (car res)))
                                         (car res))
                                        ((sequencep res)
                                         (string-join (mapcar (lambda (x) (format "%s" x))
                                                              (append res nil))
                                                      "\n\n"))
                                        (t (format "%s" res))))))))))))))
