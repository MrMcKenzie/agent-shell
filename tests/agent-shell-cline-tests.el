;;; agent-shell-cline-tests.el --- Tests for agent-shell-cline -*- lexical-binding: t; -*-

(require 'ert)

;; Mock functions to avoid dependency on acp
(defvar agent-shell--mock-acp-client nil)
(defun acp-make-client (&rest _args)
  agent-shell--mock-acp-client)

(defun agent-shell-make-agent-config (&rest args)
  (apply #'list args))

(require 'agent-shell-cline)

(ert-deftest agent-shell-cline-make-client-test ()
  "Test agent-shell-cline--make-client function."
  ;; Mock executable-find to always return the command path
  (cl-letf (((symbol-function 'executable-find)
             (lambda (_) "/usr/bin/cline"))
            ((symbol-function 'agent-shell--make-acp-client)
             (lambda (&rest args) args)))

    ;; Test with default settings
    (let* ((agent-shell-cline-executable "cline")
           (agent-shell-cline-model nil)
           (agent-shell-cline-yolo-mode nil)
           (agent-shell-cline-config-dir nil)
           (agent-shell-cline-extra-args nil)
           (agent-shell-cline-env-vars nil)
           (test-buffer (get-buffer-create "*test-buffer*"))
           (client (agent-shell-cline--make-client test-buffer)))
      (unwind-protect
          (progn
            (should (listp client))
            (should (equal (map-elt client :command) "cline"))
            (should (equal (map-elt client :command-params) '("--acp")))
            (should (equal (map-elt client :environment-variables) nil)))
        (when (buffer-live-p test-buffer)
          (kill-buffer test-buffer))))

    ;; Test with all customizable/settable variables
    (let* ((agent-shell-cline-executable "/custom/path/cline")
           (agent-shell-cline-model "gpt-4")
           (agent-shell-cline-yolo-mode t)
           (agent-shell-cline-config-dir "/custom/config")
           (agent-shell-cline-extra-args '("--verbose"))
           (agent-shell-cline-env-vars '("CLINE_DIR=/usr/cline" "DEBUG=1"))
           (test-buffer (get-buffer-create "*test-buffer*"))
           (client (agent-shell-cline--make-client test-buffer)))
      (unwind-protect
          (progn
            (should (listp client))
            (should (equal (map-elt client :command) "/custom/path/cline"))
            (should (equal (map-elt client :command-params)
                           '("--acp" "--model" "gpt-4" "--yolo" "--config-dir" "/custom/config" "--verbose")))
            (should (equal (map-elt client :environment-variables)
                           '("CLINE_DIR=/usr/cline" "DEBUG=1"))))
        (when (buffer-live-p test-buffer)
          (kill-buffer test-buffer))))))

(ert-deftest agent-shell-cline-make-agent-config-test ()
  "Test agent-shell-cline-make-agent-config function."
  (let ((config (agent-shell-cline-make-agent-config)))
    (should (eq (map-elt config :identifier) 'cline))
    (should (string= (map-elt config :mode-line-name) "Cline"))
    (should (string= (map-elt config :buffer-name) "Cline"))
    (should (string= (map-elt config :shell-prompt) "Cline> "))
    (should (string= (map-elt config :shell-prompt-regexp) "^Cline> "))
    (should (functionp (map-elt config :client-maker)))
    (should-not (map-elt config :needs-authentication))
    (should-not (map-elt config :authenticate-request-maker))
    (should-not (map-elt config :default-model-id))
    (should-not (map-elt config :default-session-mode-id))
    (should (string= (map-elt config :icon-name) "cline.png"))
    (should (functionp (map-elt config :welcome-function)))
    (should (stringp (map-elt config :install-instructions)))))

(provide 'agent-shell-cline-tests)
;;; agent-shell-cline-tests.el ends here
