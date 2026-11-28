;;; vite_build.el --- Run Vite production build inside the VFS -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'ansi-color)
(require 'gptel)

(setq macher-agent-vite-build-tool
      (gptel-make-tool
       :name "vite_build"
       :description "Run 'deno run -q -A npm:vite build' (with '--app' enabled by default for Fresh 2.0 sites) inside the VFS."
       :category "execution"
       :include nil
       :args '((:name "cwd"
                :type "string"
                :optional t
                :description "Optional workspace-relative directory containing vite.config.ts (defaults to '.').")
               (:name "app_mode"
                :type "boolean"
                :optional t
                :description "Whether to pass '--app' to vite build (defaults to true)."))
       :async t
       :function (lambda (callback &optional cwd app_mode)
                   (let ((thunk (funcall (get 'macher-agent-vite-build-tool 'ptc-function)
                                         cwd app_mode)))
                     (funcall thunk callback)))))

(put 'macher-agent-vite-build-tool 'ptc-function
     (lambda (&optional cwd app-mode context _root)
       (let* ((ctx-in-cwd (and (null context)
                               (null app-mode)
                               (not (null cwd))
                               (not (stringp cwd))))
              (ctx-in-app (and (not ctx-in-cwd)
                               (null context)
                               (not (null app-mode))
                               (not (booleanp app-mode))
                               (not (eq app-mode :json-false))))
              (raw-cwd (if ctx-in-cwd nil cwd))
              (raw-app (if (or ctx-in-cwd ctx-in-app) nil app-mode))
              (ctx (or (cond
                        (ctx-in-cwd cwd)
                        (ctx-in-app app-mode)
                        (t context))
                       (current-buffer)))
              (ws-root (and ctx
                            (fboundp 'macher-agent--context-workspace-root)
                            (macher-agent--context-workspace-root ctx)))
              (ws-nm (and (stringp ws-root)
                          (expand-file-name "node_modules" ws-root)))
              (clean-cwd (if (and (stringp raw-cwd)
                                  (not (string-empty-p (string-trim raw-cwd))))
                             (string-trim raw-cwd)
                           "."))
              (use-app (not (eq raw-app :json-false)))
              (run-fn (if (fboundp 'macher-agent-vfs-run-in-sandbox)
                          #'macher-agent-vfs-run-in-sandbox
                        #'macher-agent-run-in-vfs-sandbox)))
         (lambda (resolve)
           (if (or (string-prefix-p "/" clean-cwd)
                   (string-match-p "\\(^\\|/\\)\\.\\.\\(/\\|$\\)" clean-cwd))
               (funcall resolve
                        (format "ERROR: Invalid workspace-relative cwd '%s'." clean-cwd))
             (let* ((seed-nm (if (and ws-nm (file-directory-p ws-nm) (eq system-type 'darwin))
                                 (format "[ ! -e node_modules ] && cp -cR %s ./node_modules 2>/dev/null || true; "
                                         (shell-quote-argument ws-nm))
                               ""))
                    (cmd (format "%scd %s && NO_COLOR=1 deno run -q -A npm:vite build%s </dev/null 2>&1"
                                 seed-nm
                                 (shell-quote-argument clean-cwd)
                                 (if use-app " --app" ""))))
               (funcall
                run-fn ctx cmd resolve
                (lambda (code output)
                  (let ((clean-out (replace-regexp-in-string
                                    "\r" ""
                                    (ansi-color-filter-apply output))))
                    (if (/= code 0)
                        (format "ERROR: Vite build failed (exit code %d).\n\n=== BUILD OUTPUT ===\n%s"
                                code clean-out)
                      (concat "SUCCESS: Vite build completed.\n\n=== BUILD OUTPUT ===\n"
                              clean-out)))))))))))
