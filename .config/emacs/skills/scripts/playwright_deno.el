;;; playwright_deno.el --- Run Playwright via Deno and return screenshots -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'mailcap)
(require 'subr-x)
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
                     "or to the path specified in `screenshot_path`.")
       :category "perception"
       :args '((:name "script"
                      :type "string"
                      :description "TypeScript/JavaScript Playwright script to execute via `deno run -A`.")
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
       (let ((ctx (or (macher-agent-resolve-context context)
                      (macher-agent-resolve-context (current-buffer)))))
         (lambda (resolve)
           (if (not (and (boundp 'gptel-track-media) gptel-track-media))
               (funcall resolve "ERROR: gptel media send option is off (gptel-track-media is nil).")
             (macher-agent-call-with-strict-vfs-pipeline
              ctx resolve
              (lambda (sandbox-dir done)
                (let* ((default-directory (macher-agent--ensure-trailing-slash sandbox-dir))
                       (shot-dir (expand-file-name ".playwright-screenshots" sandbox-dir))
                       (fake-home (expand-file-name ".playwright-home" sandbox-dir))
                       (real-home (expand-file-name "~"))
                       (script-file (expand-file-name ".macher-playwright-runner.ts" sandbox-dir))
                       (out-buf (generate-new-buffer " *macher-playwright-deno*"))
                       (process-environment
                        (append
                         (list (format "PLAYWRIGHT_SCREENSHOT_DIR=%s" shot-dir)
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
                       :command (list "deno" "run" "-A" script-file)
                       :sentinel
                       (lambda (proc _event)
                         (when (memq (process-status proc) '(exit signal))
                           (let* ((code (process-exit-status proc))
                                  (raw-out (if (buffer-live-p out-buf)
                                               (with-current-buffer out-buf
                                                 (buffer-string))
                                             ""))
                                  (explicit-shot (and screenshot-path
                                                      (not (string-empty-p screenshot-path))
                                                      (expand-file-name screenshot-path sandbox-dir)))
                                  (dir-shots (when (file-directory-p shot-dir)
                                               (directory-files-recursively
                                                shot-dir "\\.\\(png\\|jpe?g\\|webp\\)\\'")))
                                  (shots (append (when (and explicit-shot (file-exists-p explicit-shot))
                                                   (list explicit-shot))
                                                 dir-shots))
                                  (primary-shot (car (last shots))))
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
                                      (macher-agent--truncate-string
                                       (concat
                                        (if (= code 0)
                                            "SUCCESS: Playwright Deno script completed.\n"
                                          (format "ERROR: Playwright Deno script exited with code %d.\n" code))
                                        (if primary-shot
                                            (format "Screenshot '%s' queued into visual context.\n"
                                                    (file-relative-name primary-shot sandbox-dir))
                                          "No screenshots were found in PLAYWRIGHT_SCREENSHOT_DIR or screenshot_path.\n")
                                        "\n=== DENO OUTPUT ===\n"
                                        raw-out)))))))
                    (error
                     (when (buffer-live-p out-buf)
                       (kill-buffer out-buf))
                     (funcall done (format "ERROR: Failed to start Deno Playwright process: %s"
                                           (error-message-string err)))))))))))))
