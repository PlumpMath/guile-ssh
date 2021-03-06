;;; dist.scm -- Spirit of disrtibuted computing for Scheme.

;; Copyright (C) 2014, 2015, 2016, 2017 Artyom V. Poptsov <poptsov.artyom@gmail.com>
;;
;; This file is a part of Guile-SSH.
;;
;; Guile-SSH is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Guile-SSH is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Guile-SSH.  If not, see
;; <http://www.gnu.org/licenses/>.


;;; Commentary:

;; This module contains distributed forms of some useful procedures such as
;; 'map'.
;;
;; The module exports:
;;   distribute
;;   dist-map
;;   with-ssh
;;   rrepl
;;   make-node
;;   node?
;;   node-session
;;   node-repl-port
;;
;; See the Info documentation for the detailed description of these
;; procedures.


;;; Code:

(define-module (ssh dist)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 threads)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ssh session)
  #:use-module (ssh channel)
  #:use-module (ssh dist node)
  #:use-module (ssh dist job)
  #:re-export (node? node-session node-repl-port make-node with-ssh)
  #:export (distribute dist-map rrepl))


;;; Helper procedures

(define (flatten-1 lst)
  "Flatten a list LST one level down.  Return a flattened list."
  (fold-right append '() lst))

(define (format-warning fmt . args)
  (apply format (current-error-port) (string-append "WARNING: " fmt) args))

(define (format-error fmt . args)
  (apply format (current-error-port) (string-append "ERROR: " fmt) args))


(define (execute-job nodes job)
  "Execute a JOB, handle errors."
  (catch 'node-error
    (lambda ()
      (catch 'node-repl-error
        (lambda ()
          (hand-out-job job))
        (lambda args
          (format-error "In ~a:~%~a:~%~a~%" job (cadr args) (caddr args))
          (error "Could not execute a job" job))))
    (lambda args
      (format-warning "Could not execute a job ~a~%" job)
      (let ((nodes (delete (job-node job) nodes)))
        (when (null? nodes)
          (error "Could not execute a job" job))
        (format-warning "Passing a job ~a to a node ~a ...~%" job (car nodes))
        (execute-job nodes (set-job-node job (car nodes)))))))

(define (execute-jobs nodes jobs)
  "Execute JOBS on NODES, return the result."
  (flatten-1 (n-par-map (length jobs) (cut execute-job nodes <>) jobs)))


;;;


(define-syntax-rule (distribute nodes expr ...)
  "Evaluate each EXPR in parallel, using distributed computation.  Split the
job to nearly equal parts and hand out each of resulting sub-jobs to a NODES
list.  Return the results of N expressions as a set of N multiple values."
  (let* ((jobs    (assign-eval nodes (list (quote expr) ...)))
         (results (execute-jobs nodes jobs)))
    (when (null? results)
      (error "Could not execute jobs" nodes jobs))
    (apply values results)))

(define-syntax-rule (dist-map nodes proc lst)
  "Do list mapping using distributed computation.  The job is splitted to
nearly equal parts and hand out resulting jobs to a NODES list.  Return the
result of computation."
  (let* ((jobs    (assign-map nodes lst (quote proc)))
         (results (execute-jobs nodes jobs)))
    (when (null? results)
      (error "Could not execute jobs" nodes jobs))
    results))


(define (rrepl node)
  "Start an interactive remote REPL (RREPL) session using NODE."
  (let ((repl-channel (node-open-rrepl node)))
    (while (channel-open? repl-channel)
      (cond
       ((and (channel-open? repl-channel) (char-ready? repl-channel))
        (display (read-char repl-channel)))
       ((and (channel-open? repl-channel) (char-ready? (current-input-port)))
        (display (read-char (current-input-port)) repl-channel))
       (else
        (usleep 5000))))))

;;; dist.scm ends here


