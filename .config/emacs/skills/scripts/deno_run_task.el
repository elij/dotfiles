;;; deno_run_task.el --- Run a Deno task inside the VFS -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'ansi-color)
(require 'gptel)

(setq macher-agent-deno-run-task-tool
      (gptel-make-tool
       :name "deno_run_task"
       :description "Run a short-lived Deno task (for example, 'check', 'test', or 'build') inside the VFS. Do not use for long-lived server tasks such as 'start' or 'dev'; spawn those inside playwright_deno on a free port."
       :category "execution"
       :include nil
       :args '((:name "task"
                :type "string"
                :description "The task name defined in deno.json (for example, 'check', 'test', or 'build').")
               (:name "cwd"
                :type "string"
                :optional t
                :description "Optional workspace-relative directory containing deno.json (defaults to '.')."))
       :async t
       :function (lambda (callback task &optional cwd)
                   (let ((thunk (funcall (get 'macher-agent-deno-run-task-tool 'ptc-function)
                                         task cwd)))
                     (funcall thunk callback)))))

(put 'macher-agent-deno-run-task-tool 'ptc-function
     (lambda (task &optional cwd context _root)
       (let* ((ctx-in-cwd (and (null context)
                               (not (null cwd))
                               (not (stringp cwd))))
              (raw-cwd (if ctx-in-cwd nil cwd))
              (ctx (or (if ctx-in-cwd cwd context)
                       (current-buffer)))
              (ws-root (and ctx
                            (fboundp 'macher-agent--context-workspace-root)
                            (macher-agent--context-workspace-root ctx)))
              (ws-nm (and (stringp ws-root)
                          (expand-file-name "node_modules" ws-root)))
              (clean-task (if (stringp task) (string-trim task) ""))
              (clean-cwd (if (and (stringp raw-cwd)
                                  (not (string-empty-p (string-trim raw-cwd))))
                             (string-trim raw-cwd)
                           "."))
              (run-fn (if (fboundp 'macher-agent-vfs-run-in-sandbox)
                          #'macher-agent-vfs-run-in-sandbox
                        #'macher-agent-run-in-vfs-sandbox)))
         (lambda (resolve)
           (cond
            ((member clean-task '("start" "dev" "serve" "watch"))
             (funcall resolve
                      (format "ERROR: Task '%s' is a long-lived server/watch command that blocks the VFS sandbox. Spawn it as a child process on a free ephemeral port inside playwright_deno and terminate it in a finally block." clean-task)))
            ((not (string-match-p "\\`[A-Za-z0-9:_-]+\\'" clean-task))
             (funcall resolve
                      (format "ERROR: Invalid Deno task name '%s'." clean-task)))
            ((or (string-prefix-p "/" clean-cwd)
                 (string-match-p "\\(^\\|/\\)\\.\\.\\(/\\|$\\)" clean-cwd))
             (funcall resolve
                      (format "ERROR: Invalid workspace-relative cwd '%s'." clean-cwd)))
            (t
             (let* ((seed-nm (if (and ws-nm (file-directory-p ws-nm) (eq system-type 'darwin))
                                 (format "[ ! -e node_modules ] && cp -cR %s ./node_modules 2>/dev/null || true; "
                                         (shell-quote-argument ws-nm))
                               ""))
                    (cmd (format "%scd %s && NO_COLOR=1 deno task -q %s </dev/null 2>&1"
                                 seed-nm
                                 (shell-quote-argument clean-cwd)
                                 (shell-quote-argument clean-task))))
               (funcall
                run-fn ctx cmd resolve
                (lambda (code output)
                  (let ((clean-out (replace-regexp-in-string
                                    "\r" ""
                                    (ansi-color-filter-apply output))))
                    (if (/= code 0)
                        (format "ERROR: Deno task '%s' failed (exit code %d).\n\n=== OUTPUT ===\n%s"
                                clean-task code clean-out)
                      (format "SUCCESS: Deno task '%s' completed with no errors.\n\n=== OUTPUT ===\n%s"
                              clean-task clean-out))))))))))))
