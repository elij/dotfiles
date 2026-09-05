;;; cargo_test.el --- Run cargo test in workspace -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'macher-agent-tools)
(require 'macher-agent-vfs)

(setq macher-agent-cargo-test-tool
      (gptel-make-tool
       :name "cargo_test"
       :description "Run 'cargo test' inside the VFS."
       :category "execution"
       :args nil
       :async t
       :function (macher-agent-with-presentation-context ()
                   (let* ((native-fn (get 'macher-agent-cargo-test-tool 'ptc-function))
                          (root (or (and context (macher-agent-context-project-root context))
                                    default-directory)))
                     (funcall native-fn context root)))))

(put 'macher-agent-cargo-test-tool 'ptc-function
     (lambda (context _root)
       (let ((output
              (macher-agent-call-with-strict-vfs-pipeline
               context
               (lambda ()
                 (let* ((toml-path (car (directory-files-recursively default-directory "^Cargo\\.toml$")))
                        (dir (if toml-path (file-name-directory toml-path) nil)))
                   (if dir
                       (let* ((default-directory dir)
                              (clean-dir (directory-file-name (expand-file-name dir)))
                              (cmd (format "RUSTFLAGS=\"--remap-path-prefix=%s=.\" rtk cargo test 2>&1"
                                           clean-dir)))
                         (shell-command-to-string cmd))
                     "ERROR: No Cargo.toml found. The workspace is empty or invalid."))))))
         (if (string-match-p "\\(FAILED\\|error:\\|ERROR:\\)" output)
             output
           (concat "SUCCESS: All tests passed.\n\n=== OUTPUT ===\n" output)))))
