;;; cargo_check.el --- Cargo check execution tool -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'subr-x)
(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-cargo-check-tool
      (gptel-make-tool
       :name "cargo_check"
       :description "Run 'cargo check' inside the VFS."
       :category "execution"
       :include nil
       :args nil
       :async t
       :function (macher-agent-with-presentation-context ()
                   (let ((native-fn (get 'macher-agent-cargo-check-tool 'ptc-function)))
                     (funcall native-fn context)))))

(put 'macher-agent-cargo-check-tool 'ptc-function
     (lambda (context)
       (let ((raw-output
              (macher-agent-call-with-strict-vfs-pipeline
               context
               (lambda ()
                 (let* ((toml-path (car (directory-files-recursively default-directory "^Cargo\\.toml$")))
                        (dir (if toml-path (file-name-directory toml-path) nil)))
                   (if dir
                       (let* ((default-directory dir)
                              (clean-dir (directory-file-name (expand-file-name dir)))
                              (cmd (format "RUSTFLAGS=\"--remap-path-prefix=%s=.\" rtk cargo check 2>&1"
                                           clean-dir)))
                         (shell-command-to-string cmd))
                     "ERROR: No Cargo.toml found. The workspace is empty or invalid."))))))
         (if (string-match-p "\\(error:\\|could not compile\\|ERROR:\\)" raw-output)
             raw-output
           (concat "SUCCESS: Cargo check completed with no errors.\n\n=== OUTPUT ===\n" raw-output)))))
