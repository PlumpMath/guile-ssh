;;; server.scm -- SSH server API.

;; Copyright (C) 2013 Artyom V. Poptsov <poptsov.artyom@gmail.com>
;;
;; This file is a part of libguile-ssh.
;;
;; libguile-ssh is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; libguile-ssh is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with libguile-ssh.  If not, see
;; <http://www.gnu.org/licenses/>.


;;; Commentary:

;; This module contains API that is used for SSH server.
;;
;; These methods are exported:
;;
;;   make-server
;;   server-accept
;;   server-set!
;;   server-listen!
;;   server-set-blocking!
;;   server-handle-key-exchange
;;   server-set-message-callback!
;;   server-message-get


;;; Code:

(define-module (ssh server)
  #:export (server
	    make-server
            server-accept
            server-set!
            server-listen!
            server-set-blocking!
            server-handle-key-exchange
            server-set-message-callback!
            server-message-get))

(load-extension "libguile-ssh" "init_server")

;;; server.scm ends here
