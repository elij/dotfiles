(macher-agent-make-tool macher-agent-cargo-test-tool
    "Run 'cargo test' inside the VFS."
  :category "execution"
  :args nil
  :command-fn
  (lambda (_payload context _root)
    (macher-agent-call-with-strict-vfs-pipeline
     context
     (lambda ()
       (let* ((toml-path (car (directory-files-recursively default-directory "^Cargo\\.toml$")))
              (dir (if toml-path (file-name-directory toml-path) nil)))
         (if dir
             (let ((default-directory dir))
               (shell-command-to-string "cargo test 2>&1"))
           "ERROR: No Cargo.toml found. The workspace is empty or invalid.")))))
  :success-fn
  (lambda (output)
    (if (string-match-p "\\(FAILED\\|error:\\|ERROR:\\)" output)
        output
      (concat "SUCCESS: All tests passed.\n\n=== OUTPUT ===\n" output))))
