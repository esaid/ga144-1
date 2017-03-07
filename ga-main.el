;; -*- lexical-binding: t -*-
(add-to-list 'load-path "~/a/projects/ga144/aforth-mode") ;;TODO: remove
(add-to-list 'load-path "~/a/projects/ga144/")

(setq gc-cons-threshold most-positive-fixnum)

(setq debug-on-error t)
(setq load-start-time (current-time))

(setq bootstream? nil)
(setq bootstream-type "async")
(setq symbols? nil)
(setq pretty? nil)
(setq count? nil)
(setq hex? nil)
(setq in-file nil)
(setq byte-compile? nil)
(setq profile? nil)
(setq create-docs? nil)
(setq test? nil)

(require 'arg-parser)

(defun ga-print-help-and-exit ()
  (message "ga [--byte-compile, --create-docs, --test, [-b], [-s], [-p], [-x]] FILE")
  (kill-emacs))

(when (< (length command-line-args) 4)
  (ga-print-help-and-exit))

(parse-args '((("-b" "--bootstream") nil "include bootstream"
               (setq bootstream? t))
              (("--bootstream-type") (type) "bootstream type"
               (setq bootstream-type type))
              (("-s" "--symbols") nil "include symboltable"
               (setq symbols? t))
              (("-p" "--pretty") nil "print in human readable"
               (setq pretty? t))
              (("-c" "--count") nil "count ram usage"
               (setq count? t))
              (("-x" "--hex") nil  "print numbers in hexadecimal format"
               (setq hex? t))
              (("--byte-compile") nil  "byte compile .rkt files"
               (setq byte-compile? t))
              (("--profile") nil "save cpu profile data in file INFILE_profile"
               (setq profile? t))
              (("--create-docs") nil "generate documentation"
               (setq create-docs? t))
              (("--test") nil "run tests"
               (setq test? t))
              (("-h") nil "print usage"
               (ga-print-help-and-exit))
              (position (file) "aforth file"
                        (setq in-file file))
              )
            (cdddr command-line-args) t)

(when profile?
  (require 'profiler)
  (profiler-start 'cpu))

(require 'cl)
(put 'flet 'byte-obsolete-info nil) ;;prevent message "‘flet’ is an obsolete macro.."
(require 'rkt)
(rkt-require "ga-compile-print.rkt")
(require 'aforth-compile)
(require 'ga144-load)

(setq racket-script-mode t)

(message "load time: %s" (float-time (time-since load-start-time)))

(defun ga-byte-compile-files ()
  (setq lexical-binding t)
  (dolist (file '("compiler/bootstream.rkt"
                  "compiler/assemble.rkt"
                  "compiler/compile.rkt"
                  "compiler/disassemble.rkt"
                  "ga-compile-print.rkt"
                  "common.rkt"
                  "rom.rkt"
                  "rom-dump.rkt"
                  ))
    (rkt-byte-compile (expand-file-name file)))

  (dolist (file '("ga-main.el"
                  "aforth-mode/aforth-compile.el"
                  "aforth-mode/aforth-mode.el"
                  "aforth-mode/ga144-map.el"
                  "aforth-mode/aforth-parse.el"
                  "rkt.el"
                  ))
    (byte-compile-file (expand-file-name file))))

(defun ga-main-exit ()
  (when profile?
    (let ((profile-filename (concat "_profile_" (or in-file ""))))
      (profiler-report)
      (profiler-report-write-profile profile-filename)
      (message "saved profile data in file: '%s', view with M-x profiler-find-profile" profile-filename)
      ))
  (exit))

(when byte-compile?
  (setq _start-time (current-time))
  (require 'vc-git) ;; for vc-git-root, because basic-save-buffer calls vc-after-save, but why?

  ;;(dolist (file (set->list rkt-loaded-files))
  ;;  (rkt-byte-compile (expand-file-name file)))
  (ga-byte-compile-files)
  (message "byte-compile time: %s" (float-time (time-since _start-time)))
  (ga-main-exit))


(when create-docs?
  (require 'vc-git)
  (write-directive-docs "compiler-directives")
  (ga-main-exit))

(when test?
  (rkt-require "tests/test-compiler.rkt")
  (message (if (run-compiler-tests)
               "ok"
             "fail"))
  (ga-main-exit))

(progn ;;for .rkt compatibility
  (defun bootstream-type () bootstream-type)
  (defun symbols? () symbols?)
  (defun hex? () hex?))

(setq _start-time (current-time))

(if count?
    (print-count in-file)
  (if pretty?
      (print-pretty in-file hex?)
    (print-json in-file bootstream-type symbols?)))

(message "compile time: %s" (float-time (time-since _start-time)))




(ga-main-exit)
