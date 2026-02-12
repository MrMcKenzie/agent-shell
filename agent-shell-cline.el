;;; agent-shell-cline.el --- Cline ACP integration for agent-shell -*- lexical-binding: t; -*-

;; Copyright (C) 2024

;; This file is part of agent-shell.

;;; Commentary:

;; This package provides integration with Cline CLI via the Agent Client Protocol (ACP).
;; Cline is an AI coding agent that can work across different editors through ACP.
;;
;; Prerequisites:
;; - Node.js and npm installed
;; - Cline CLI installed: npm i -g cline
;; - Authenticated: cline auth
;;
;; Usage:
;; (agent-shell-cline-start-agent)

;;; Code:
(defgroup agent-shell-cline nil
  "Cline ACP integration for agent-shell."
  :group 'agent-shell
  :prefix "agent-shell-cline-")

(defcustom agent-shell-cline-executable "cline"
  "Path to the Cline CLI executable."
  :type 'string
  :group 'agent-shell-cline)

(defcustom agent-shell-cline-model nil
  "Model to use with Cline.
If nil, uses Cline's default model configuration."
  :type '(choice (const :tag "Default" nil)
                 (string :tag "Model name"))
  :group 'agent-shell-cline)

(defcustom agent-shell-cline-yolo-mode nil
  "Enable yolo (auto-approve) mode for Cline.
When enabled, Cline will automatically approve certain actions."
  :type 'boolean
  :group 'agent-shell-cline)

(defcustom agent-shell-cline-config-dir nil
  "Custom configuration directory for Cline.
If nil, uses Cline's default configuration directory."
  :type '(choice (const :tag "Default" nil)
                 (directory :tag "Config directory"))
  :group 'agent-shell-cline)

(defcustom agent-shell-cline-extra-args nil
  "Additional command-line arguments to pass to Cline CLI."
  :type '(repeat string)
  :group 'agent-shell-cline)

(defcustom agent-shell-cline-env-vars nil
  "Additional environment variables for Cline process.
Should be an alist of (VAR . VALUE) pairs.

Example:
  (setq agent-shell-cline-env-vars
        (`agent-shell-make-environment-variables'
         \"CLINE_DIR\" . \"/usr/cline\"
         \"CLINE_COMMAND_PERMISSIONS\" . \"'{\"allow\": [\"npm *\", \"git *\"], \"deny\": [\"rm -rf *\"]}'\"))"
  :type '(repeat string)
  :group 'agent-shell-cline)

(defun agent-shell-cline-make-agent-config ()
  "Create configuration for Cline ACP agent."
  (agent-shell-make-agent-config
   :identifier 'cline
   :mode-line-name "Cline"
   :buffer-name "Cline"
   :shell-prompt "Cline> "
   :shell-prompt-regexp "^Cline> "
   :client-maker #'agent-shell-cline--make-client
   :needs-authentication nil
   :authenticate-request-maker nil
   :default-model-id nil
   :default-session-mode-id nil
   :icon-name "cline.png"
   :welcome-function #'agent-shell-cline--welcome-message
   :install-instructions "See https://docs.cline.bot/cline-cli/installation for installation and configuration."))

(defun agent-shell-cline--make-client (buffer)
  "Create Cline ACP client for BUFFER."
  (with-current-buffer buffer
    (let* ((args (list "--acp")))
      ;; Add model if specified
      (when agent-shell-cline-model
        (setq args (append args (list "--model" agent-shell-cline-model))))

      ;; Add auto-approve if enabled
      (when agent-shell-cline-yolo-mode
        (setq args (append args (list "--yolo"))))

      ;; Add config directory if specified
      (when agent-shell-cline-config-dir
        (setq args (append args (list "--config-dir"
                                      (expand-file-name agent-shell-cline-config-dir)))))

      ;; Add any extra arguments
      (when agent-shell-cline-extra-args
        (setq args (append args agent-shell-cline-extra-args)))

      (agent-shell--make-acp-client :command agent-shell-cline-executable
                                    :command-params args
                                    :environment-variables agent-shell-cline-env-vars
                                    :context-buffer buffer))))

;;;###autoload
(defun agent-shell-cline-start-agent ()
  "Start a new agent-shell session with Cline via ACP."
  (interactive)
  (let ((config (agent-shell-cline-make-agent-config)))
    (agent-shell config)))

(defun agent-shell-cline--welcome-message (config)
  "Return Cline ASCII art as welcome message using `shell-maker' CONFIG."
  (let ((art (agent-shell--indent-string 4 (agent-shell-cline--ascii-art)))
        (message (string-trim-left (shell-maker-welcome-message config) "\n")))
    (concat "\n\n\n"
            art
            "\n        What can I do for you?"
            "\n\n"
            message)))

(defun agent-shell-cline--ascii-art ()
  "Return ASCII art for Cline agent."
  ;; Obtained from https://github.com/cline/cline/blob/main/cli/src/components/WelcomeView.tsx
  "
            :::::::
           :::::::::
       :::::::::::::::::
    :::::::::::::::::::::::
   :::::::::::::::::::::::::
  :::::::::::::::::::::::::::
  :::::::   :::::::   :::::::
 :::::::     :::::     :::::::
::::::::     :::::     ::::::::
::::::::     :::::     ::::::::
 :::::::     :::::     :::::::
  :::::::   :::::::   :::::::
  :::::::::::::::::::::::::::
   :::::::::::::::::::::::::
    :::::::::::::::::::::::
       ::::::::::::::::
")

(provide 'agent-shell-cline)

;;; agent-shell-cline.el ends here
