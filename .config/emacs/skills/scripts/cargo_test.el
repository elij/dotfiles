;;; cargo_test.el --- Run cargo test in workspace -*- lexical-binding: t; -*-
(setq macher-agent-cargo-test-tool
      (gptel-make-tool
       :name "cargo_test"
       :description "Run 'cargo test' inside the VFS to test a rust package."
       :category "execution"
       :args nil
       :async t
       :function (lambda (callback)
                   (let ((thunk (funcall (get 'macher-agent-cargo-test-tool 'ptc-function))))
                     (funcall thunk callback)))))

(put 'macher-agent-cargo-test-tool 'ptc-function
     (lambda (&optional context)
       (let ((ctx (or context (current-buffer))))
         (lambda (resolve)
           (let ((cmd (concat
                       "toml=$(find . -name 'Cargo.toml' -print "
                       "| awk '{print length($0), $0}' | sort -n | head -n1 | cut -d' ' -f2-); "
                       "if [ -z \"$toml\" ]; then "
                       "  echo 'ERROR: No Cargo.toml found. The workspace is empty or invalid.'; exit 1; "
                       "fi; "
                       "cd \"$(dirname \"$toml\")\" && "
                       "RUSTFLAGS=\"--remap-path-prefix=$(pwd)=.\" rtk cargo test </dev/null 2>&1")))
             (macher-agent-run-in-vfs-sandbox
              ctx cmd resolve
              (lambda (code output)
                (if (or (/= code 0)
                        (string-match-p "\\(FAILED\\|error:\\|error\\[\\|ERROR:\\)" output))
                    output
                  (concat "SUCCESS: All tests passed.\n\n=== OUTPUT ===\n" output)))))))))
