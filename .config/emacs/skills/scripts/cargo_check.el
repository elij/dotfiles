;;; cargo_check.el --- Cargo check execution tool -*- lexical-binding: t; -*-
(setq macher-agent-cargo-check-tool
      (gptel-make-tool
       :name "cargo_check"
       :description "Run 'cargo check' inside the VFS."
       :category "execution"
       :include nil
       :args nil
       :async t
       :function (lambda (callback)
                   (let ((thunk (funcall (get 'macher-agent-cargo-check-tool 'ptc-function))))
                     (funcall thunk callback)))))

(put 'macher-agent-cargo-check-tool 'ptc-function
     (lambda (&optional context _root)
       (let ((ctx (or context (current-buffer))))
         (lambda (resolve)
           (let ((cmd (concat
                       "toml=$(find . -name 'Cargo.toml' -print "
                       "| awk '{print length($0), $0}' | sort -n | head -n1 | cut -d' ' -f2-); "
                       "if [ -z \"$toml\" ]; then "
                       "  echo 'ERROR: No Cargo.toml found. The workspace is empty or invalid.'; exit 1; "
                       "fi; "
                       "cd \"$(dirname \"$toml\")\" && "
                       "RUSTFLAGS=\"--remap-path-prefix=$(pwd)=.\" rtk cargo check </dev/null 2>&1")))
             (macher-agent-run-in-vfs-sandbox
              ctx cmd resolve
              (lambda (code output)
                (if (or (/= code 0)
                        (string-match-p "\\(error:\\|error\\[\\|could not compile\\|ERROR:\\)" output))
                    output
                  (concat "SUCCESS: Cargo check completed with no errors.\n\n=== OUTPUT ===\n" output)))))))))
