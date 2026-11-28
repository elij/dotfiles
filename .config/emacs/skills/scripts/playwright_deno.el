;;; playwright_deno.el --- Run Playwright via Deno and return screenshots -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'mailcap)
(require 'subr-x)
(require 'ansi-color)
(require 'gptel)
(require 'macher-agent-core)
(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-playwright-deno-tool
      (gptel-make-tool
       :name "playwright_deno"
       :description (concat
                     "Execute a TypeScript or JavaScript Playwright script using Deno inside the VFS "
                     "and return the captured screenshot directly in visual context. "
                     "Use `import { firefox } from \"npm:playwright@1.60.0\";` and call `Deno.exit(0)` after closing the browser. "
                     "Save screenshots to Deno.env.get('PLAYWRIGHT_SCREENSHOT_DIR') "
                     "or to the path specified in `screenshot_path`. "
                     "When testing a local server (such as `deno serve`), pick a free ephemeral port, "
                     "terminate the child server in a `finally` block, and use `page.route` when mocking backend APIs.")
       :category "perception"
       :args '((:name "script"
                      :type "string"
                      :description "TypeScript/JavaScript Playwright script to execute via `deno run -q -A`.")
               (:name "screenshot_path"
                      :type "string"
                      :optional t
                      :description "Optional relative path where the script writes a screenshot (for example, 'screenshot.png')."))
       :async t
       :function (lambda (callback script &optional screenshot_path)
                   (let ((thunk (funcall (get 'macher-agent-playwright-deno-tool 'ptc-function)
                                         script screenshot_path)))
                     (funcall thunk callback)))))

(put 'macher-agent-playwright-deno-tool 'ptc-function
     (lambda (script &optional screenshot-path context)
       (let* ((ctx-in-shot (and (null context)
                                (not (null screenshot-path))
                                (not (stringp screenshot-path))))
              (actual-shot (if ctx-in-shot nil screenshot-path))
              (ctx (or (macher-agent-resolve-context (if ctx-in-shot screenshot-path context))
                       (macher-agent-resolve-context (current-buffer))))
              (ws-root (and ctx
                            (fboundp 'macher-agent--context-workspace-root)
                            (macher-agent--context-workspace-root ctx)))
              (pipeline-fn (if (fboundp 'macher-agent-vfs-call-with-strict-pipeline)
                               #'macher-agent-vfs-call-with-strict-pipeline
                             #'macher-agent-call-with-strict-vfs-pipeline))
              (slash-fn (if (fboundp 'macher-agent-ensure-trailing-slash)
                            #'macher-agent-ensure-trailing-slash
                          #'macher-agent--ensure-trailing-slash))
              (trunc-fn (if (fboundp 'macher-agent-truncate-string)
                            #'macher-agent-truncate-string
                          #'macher-agent--truncate-string)))
         (lambda (resolve)
           (if (not (and (boundp 'gptel-track-media) gptel-track-media))
               (funcall resolve "ERROR: gptel media send option is off (gptel-track-media is nil).")
             (funcall
              pipeline-fn ctx resolve
              (lambda (sandbox-dir done)
                (let* ((canon-sandbox (file-name-as-directory (file-truename sandbox-dir)))
                       (default-directory (funcall slash-fn sandbox-dir))
                       (shot-dir (expand-file-name ".playwright-screenshots" sandbox-dir))
                       (fake-home (expand-file-name ".playwright-home" sandbox-dir))
                       (real-home (expand-file-name "~"))
                       (ws-node-modules (and (stringp ws-root)
                                             (expand-file-name "node_modules" ws-root)))
                       (sandbox-node-modules (expand-file-name "node_modules" sandbox-dir))
                       (script-file (expand-file-name ".macher-playwright-runner.ts" sandbox-dir))
                       (out-buf (generate-new-buffer " *macher-playwright-deno*"))
                       (process-environment
                        (append
                         (list "NO_COLOR=1"
                               (format "PLAYWRIGHT_SCREENSHOT_DIR=%s" shot-dir)
                               (format "PLAYWRIGHT_BROWSERS_PATH=%s"
                                       (expand-file-name "Library/Caches/ms-playwright" real-home))
                               (format "DENO_DIR=%s"
                                       (expand-file-name "Library/Caches/deno" real-home))
                               (format "HOME=%s" fake-home)
                               (format "CFFIXED_USER_HOME=%s" fake-home)
                               "MOZ_DISABLE_CONTENT_SANDBOX=1"
                               "MOZ_DISABLE_GMP_SANDBOX=1"
                               "MOZ_DISABLE_GPU_SANDBOX=1"
                               "MOZ_DISABLE_RDD_SANDBOX=1"
                               "MOZ_DISABLE_SOCKET_PROCESS_SANDBOX=1")
                         process-environment)))
                  ;; Seed node_modules via APFS copy-on-write clone when available
                  ;; so Deno avoids re-initialising workspace npm packages per run.
                  (when (and ws-node-modules
                             (file-directory-p ws-node-modules)
                             (not (file-exists-p sandbox-node-modules))
                             (eq system-type 'darwin))
                    (ignore-errors
                      (call-process "cp" nil nil nil "-cR" ws-node-modules sandbox-node-modules)))
                  (make-directory shot-dir t)
                  (make-directory (expand-file-name "Library/Application Support/Firefox" fake-home) t)
                  (let ((coding-system-for-write 'utf-8-unix))
                    (with-temp-file script-file
                      (insert (or script ""))))
                  (condition-case err
                      (make-process
                       :name "macher-playwright-deno"
                       :buffer out-buf
                       :noquery t
                       :connection-type 'pipe
                       :command (list "deno" "run" "-q" "-A" script-file)
                       :sentinel
                       (lambda (proc _event)
                         (when (memq (process-status proc) '(exit signal))
                           (let* ((code (process-exit-status proc))
                                  (raw-out (if (buffer-live-p out-buf)
                                               (with-current-buffer out-buf
                                                 (replace-regexp-in-string
                                                  "\r" ""
                                                  (ansi-color-filter-apply (buffer-string))))
                                             ""))
                                  (explicit-cand (and (stringp actual-shot)
                                                      (not (string-empty-p actual-shot))
                                                      (expand-file-name actual-shot sandbox-dir)))
                                  (explicit-shot (when (and explicit-cand (file-exists-p explicit-cand))
                                                   (let ((tr (file-truename explicit-cand)))
                                                     (when (string-prefix-p canon-sandbox tr)
                                                       tr))))
                                  (dir-shots (when (file-directory-p shot-dir)
                                               (sort (directory-files-recursively
                                                      shot-dir "\\.\\(png\\|jpe?g\\|webp\\)\\'")
                                                     #'string<)))
                                  (shots (delete-dups
                                          (append (when explicit-shot (list explicit-shot))
                                                  dir-shots)))
                                  (primary-shot (car (last shots)))
                                  (extra-shots (butlast shots)))
                             (when (buffer-live-p out-buf)
                               (kill-buffer out-buf))
                             (when (and primary-shot (macher-agent-valid-context-p ctx))
                               (let* ((mime (or (mailcap-file-name-to-mime-type primary-shot) "image/png"))
                                      (media-spec (list (gptel--base64-encode primary-shot) :mime mime)))
                                 (setf (macher-agent-context-media-queue ctx) media-spec)
                                 (setf (macher-agent-context-plugins ctx)
                                       (plist-put (copy-sequence (macher-agent-context-plugins ctx))
                                                  :pending-media media-spec))))
                             (funcall done
                                      (funcall
                                       trunc-fn
                                       (concat
                                        (if (= code 0)
                                            "SUCCESS: Playwright Deno script completed.\n"
                                          (format "ERROR: Playwright Deno script exited with code %d.\n" code))
                                        (if primary-shot
                                            (concat
                                             (format "Screenshot '%s' queued into visual context.\n"
                                                     (file-relative-name primary-shot canon-sandbox))
                                             (if extra-shots
                                                 (format "Note: %d additional screenshot(s) were written (%s); only the last screenshot is attached to visual context per invocation.\n"
                                                         (length extra-shots)
                                                         (mapconcat (lambda (p) (file-relative-name p canon-sandbox))
                                                                    extra-shots ", "))
                                               ""))
                                          "No screenshots were found in PLAYWRIGHT_SCREENSHOT_DIR or screenshot_path.\n")
                                        "\n=== DENO OUTPUT ===\n"
                                        raw-out)))))))
                    (error
                     (when (buffer-live-p out-buf)
                       (kill-buffer out-buf))
                     (funcall done (format "ERROR: Failed to start Deno Playwright process: %s"
                                           (error-message-string err)))))))))))))
