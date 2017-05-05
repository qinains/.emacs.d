;;; init.el --- 开发常用配置

;;; Commentary:
;; 请查看 README.md 文件

;;; Code:

;; 记录启动时间
(defconst emacs-start-time (current-time))

;; 40MB以后才进行垃圾回收(默认是 400000 )
(setq gc-cons-threshold 40000000)

;; 当打开超过100MB的文件的时候警告
(setq large-file-warning-threshold 100000000)

(setq inhibit-startup-screen t)

;; 最大化窗口
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; 手动初始化包
(setq package-enable-at-startup nil)
(package-initialize)

(defun melpa-package ()
  "设置melpa安装包链接."
  (setq package-archives '(("gnu" . "http://elpa.emacs-china.org/gnu/")
                           ("melpa" . "http://elpa.emacs-china.org/melpa/"))))

(defun melpa-stable-package ()
  "设置melpa-stable安装包链接."
  (setq package-archives '(("gnu" . "http://elpa.emacs-china.org/gnu/")
                           ("melpa-stable" . "http://elpa.emacs-china.org/melpa-stable/"))))

(melpa-package)

;; 稳定的安装包
(defvar melpa-stable-packages
  '(adoc-mode
    cider
    clj-refactor
    clojure-mode
    clojure-mode-extra-font-locking
    clojure-snippets
    company
    flycheck-pos-tip
    flx-ido
    magit
    magit-gitflow
    markdown-mode
    projectile
    rainbow-delimiters
    smartparens
    smex
    solarized-theme
    undo-tree
    web-mode))

;; 开发中的安装包
(defvar melpa-develop-packages
  '(company-flx
    company-go
    docker
    docker-api
    dockerfile-mode
    flycheck-clojure
    flycheck-gometalinter
    flymake-go
    go-eldoc
    go-mode
    go-projectile
    restclient
    sr-speedbar))

(defun install ()
  "Install the packages."
  (interactive)
  (package-initialize)
  (melpa-stable-package)
  (package-refresh-contents)
  (dolist (p melpa-stable-packages)
    (unless (package-installed-p p)
      (message "Installing %s" (symbol-name p))
      (package-install p)))

  (melpa-package)
  (package-refresh-contents)
  (dolist (p melpa-develop-packages)
    (unless (package-installed-p p)
      (message "Installing %s" (symbol-name p))
      (package-install p)))
  (message "All packages has installed."))

(defun update-packages ()
  "刷新包内容，更新包."
  (package-refresh-contents)
  (require 'epl)
  (epl-upgrade))

(defun update-stable-packages ()
  "只更新稳定的安装包."
  (interactive)
  (melpa-stable-package)
  (update-packages)
  (message "Stable-packages has updated."))

(defun update-develop-packages ()
  "只更新开发中的安装包."
  (interactive )
  (melpa-package)
  (package-refresh-contents)
  (require 'epl)
  (dolist (p melpa-develop-packages)
    (if (epl-package-outdated-p p)
        (progn
          (epl-package-install (epl-upgrade-available (car (epl-find-upgrades (epl-find-installed-packages p)))) 'force)
          (epl-package-delete (epl-upgrade-installed (car (epl-find-upgrades (epl-find-installed-packages p))))))))
  (message "Develop-packages has updated."))

(defun update ()
  "稳定版和开发版各更新到最新版本."
  (interactive)
  (update-stable-packages)
  (update-develop-packages)
  (message "All packages has updated."))

(defun loaded-time (name start-time)
  "统计NAME从START-TIME开始到现在所用的时间."
  (message "Loaded in %.3fs for %s" (float-time (time-since start-time)) name))

(defun indent-whole ()
  "格式化整个buffer，且避免光标位置移动."
  (interactive)
  (delete-trailing-whitespace)
  (untabify (point-min) (point-max))
  (indent-region (point-min) (point-max) nil))

(defmacro after-load (name &rest body)
  "`eval-after-load' NAME evaluate BODY."
  (declare (indent defun))
  `(eval-after-load ,name
     ',(append (list 'progn
                     `(let ((ts (current-time)))
                        ,@body
                        (loaded-time ,name ts))))))

(add-hook
 'emacs-startup-hook
 (lambda()
   (loaded-time "all-packages" emacs-start-time)))

;; 全局性设置 start

;; 记住关闭前光标的位置
(require 'saveplace)
(setq-default save-place t)

(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)

(add-hook
 'after-init-hook
 (lambda ()
   (message "after-init-hook")
   (when (not (version< emacs-version "24.1"))

     ;; 设置字体
     (set-frame-font "-outline-WenQuanYi Micro Hei Mono-normal-normal-normal-sans-13-*-*-*-p-*-iso8859-1")

     (tool-bar-mode -1)
     (scroll-bar-mode -1)
     (electric-indent-mode)
     (global-linum-mode))

   ;; 如果是windows系统
   (if (memq window-system '(w32))
       (progn
         ;; 修复https的git push不了的问题(私钥不能有密码)
         (setenv "GIT_ASKPASS" "git-gui--askpass")))

   ;; 光标显示为一竖线
   (setq-default cursor-type 'bar)

   ;; 设置标题栏显示文件的完整路径名
   (setq frame-title-format
         '("%S" (buffer-file-name "%f" (dired-directory dired-directory "%b"))))

   ;; C-x C-f后默认打开的文件夹
   (setq default-directory "~/")

   ;; 当要回答yes或no时，直接输入y或n
   (fset 'yes-or-no-p 'y-or-n-p)

   ;; 编码
   ;; 显示当前文件编码，C-h C (或者M-x describe-current-coding-system)
   ;; 如果打开的文件有乱码，还原成文件默认编码：C-x <RET> r <RET> (或者 M-x revert-buffer-with-coding-system)
   ;; 如果想转码，改变当前buffer的编码为UTF-8：C-x <RET> f utf-8 （或者 M-x set-buffer-file-coding-system）
   (prefer-coding-system 'utf-8)
   ;; 新建的文件都保存成UTF-8编码
   (setq buffer-file-coding-system 'utf-8)
   ;; tab键和新行自动缩进
   (setq-default indent-tabs-mode nil)
   (setq-default tab-width 4)
   (setq tab-width 4)
   (setq tab-stop-list ())
   (setq tab-stop-list '(4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120))

   (setq column-number-mode t)
   (setq size-indication-mode t)
   (setq visible-bell t)

   ;; C-c,C-v,C-x,C-z复制、粘贴、剪切、撤销
   (transient-mark-mode)
   (cua-mode)
   (setq cua-auto-tabify-rectangles nil)
   (setq cua-keep-region-after-copy t)
   (setq x-select-enable-clipboard t)
   (setq mouse-yank-at-point t)

   ;; Fix problem with cua-delete-region in Emacs 24.4
   ;; 参考http://pastebin.com/sDNqakF3
   (unless (fboundp 'cua-replace-region)
     (defun cua-replace-region ()
       "Replace the active region with the character you type."
       (interactive)
       (let ((not-empty (and cua-delete-selection (cua-delete-region))))
         (unless (eq this-original-command this-command)
           (let ((overwrite-mode
                  (and overwrite-mode
                       not-empty
                       (not (eq this-original-command 'self-insert-command)))))
             (cua--fallback))))))

   ;; 选择文字后输入文字，不再追加，而是直接替换
   (delete-selection-mode)

   (show-paren-mode)

   ;; 文件有更改时自动更新
   (global-auto-revert-mode)

   ;; 按键绑定
   (global-set-key (kbd "RET") 'newline-and-indent)
   (global-set-key (kbd "C-<return>") 'newline)

   ;; F4键弹出eshell
   (global-set-key [f4] 'eshell)

   ;; 按Shift+方向键即可切换窗口
   (when (fboundp 'windmove-default-keybindings)
     (windmove-default-keybindings))

   ;; 按C-M-\键格式化
   (global-set-key (kbd "C-M-\\") 'indent-whole)

   ;; 重写undo
   (global-undo-tree-mode)))

(add-hook
 'window-setup-hook
 (lambda ()
   (message "window-setup-hook")

   ;; ido
   (setq ido-enable-flex-matching t)
   (setq ido-use-faces nil)
   (ido-mode)
   (ido-everywhere)
   (flx-ido-mode)

   ;; 扩展M-x功能
   (smex-initialize)
   (global-set-key (kbd "M-x") 'smex)
   (global-set-key (kbd "M-X") 'smex-major-mode-commands)
   ;; 原配的M-x
   (global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

   ;; git管理
   (add-hook
    'magit-mode-hook
    ;;添加gitflow插件
    (lambda ()
      (turn-on-magit-gitflow)))
   (global-set-key [f12] 'magit-status)

   (rainbow-delimiters-mode-enable)
   (smartparens-strict-mode)
   (projectile-global-mode)
   (yas-global-mode)

   ;; 自动补齐
   (company-mode)
   (setq company-dabbrev-downcase nil)
   (setq company-dabbrev-ignore-case nil)
   (setq company-minimum-prefix-length 1)
   (setq company-show-numbers t)
   (company-flx-mode)
   (global-set-key "\t" 'company-complete-common)

   ;; 语法检查
   (flycheck-mode)))

;; 自动更换主题
(after-load "solarized-theme-autoloads"
  (defvar current-theme nil "当前的主题，防止刷新")
  (defun theme-auto-switch ()
    "Automatically switch between dark and light theme."
    (interactive)
    (let ((now (string-to-number (format-time-string "%H"))))
      (if (and (>= now 06) (<= now 18))
          (if (not (equal current-theme 'light))
              (progn
                (load-theme 'solarized-light t)
                (setq current-theme 'light)))
        (if (not (equal current-theme 'dark))
            (progn
              (load-theme 'solarized-dark t)
              (setq current-theme 'dark))))
      nil))
  (setq theme-timer (run-with-timer 0 (* 1 60) 'theme-auto-switch)))

;; 全局性设置 end

;; go 语言配置
(add-hook
 'go-mode-hook
 (lambda ()
   (message "go-mode-hook")
   (setq gofmt-command "goimports")
   (add-hook 'before-save-hook 'gofmt-before-save)

   (setq company-tooltip-limit 20)
   (setq company-idle-delay .25)
   (setq company-echo-delay 0)
   (setq company-begin-commands '(self-insert-command))
   (set (make-local-variable 'company-backends) '(company-go))

   (go-eldoc-setup)

   (go-guru-hl-identifier-mode)

   (setq flycheck-disabled-checkers
         '(go-gofmt
           go-golint
           go-vet
           go-build
           go-test
           go-errcheck))
   (add-hook 'flycheck-mode-hook #'flycheck-gometalinter-setup)))

;; clojure 语言配置
(add-hook
 'clojure-mode-hook
 (lambda ()
   (subword-mode)
   (eldoc-mode)

   (clj-refactor-mode)
   (cljr-add-keybindings-with-prefix "C-c RET")

   ;; cider
   (setq cider-repl-use-clojure-font-lock t)
   (setq cider-repl-wrap-history t)
   (setq nrepl-log-messages t)
   (setq cider-repl-history-size 3000)
   (setq cider-repl-history-file "~/.emacs.d/cider-history")
   (setq cider-refresh-show-log-buffer t)
   (add-hook 'cider-mode-hook #'eldoc-mode)
   (add-hook 'cider-repl-mode-hook #'subword-mode)
   (global-set-key (kbd "C-c C-z") 'cider-switch-to-repl-buffer)

   (flycheck-clojure-setup)))

(provide 'init)
;;; init.el ends here
