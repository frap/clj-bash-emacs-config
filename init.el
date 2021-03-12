;;; init.el --- basic clj emacs -*- lexical-binding: t; -*-
;;
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1") (dash "2.13") (f "0.17.2") (s "1.12.0") (emacsql "3.0.0"))
;; Copyright (c) 2021 Andrés Gasson
;;
;; Author: Andrés Gasson <agasson@gas-atea.local>
;; Maintainer: Andrés Gasson <agasson@gas-atea.local>
;;
;; Created: 11 Mar 2021
;;
;; URL: https://github.com/frap/clj-bash-emacs-config.git
;;
;; License: GPLv3
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;; Code:

;; Since we might be running in CI or other environments, stick to
;; XDG_CONFIG_HOME value if possible.
(let ((emacs-home (if-let ((xdg (getenv "XDG_CONFIG_HOME")))
                      (expand-file-name "emacs/" xdg)
                    user-emacs-directory)))
  ;; Add Lisp directory to `load-path'.
  (add-to-list 'load-path (expand-file-name "lisp" emacs-home)))

;; Adjust garbage collection thresholds during startup, and thereafter
(let ((normal-gc-cons-threshold (* 20 1024 1024))
      (init-gc-cons-threshold (* 128 1024 1024)))
  (setq gc-cons-threshold init-gc-cons-threshold)
  (add-hook 'emacs-startup-hook
            (lambda () (setq gc-cons-threshold
                             normal-gc-cons-threshold))))

;; constants
(setq user-full-name "Andrés Gasson"
      user-mail-address "gas@red-elvis.net")


(defconst path-home-dir (file-name-as-directory (getenv "HOME"))
  "Path to user home directory.

In a nutshell, it's just a value of $HOME.")

(defconst path-config-dir
  (file-name-as-directory
   (or (getenv "XDG_CONFIG_HOME")
       (concat path-home-dir ".config")))
  "The root directory for personal configurations.")

(defconst path-emacs-dir
  (file-name-as-directory
   (expand-file-name "emacs/" path-config-dir))
  "The path to this Emacs directory.")

(defconst path-autoloads-file
  (expand-file-name "init-autoloads.el" path-emacs-dir)
  "The path to personal autoloads file.")

(defconst path-local-dir
  (concat
   (file-name-as-directory
    (or (getenv "XDG_CACHE_HOME")
        (concat path-home-dir ".cache")))
   "emacs/")
  "The root directory for local Emacs files.

Use this as permanent storage for files that are safe to share
across systems.")

(defconst path-etc-dir (concat path-local-dir "etc/")
  "Directory for non-volatile storage.

Use this for files that don't change much, like servers binaries,
external dependencies or long-term shared data.")

(defconst path-cache-dir (concat path-local-dir "cache/")
  "Directory for volatile storage.

Use this for files that change often, like cache files.")

(defconst path-packages-dir
  (expand-file-name (format "packages/%s.%s/"
                            emacs-major-version
                            emacs-minor-version)
                    path-local-dir)
  "Where packages are stored.")

(defconst env-graphic? (display-graphic-p))
(defconst env-root? (string-equal "root" (getenv "USER")))
(defconst env-sys-mac? (eq system-type 'darwin))
(defconst env-sys-linux? (eq system-type 'gnu/linux))
(defconst env-sys-name (system-name))

(defvar elpa-bootstrap-p nil)


;;
;;; Native Compilation support (http://akrl.sdf.org/gccemacs.html)

;; Prevent unwanted runtime builds in gccemacs (native-comp); packages are
;; compiled ahead-of-time when they are installed and site files are compiled
;; when gccemacs is installed.
(setq comp-deferred-compilation nil)

;; Don't store eln files in ~/.emacs.d/eln-cache (they are likely to be purged
;; when ugrading).
(when (boundp 'comp-eln-load-path)
  (add-to-list 'comp-eln-load-path (concat path-cache-dir "eln/")))

(setq package-user-dir
      (expand-file-name
       "elpa/"
       path-packages-dir))


;; bootstrap straight.el

(setq-default
 straight-repository-branch "develop"
 straight-check-for-modifications nil
 straight-use-package-by-default t
 straight-base-dir path-packages-dir
 straight-profiles (list
                    (cons nil
                          (expand-file-name
                           "versions/default.el"
                           path-emacs-dir))))

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el"
                         path-packages-dir))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         (concat "https://raw.githubusercontent.com/"
                 "raxod502/straight.el/"
                 "develop/install.el")
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))


;; use-package

(setq-default
 use-package-enable-imenu-support t)
(straight-use-package 'use-package)



(use-package el-patch
  :straight t)


;; popular packages

(use-package f :demand t)          ;; files
(use-package dash :demand t)       ;; lists
(use-package ht :demand t)         ;; hash-tables
(use-package s :demand t)          ;; strings
(use-package a :demand t)          ;; association lists
(use-package async)


;; Better defaults

;; Always load newest byte code
(setq load-prefer-newer t)

;; reduce the frequency of garbage collection by making it happen on
;; each 50MB of allocated data (the default is on every 0.76MB)
(setq gc-cons-threshold 50000000)

;; warn when opening files bigger than 100MB
(setq large-file-warning-threshold 100000000)

;; quit Emacs directly even if there are running processes
(setq confirm-kill-processes nil)

;; create the savefile dir if it doesn't exist
(unless (file-exists-p path-cache-dir)
  (make-directory path-cache-dir))

;; store all backup and autosave files in the tmp dir
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; revert buffers automatically when underlying files are changed externally
(global-auto-revert-mode t)

(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)

;; hippie expand is dabbrev expand on steroids
(setq hippie-expand-try-functions-list '(try-expand-dabbrev
                                         try-expand-dabbrev-all-buffers
                                         try-expand-dabbrev-from-kill
                                         try-complete-file-name-partially
                                         try-complete-file-name
                                         try-expand-all-abbrevs
                                         try-expand-list
                                         try-expand-line
                                         try-complete-lisp-symbol-partially
                                         try-complete-lisp-symbol))


;; Global Keybindings

;; use hippie-expand instead of dabbrev
(global-set-key (kbd "M-/") #'hippie-expand)
(global-set-key (kbd "s-/") #'hippie-expand)

;; replace buffer-menu with ibuffer
(global-set-key (kbd "C-x C-b") #'ibuffer)

;; align code in a pretty way
(global-set-key (kbd "C-x \\") #'align-regexp)

(define-key 'help-command (kbd "C-i") #'info-display-manual)

;; misc useful keybindings
(global-set-key (kbd "s-<") #'beginning-of-buffer)
(global-set-key (kbd "s->") #'end-of-buffer)
(global-set-key (kbd "s-q") #'fill-paragraph)
(global-set-key (kbd "s-x") #'execute-extended-command)

;; smart tab behavior - indent or complete
(setq tab-always-indent 'complete)

;; enable some commands that are disabled by default
(put 'erase-buffer 'disabled nil)


;; Setup
(use-package diminish
  :ensure t
  :config
  (diminish 'abbrev-mode)
  (diminish 'flyspell-mode)
  (diminish 'flyspell-prog-mode)
  (diminish 'eldoc-mode))


;; Buffers
;;; built-in packages
(use-package paren
  :straight nil
  :config
  (show-paren-mode +1))

(use-package elec-pair
  :straight nil
  :config
  (electric-pair-mode +1))

;; highlight the current line
(use-package hl-line
  :straight nil
  :config
  (global-hl-line-mode +1))

(use-package abbrev
  :straight nil
  :config
  (setq save-abbrevs 'silently)
  (setq-default abbrev-mode t))

(use-package uniquify
  :straight nil
  :config
  (setq uniquify-buffer-name-style 'forward)
  (setq uniquify-separator "/")
  ;; rename after killing uniquified
  (setq uniquify-after-kill-buffer-p t)
  ;; don't muck with special buffers
  (setq uniquify-ignore-buffers-re "^\\*"))

;; saveplace remembers your location in a file when saving files
(use-package saveplace
  :straight nil
  :config
  (setq save-place-file (expand-file-name "saveplace" path-cache-dir))
  ;; activate it for all buffers
  (setq-default save-place t))

(use-package savehist
  :straight nil
  :config
  (setq savehist-additional-variables
        ;; search entries
        '(search-ring regexp-search-ring)
        ;; save every minute
        savehist-autosave-interval 60
        ;; keep the home clean
        savehist-file (expand-file-name "savehist" path-cache-dir))
  (savehist-mode +1))

(use-package recentf
  :straight nil
  :config
  (setq recentf-save-file (expand-file-name "recentf" path-cache-dir)
        recentf-max-saved-items 500
        recentf-max-menu-items 15
        ;; disable recentf-cleanup on Emacs start, because it can cause
        ;; problems with remote files
        recentf-auto-cleanup 'never)
  (recentf-mode +1))


;; Navigation
(use-package dired
  :straight nil
  :config
  ;; dired - reuse current buffer by pressing 'a'
  (put 'dired-find-alternate-file 'disabled nil)

  ;; always delete and copy recursively
  (setq dired-recursive-deletes 'always)
  (setq dired-recursive-copies 'always)

  ;; if there is a dired buffer displayed in the next window, use its
  ;; current subdir, instead of the current subdir of this dired buffer
  (setq dired-dwim-target t)

  ;; enable some really cool extensions like C-x C-j(dired-jump)
  (require 'dired-x))

(use-package imenu-anywhere
  :ensure t
  :bind (("C-c i" . imenu-anywhere)
         ("s-i" . imenu-anywhere)))

(use-package selectrum
  :ensure t
  :config
  (selectrum-mode +1))

(use-package selectrum-prescient
  :ensure t
  :config
  (selectrum-prescient-mode +1)
  (prescient-persist-mode +1))

(use-package company
  :ensure t
  :config
  (setq company-idle-delay 0.5)
  (setq company-show-numbers t)
  (setq company-tooltip-limit 10)
  (setq company-minimum-prefix-length 2)
  (setq company-tooltip-align-annotations t)
  ;; invert the navigation direction if the the completion popup-isearch-match
  ;; is displayed on top (happens near the bottom of windows)
  (setq company-tooltip-flip-when-above t)
  (global-company-mode)
  (diminish 'company-mode))


;;Editor
;; Emacs modes typically provide a standard means to change the
;; indentation width -- eg. c-basic-offset: use that to adjust your
;; personal indentation width, while maintaining the style (and
;; meaning) of any files you load.
;;(setq-default indent-tabs-mode nil)   ;; don't use tabs to indent
;;(setq-default tab-width 8)            ;; but maintain correct appearance

;; Newline at end of file
;;(setq require-final-newline t)

(setq-default
 indent-tabs-mode nil
 tab-width 2
 require-final-newline t
 tab-always-indent t)

;; Wrap lines at 80 characters
(setq-default fill-column 80)

;; delete the selection with a keypress
(delete-selection-mode t)

(use-package avy
  :bind (("s-." . avy-goto-word-or-subword-1)
         ("s-," . avy-goto-char)
         ("C-c ." . avy-goto-word-or-subword-1)
         ("C-c ," . avy-goto-char)
         ("M-g f" . avy-goto-line)
         ("M-g w" . avy-goto-word-or-subword-1))
  :config
  (setq avy-background t))

;; easier to search
(setq-default
 search-default-mode #'char-fold-to-regexp
 replace-char-fold t)

(use-package anzu
  :ensure t
  :bind (("M-%" . anzu-query-replace)
         ("C-M-%" . anzu-query-replace-regexp))
  :config
  (global-anzu-mode))

(use-package move-text
  :ensure t
  :bind
  (([(meta shift up)] . move-text-up)
   ([(meta shift down)] . move-text-down)))


(defun editor-show-trailing-whitespace ()
  "Enable display of trailing whitespace in this buffer."
  (setq-local show-trailing-whitespace t))

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook 'editor-show-trailing-whitespace))

;; Formatting
(setq-default
 ;; `ws-butler' is used for better whitespace handling
 delete-trailing-lines nil
 sentence-end-double-space nil
 word-wrap t)

(use-package ws-butler
  :straight (ws-butler
             :type git
             :host github
             :repo "hlissner/ws-butler")
  :diminish
  :commands (ws-butler-global-mode)
  :init
  (ws-butler-global-mode)
  :config
  (setq ws-butler-global-exempt-modes
        (append ws-butler-global-exempt-modes
                '(special-mode comint-mode term-mode eshell-mode))))

(use-package crux
  :ensure t
  :bind (("C-c o" . crux-open-with)
         ("M-o" . crux-smart-open-line)
         ("C-c n" . crux-cleanup-buffer-or-region)
         ("C-c f" . crux-recentf-find-file)
         ("C-M-z" . crux-indent-defun)
         ("C-c u" . crux-view-url)
         ("C-c e" . crux-eval-and-replace)
         ("C-c w" . crux-swap-windows)
         ("C-c D" . crux-delete-file-and-buffer)
         ("C-c r" . crux-rename-buffer-and-file)
         ("C-c t" . crux-visit-term-buffer)
         ("C-c k" . crux-kill-other-buffers)
         ("C-c TAB" . crux-indent-rigidly-and-copy-to-clipboard)
         ("C-c I" . crux-find-user-init-file)
         ("C-c S" . crux-find-shell-init-file)
         ("s-r" . crux-recentf-find-file)
         ("s-j" . crux-top-join-line)
         ("C-^" . crux-top-join-line)
         ("s-k" . crux-kill-whole-line)
         ("C-<backspace>" . crux-kill-line-backwards)
         ("s-o" . crux-smart-open-line-above)
         ([remap move-beginning-of-line] . crux-move-beginning-of-line)
         ([(shift return)] . crux-smart-open-line)
         ([(control shift return)] . crux-smart-open-line-above)
         ([remap kill-whole-line] . crux-kill-whole-line)
         ("C-c s" . crux-ispell-word-then-abbrev)))

(use-package diff-hl
  :ensure t
  :config
  (global-diff-hl-mode +1)
  (add-hook 'dired-mode-hook 'diff-hl-dired-mode)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh))

(use-package flycheck
  :ensure t
  :config
  (add-hook 'after-init-hook #'global-flycheck-mode))

(use-package flycheck-eldev
  :ensure t)


(use-package flyspell
  :config
  (setq ispell-program-name "aspell" ; use aspell instead of ispell
        ispell-extra-args '("--sug-mode=ultra"))
  (add-hook 'text-mode-hook #'flyspell-mode)
  (add-hook 'prog-mode-hook #'flyspell-prog-mode))

(use-package which-key
  :ensure t
  :config
  (which-key-mode +1)
  (diminish 'which-key-mode))

(use-package undo-tree
  :ensure t
  :config
  ;; autosave the undo-tree history
  (setq undo-tree-history-directory-alist
        `((".*" . ,temporary-file-directory)))
  (setq undo-tree-auto-save-history t)
  (global-undo-tree-mode +1)
(diminish 'undo-tree-mode))

;; temporarily highlight changes from yanking, etc
(use-package volatile-highlights
  :ensure t
  :config
  (volatile-highlights-mode +1)
  (diminish 'volatile-highlights-mode))

(use-package hl-todo
  :ensure t
  :config
  (setq hl-todo-highlight-punctuation ":")
  (global-hl-todo-mode))

(use-package zop-to-char
  :ensure t
  :bind (("M-z" . zop-up-to-char)
         ("M-Z" . zop-to-char)))


;; Windows
(use-package windmove
  :straight nil
  :config
  ;; use shift + arrow keys to switch between visible buffers
  (windmove-default-keybindings))

(use-package easy-kill
  :ensure t
  :config
(global-set-key [remap kill-ring-save] 'easy-kill))

(use-package super-save
  :ensure t
  :config
  ;; add integration with ace-window
  (add-to-list 'super-save-triggers 'ace-window)
  (super-save-mode +1)
  (diminish 'super-save-mode))

(use-package ace-window
  :ensure t
  :config
  (global-set-key (kbd "s-w") 'ace-window)
  (global-set-key [remap other-window] 'ace-window))


;; UI
;; the toolbar is just a waste of valuable screen estate
;; in a tty tool-bar-mode does not properly auto-load, and is
;; already disabled anyway
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))

;; be quiet at startup; don't load or display anything unnecessary
(setq-default
 inhibit-startup-message t
 inhibit-startup-screen t
 inhibit-startup-echo-area-message user-login-name
 inhibit-default-init t
 initial-major-mode 'fundamental-mode
 initial-scratch-message nil
 use-file-dialog nil
 use-dialog-box nil)

;; disable cursort blinking
(blink-cursor-mode -1)

;; for some reason only this removes the clutter with xmonad
(use-package scroll-bar
  :straight nil
  :commands (scroll-bar-mode)
  :init
  (scroll-bar-mode -1))

;; y/n instead of yes/no
(fset #'yes-or-no-p #'y-or-n-p)

;; nice scrolling
(setq scroll-margin 0
      scroll-conservatively 100000
      scroll-preserve-screen-position 1)

;; mode line settings
(line-number-mode t)
(column-number-mode t)
(size-indication-mode t)

(setq-default
 ;; no beeping and no blinking please
 ring-bell-function #'ignore
 visible-bell nil

 ;; make sure that trash is not drawed
 indicate-buffer-boundaries nil
 indicate-empty-lines nil

 ;; don't resize emacs in steps, it looks weird and plays bad with
 ;; window manager.
 window-resize-pixelwise t
 frame-resize-pixelwise t

 ;; disable bidirectional text for tiny performance boost
 bidi-display-reordering nil

 ;; hide curosrs in other windows
 cursor-in-non-selected-windows nil)

;; maximize the initial frame automatically
;;(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; more useful frame title, that show either a file or a
;; buffer name (if the buffer isn't visiting a file)
(setq frame-title-format
      '((:eval (if (buffer-file-name)
                   (abbreviate-file-name (buffer-file-name))
                 "%b"))))

(when (and env-sys-mac? env-graphic?)
  (setq-default line-spacing 1)
  (add-to-list 'default-frame-alist '(font . "RobotoMono Nerd Font")))

(use-package modus-themes
  :if env-graphic?
  :init
  (setq-default
   modus-themes-diffs 'desaturated
   modus-themes-headings '((t . section))
   modus-themes-bold-constructs t
   modus-themes-syntax 'faint
   modus-themes-prompts 'subtle
   modus-themes-completions 'opionated)
  (load-theme 'modus-operandi t))

(use-package all-the-icons
  :defer t
  :commands (all-the-icons-material))

(use-package doom-modeline
  :init (doom-modeline-mode))


(use-package zenburn-theme
  :config
  ;;(load-theme 'zenburn t)
  )


;; Coding

(use-package rainbow-delimiters
  :ensure t)

(use-package rainbow-mode
  :ensure t
  :config
  (add-hook 'prog-mode-hook #'rainbow-mode)
  (diminish 'rainbow-mode))

(use-package lisp-mode
  :straight nil
  :config
  (defun bozhidar-visit-ielm ()
    "Switch to default `ielm' buffer.
Start `ielm' if it's not already running."
    (interactive)
    (crux-start-or-switch-to 'ielm "*ielm*"))

  (add-hook 'emacs-lisp-mode-hook #'eldoc-mode)
  (add-hook 'emacs-lisp-mode-hook #'rainbow-delimiters-mode)
  (define-key emacs-lisp-mode-map (kbd "C-c C-z") #'bozhidar-visit-ielm)
  (define-key emacs-lisp-mode-map (kbd "C-c C-c") #'eval-defun)
  (define-key emacs-lisp-mode-map (kbd "C-c C-b") #'eval-buffer)
  (add-hook 'lisp-interaction-mode-hook #'eldoc-mode)
  (add-hook 'eval-expression-minibuffer-setup-hook #'eldoc-mode))

(use-package ielm
  :straight nil
  :config
  (add-hook 'ielm-mode-hook #'eldoc-mode)
  (add-hook 'ielm-mode-hook #'rainbow-delimiters-mode))

(use-package elisp-slime-nav
  :ensure t
  :config
  (dolist (hook '(emacs-lisp-mode-hook ielm-mode-hook))
    (add-hook hook #'elisp-slime-nav-mode))
  (diminish 'elisp-slime-nav-mode))

(use-package buttercup
  :defer t)

(use-package paredit
  :ensure t
  :config
  (add-hook 'emacs-lisp-mode-hook #'paredit-mode)
  ;; enable in the *scratch* buffer
  (add-hook 'lisp-interaction-mode-hook #'paredit-mode)
  (add-hook 'ielm-mode-hook #'paredit-mode)
  (add-hook 'lisp-mode-hook #'paredit-mode)
  (add-hook 'eval-expression-minibuffer-setup-hook #'paredit-mode)
  (diminish 'paredit-mode "()"))

(use-package clojure-mode
  :ensure t
  :config
  (add-hook 'clojure-mode-hook #'paredit-mode)
  (add-hook 'clojure-mode-hook #'subword-mode)
  (add-hook 'clojure-mode-hook #'rainbow-delimiters-mode))

(use-package cider
  :ensure t
  :config
  (setq nrepl-log-messages t)
  (add-hook 'cider-mode-hook #'eldoc-mode)
  (add-hook 'cider-repl-mode-hook #'eldoc-mode)
  (add-hook 'cider-repl-mode-hook #'paredit-mode)
  (add-hook 'cider-repl-mode-hook #'rainbow-delimiters-mode))

(use-package magit
  :ensure t
  :bind (("C-x g" . magit-status)))

(use-package git-timemachine
  :ensure t
  :bind (("s-g" . git-timemachine)))

(use-package ag
  :ensure t)

(use-package web-mode
  :ensure t
  :custom
  (web-mode-markup-indent-offset 2)
  (web-mode-css-indent-offset 2)
  (web-mode-code-indent-offset 2)
  :config
  (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.hbs\\'" . web-mode)))

;;; bash shell
(defvar sh-builtin-keywords
  '("cat" "cat" "cd" "chmod" "chown" "cp" "curl" "date" "echo" "find"
    "git" "grep" "kill" "less" "ls" "make" "mkdir" "mv" "pgrep"
    "pkill" "pwd" "rm" "sleep" "sudo" "touch")
  "A list of common commands to be fontified in `sh-mode'.")

(use-package sh-script
  :straight nil
  :commands (sh-shell-process)
  :config
  ;; setup indentation
  (setq sh-indent-after-continuation 'always
        sh-basic-offset tab-width)

  ;; 1. Fontifies variables in double quotes
  ;; 2. Fontify command substitution in double quotes
  ;; 3. Fontify built-in/common commands (see `sh-builtin-keywords')
  (font-lock-add-keywords
   'sh-mode
   `((sh--match-variables-in-quotes
      (1 'font-lock-constant-face prepend)
      (2 'font-lock-variable-name-face prepend))
     (sh--match-command-subst-in-quotes
      (1 'sh-quoted-exec prepend))
     (,(regexp-opt sh-builtin-keywords 'words)
      (0 'font-lock-type-face append)))))

(use-package company-shell
  :after sh-script
  :config
  (add-to-list 'company-backends '(company-shell
                                   company-shell-env
                                   company-fish-shell))
  (setq company-shell-delete-duplicates t))

(defun sh--match-variables-in-quotes (limit)
  "Search for variables in double-quoted strings.
Search is bounded by LIMIT."
  (with-syntax-table sh-mode-syntax-table
    (let (res)
      (while
          (and
           (setq
            res
            (re-search-forward
             "[^\\]\\(\\$\\)\\({.+?}\\|\\<[a-zA-Z0-9_]+\\|[@*#!]\\)"
             limit
             t))
           (not (eq (nth 3 (syntax-ppss)) ?\"))))
      res)))

(defun sh--match-command-subst-in-quotes (limit)
  "Search for variables in double-quoted strings.
Search is bounded by LIMIT."
  (with-syntax-table sh-mode-syntax-table
    (let (res)
      (while
          (and (setq res
                     (re-search-forward
                      "[^\\]\\(\\$(.+?)\\|`.+?`\\)"
                      limit
                      t))
               (not (eq (nth 3 (syntax-ppss)) ?\"))))
      res)))


(defun sh-repl ()
  "Open a shell REPL."
  (let* ((dest-sh (symbol-name sh-shell))
         (sh-shell-file dest-sh)
         (dest-name (format "*shell [%s]*" dest-sh)))
    (sh-shell-process t)
    (with-current-buffer "*shell*"
      (rename-buffer dest-name))
    (get-buffer dest-name)))


;; config changes made through the customise UI will be stored here
(setq custom-file (expand-file-name "custom.el" path-emacs-dir))

(when (file-exists-p custom-file)
  (load custom-file))

(provide 'init)
;;; init.el ends here
