;;; wrangler_deploy.el --- Validate or deploy a Cloudflare Worker via Wrangler -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'ansi-color)
(require 'gptel)

(setq macher-agent-wrangler-deploy-tool
      (gptel-make-tool
       :name "wrangler_deploy"
       :description "Run 'deno run -q -A npm:wrangler deploy' inside the VFS. Defaults to '--dry-run' to validate bundled assets, routes, and Cloudflare bindings safely without publishing."
       :category "execution"
       :include nil
       :args '((:name "cwd"
                :type "string"
                :optional t
                :description "Optional workspace-relative directory containing wrangler.jsonc or wrangler.toml (defaults to '.').")
               (:name "dry_run"
                :type "boolean"
                :optional t
                :description "Whether to pass '--dry-run' instead of deploying live (defaults to true).")
               (:name "build_first"
                :type "boolean"
                :optional t
                :description "Whether to run 'deno run -q -A npm:vite build --app' before Wrangler when a Vite config is present (defaults to false)."))
       :async t
       :function (lambda (callback &optional cwd dry_run build_first)
                   (let ((thunk (funcall (get 'macher-agent-wrangler-deploy-tool 'ptc-function)
                                         cwd dry_run build_first)))
                     (funcall thunk callback)))))

(put 'macher-agent-wrangler-deploy-tool 'ptc-function
     (lambda (&optional cwd dry-run build-first context _root)
       (let* ((ctx-in-cwd (and (null context)
                               (null dry-run)
                               (null build-first)
                               (not (null cwd))
                               (not (stringp cwd))))
              (ctx-in-dry (and (not ctx-in-cwd)
                               (null context)
                               (null build-first)
                               (not (null dry-run))
                               (not (booleanp dry-run))
                               (not (eq dry-run :json-false))))
              (ctx-in-build (and (not ctx-in-cwd)
                                 (not ctx-in-dry)
                                 (null context)
                                 (not (null build-first))
                                 (not (booleanp build-first))
                                 (not (eq build-first :json-false))))
              (raw-cwd (if ctx-in-cwd nil cwd))
              (raw-dry (if (or ctx-in-cwd ctx-in-dry) nil dry-run))
              (raw-build (if (or ctx-in-cwd ctx-in-dry ctx-in-build) nil build-first))
              (ctx (or (cond
                        (ctx-in-cwd cwd)
                        (ctx-in-dry dry-run)
                        (ctx-in-build build-first)
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
              (is-dry-run (not (eq raw-dry :json-false)))
              (do-build (and raw-build (not (eq raw-build :json-false))))
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
                    (build-prefix (if do-build
                                      "if [ -f vite.config.ts ] || [ -f vite.config.js ]; then NO_COLOR=1 deno run -q -A npm:vite build --app; fi && "
                                    ""))
                    (deploy-flag (if is-dry-run " --dry-run" ""))
                    (cmd (format
                          "%scd %s && if [ ! -f wrangler.jsonc ] && [ ! -f wrangler.toml ] && [ ! -f wrangler.json ]; then echo 'ERROR: No Wrangler configuration file found.'; exit 1; fi && %sNO_COLOR=1 deno run -q -A npm:wrangler deploy%s </dev/null 2>&1"
                          seed-nm
                          (shell-quote-argument clean-cwd)
                          build-prefix
                          deploy-flag)))
               (funcall
                run-fn ctx cmd resolve
                (lambda (code output)
                  (let ((clean-out (replace-regexp-in-string
                                    "\r" ""
                                    (ansi-color-filter-apply output))))
                    (if (/= code 0)
                        (format "ERROR: Wrangler deploy%s failed (exit code %d).\n\n=== WRANGLER OUTPUT ===\n%s"
                                deploy-flag code clean-out)
                      (format "SUCCESS: Wrangler deploy%s completed.\n\n=== WRANGLER OUTPUT ===\n%s"
                              deploy-flag clean-out)))))))))))
