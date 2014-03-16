;; Aquamacs tools
;; some helper functions for Aquamacs
 
;; Author: David Reitter, david.reitter@gmail.com
;; Maintainer: David Reitter
;; Keywords: aquamacs
 
;; Last change: $Id: aquamacs-tools.el,v 1.2 2005/06/09 19:52:49 davidswelt Exp $

;; This file is part of Aquamacs Emacs
;; http://www.aquamacs.org/


;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.
 
;; Copyright (C) 2005, David Reitter


; remove an element from an associative list (alist) 
;; (defun remove-alist-name (name alist)
;;   "Removes element whose car is NAME from ALIST."
;;   (cond ((equal name (car (car alist)))	  ; found name
;;          (cdr alist))
;;         ((null alist)		; end of list (termination cond)
;;          nil)
;;         (t
;;          (cons (car alist)	; first of alist plus rest w/ recursion
;;                (remove-alist-name name (cdr alist))))))

;; this is assq
;; (defun get-alist-value-for-name (name alist)
;;   "Returns value of element whose car is NAME from ALIST. nil if not found"
;;   (cond ((equal name (car (car alist)))	  ; found name
;;          (cdr (car alist)))
;;         ((null alist)		; end of list (termination cond)
;;          nil)
;;         (t
;;           	; first of alist plus rest w/ recursion
;;           (get-alist-value-for-name name (cdr alist)))))

(defun assq-set (key val alist)
  (set alist (assq-delete-all key (eval alist)))
  (add-to-list alist (cons key  val))
) 

(defun assq-set-equal (key val alist)
  (set alist (assq-delete-all-equal key (eval alist)))
  (add-to-list alist (cons key  val))
) 

(defun assq-string-equal (key alist)
  
  (loop for element in alist 
        if (string-equal (car element) key)
	return element
	) 
  )




 
(defun assq-delete-all-equal (key alist)
  "Delete from ALIST all elements whose car is `equal' to KEY.
Return the modified alist.
Elements of ALIST that are not conses are ignored."
  (while (and (consp (car alist))
	      (equal (car (car alist)) key))
    (setq alist (cdr alist)))
  (let ((tail alist) tail-cdr)
    (while (setq tail-cdr (cdr tail))
      (if (and (consp (car tail-cdr))
	       (equal (car (car tail-cdr)) key))
	  (setcdr tail (cdr tail-cdr))
	(setq tail tail-cdr))))
  alist)



(defun get-bufname (buf)
   (if (eq (type-of buf) 'string)
		    buf
		  (buffer-name buf))
	
)
 
(defun get-bufobj (buf)
   (if (eq (type-of buf) 'string)
		   (get-buffer buf)
		  buf)
	
)

(defun find-all-windows-internal (buffer)
  "Find all windows that display a buffer."
  (let ((windows nil))
    (walk-windows (lambda (wind)
                     
		     (if (eq (window-buffer wind) buffer) 
			 (push wind windows))) t t)
    windows 
    )
)
; (find-all-frames-internal (current-buffer))
(defun find-all-frames-internal (buffer &optional onlyvis)
  (let ((frames nil)) 
    (walk-windows (lambda (wind)
		  
                     (if (eq (window-buffer wind) buffer)
			 (let ((frm (window-frame wind)))
			    
			   (unless (memq frm frames)
			     (push frm frames)))))
                  nil (if onlyvis 'visible t))
    frames))




(defun aquamacs-set-defaults (list)
  "Set a new default for a customization option in Aquamacs."

  (dolist (elt list)
    
	  (progn 
	    (let ((symbol (car elt))
		  (value (car (cdr elt))))
	      (set symbol value)

; make sure that user customizations get saved to customizations.el (.emacs)
	      (put symbol 'standard-value (list (eval symbol)))
	    )
	  )

	  )
  )


(defun url-encode-string (string &optional coding)
  "Encode STRING by url-encoding.
Optional CODING is used for encoding coding-system."
  (apply (function concat)
	 (mapcar
	  (lambda (ch)
	    (cond
	     ((eq ch ?\n)		; newline
	      "%0D%0A")
	     ((string-match "[-a-zA-Z0-9_:/.]" (char-to-string ch))
	      (char-to-string ch))	; printable
	     ((char-equal ch ?\x20)	; space
	      "%20")
	     (t
	      (format "%%%02x" ch))))	; escape
	  ;; Coerce a string to a list of chars.
	  (append (encode-coding-string (or string "")
					(or coding
					    file-name-coding-system))
		  nil))))

(provide 'aquamacs-tools)
