;; one-buffer-one-frame.el
;; Functions to open buffers in their own frames
;;
;; Author: David Reitter, david.reitter@gmail.com
;; Maintainer: David Reitter
;; Keywords: aquamacs
 
;; Last change: $Id: one-buffer-one-frame.el,v 1.7 2005/07/19 11:13:53 davidswelt Exp $
;; This file is part of Aquamacs Emacs
;; http://aquamacs.org/

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

 ;;
;; Author: David Reitter, david.reitter@gmail.com
;; Maintainer: David Reitter
;; Keywords: aquamacs
 
;; Last change: $Id: one-buffer-one-frame.el,v 1.7 2005/07/19 11:13:53 davidswelt Exp $

;; This file is part of Aquamacs Emacs
;; http://aquamacs.org/

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
 
 

;; define customization option
(defcustom one-buffer-one-frame t
  "When non-nil, open a new frame for each new buffer and switch to that frame
   when buffer is selected from Buffers menu. When nil, regular buffers are displayed
   in the same frame and window."
  :type '(radio 
		(const :tag "Open new frames for buffers" t)
		(const :tag "standard Emacs behavior (nil)" nil))
  :group 'Aquamacs
  :require 'aquamacs-frame-setup)
 
(defvar one-buffer-one-frame-force nil 
  "Enforce one-buffer-one-frame - should be set only temporarily.")
 

(defun open-in-other-frame-p (buf)
  
  (or one-buffer-one-frame-force ;; set by color-theme
      (let ( (bufname (get-bufname buf)))
	(and one-buffer-one-frame 
		(if 
		    (member bufname
			    '(
			      "\*Completions\*" 
			      "\*Apropos\*" 
			      " SPEEDBAR" ; speedbar package opens its own frame
			      "\*Choices\*" ; for ispell
			      "\*Article\*" ; gnus
			      ))
		    nil
		  (or	
		   ;; return t if there is already text in window
		   (> (buffer-size (window-buffer)) 0)
		   ;; return nil if not special-display buffer 
		   (special-display-p (get-bufname (car args)))))))))
 
(defun killable-buffer-p (buf)
  
  (let ( (bufname (get-bufname buf))
	 )
 
   ; (if one-buffer-one-frame
	(if (or (equal "\*Messages\*" bufname) 
	      
		(equal  "\*scratch\*" bufname) 
		(equal  "\*Help\*" bufname) 
	      
		)
	    nil
      
	  t
	  )
      ;; if not one-buffer-one-frame
   ;   t ;;  used to be nil!
;	    )
    )
  )


; init
(setq aquamacs-newly-opened-frames '() )

;; only for certain special buffers

 

(if window-system
(defadvice switch-to-buffer (around sw-force-other-frame (&rest args) activate)
  ;; is buffer shown in a frame?
  (let ((switch t))
    (if one-buffer-one-frame
	(walk-windows
	 (lambda (w)
	   (when (equal (window-buffer w) (get-bufobj (car args)))
	     (setq switch nil)
	     (raise-frame (select-frame (window-frame w))))
	   ) t)) ;; t = include-hidden-frame (must be t) 
      
    (if switch
	(if (or (not (visible-frame-list))
		(not (frame-visible-p (selected-frame)))
		(open-in-other-frame-p (car args)))
 
	    (progn
	        
	      (apply #'switch-to-buffer-other-frame args)
	  
	      ;; store the frame/buffer information
	      (add-to-list 'aquamacs-newly-opened-frames 
			   (cons (selected-window) (current-buffer))) 
	       
	      ) 
	  ;; else : show in same frame
	  (if (window-dedicated-p (selected-window))
	      (apply #'switch-to-buffer-other-window args)
	    ;; else: show in same frame
	    ad-do-it))))
 
  (set-mode-specific-theme)))


;; some exception for the speedbar
;; this doesn't work, unfortunately
;; (add-hook 'speedbar-load-hook 
;; 	  (lambda ()
;; 	    (make-local-variable 'one-buffer-one-frame)
;; 	    (setq one-buffer-one-frame nil)
;; 	    )
;; )

;; less elegant, but it works:
(add-hook 'speedbar-load-hook (lambda ()
(defadvice speedbar-find-file 
  (around same-frame (&rest args) protect activate)
  
  (if one-buffer-one-frame 
      (progn
	(setq one-buffer-one-frame nil)
	(unwind-protect
	    ad-do-it
	  (setq one-buffer-one-frame t)
    
	  ))
    ad-do-it))))

 

;; make sure that when a minibuffer is ready to take input, 
;; the appropriate frame is raised (made visible)
;; using minibuffer-auto-raise globally has unpleasant results,
;; with frames losing focus all the time. speedbar doesn't work either.

(if window-system
(add-hook 'minibuffer-setup-hook 
	  (lambda () 
	    (if one-buffer-one-frame
		(raise-frame)))
)
)

;; we'd like to open new frames for some stuff
   
; one could make h-W just kill the buffer and then handle things here
; however, kill-buffer is called a lot for buffers that are not associated
; with a frame and we would need to make sure that only buffers for
; which a new frame was created will take their dedicated frame with
; them when they are killed!
; maybe the previous force-other-frame should keep track of
; newly opened frames!
 



; quit-window is usually called by some modes when the user enters 'q'
; e.g. in dired. we want to delete the window then.        
(if window-system
 (defadvice quit-window (around always-dedicated (&rest args) activate)
   (interactive)
   (if one-buffer-one-frame
       (let (save (window-dedicated-p (selected-window)))
	 (set-window-dedicated-p (selected-window) t)
	 ad-do-it
	 (set-window-dedicated-p (selected-window) save)
	 )
; else
     ad-do-it
     )
   )
)

 


(setq pop-up-frames nil)
(setq pop-up-windows t)
(setq display-buffer-reuse-frames t)

(if window-system
(defadvice pop-to-buffer (around always-dedicated (buf &rest args) protect activate) 
  (if one-buffer-one-frame
      (let ((puf pop-up-frames)
	    (sw (selected-window))
	    (wd (window-dedicated-p (selected-window)))
	    )
 
	(setq pop-up-frames (not 
			     (string-match "[ ]*\*(Completions|Apropos)\*" 
					   (get-bufname buf))
				 )
	      )
 
	(set-window-dedicated-p sw nil) 
	ad-do-it
	(set-window-dedicated-p sw wd)
	(setq pop-up-frames puf)

	)
    ;; else
    ad-do-it

    )
  )
 )

(defun aquamacs-delete-window (&optional window)
  "Remove WINDOW from the display.  Default is `selected-window'.
If WINDOW is the only one in its frame, then `delete-frame' too,
even if it's the only visible frame."
  (interactive)
  (setq window (or window (selected-window)))
  (select-window window)
  (if (one-window-p t)
      (aquamacs-delete-frame)
    (old-delete-window (selected-window))))
;; old-delete-window is the original emacs delete-window.


(defun delete-window-if-one-buffer-one-frame ()
  (if one-buffer-one-frame
      (delete-window-if-created-for-buffer)
    )
  )

(defun aquamacs-delete-frame (&optional frame)
  (condition-case nil 
      (delete-frame)
    (error   
	     
     (let ((f (frame or (selected-frame))))
       (make-frame-invisible f t)
       ;; select messages to it gets any input
       (if (find-all-frames-internal (get-buffer "*Messages*"))
	   (select-frame (car (find-all-frames-internal 
			       (get-buffer "*Messages*"))))))))
  ) 

;; delete window when buffer is killed
;; but only do so if aquamacs opened a new frame&window for
;; this buffer (e.g. during switch-to-buffer)

(defun delete-window-if-created-for-buffer ()

  
  (let (
	(buf (current-buffer))
	)
     
    (let ((winlist (find-all-windows-internal buf))
	   
	  )
        
      (mapc  
       (lambda (win)
					
	 ;;force deletion if buffer is not killable
	 (delete-window-if-created-for-this-buffer win buf t)
					; (not (killable-buffer-p buf)))
	 )
       winlist
       )
	 
	
      )
    )
 
)
     
(defun delete-window-if-created-for-this-buffer (win buf force)
  ;; used by osxkeys, too
  ;; as of now, we're always forcing the deletion of a window if the user requests it.
  ;; 
 
  (let ((elt (car (member (cons win buf)
			  aquamacs-newly-opened-frames))))
    (if (or force elt (window-dedicated-p win) )
	(progn
	  ;; remove entry from windows list
	  (if elt
	      (setq aquamacs-newly-opened-frames (delq elt aquamacs-newly-opened-frames))
	    )

	  ;; delete the window (or make the frame invisible)
	  
	  (condition-case nil 
	      (if (window-live-p win)
		  (delete-window win) ;; only get rid of that current window
		)
	    (error   
	     
	     (let ((f (selected-frame)))
	       (make-frame-invisible f t)
	        
	       (if (find-all-frames-internal (get-buffer "*Messages*"))
		   (select-frame (car (find-all-frames-internal 
				       (get-buffer "*Messages*")))))))))
      ;; else:
      ;; decide not to delete / make invisible
      ;; then switch buffer
      (if (and one-buffer-one-frame (get-buffer "*scratch*"))
	  (let ((one-buffer-one-frame))
	    (switch-to-buffer "*scratch*")
	    )
	  (next-buffer)))))


(if window-system
    (add-hook 'kill-buffer-hook 'delete-window-if-one-buffer-one-frame t)
  )
 
(defun close-current-window-asktosave (&optional force-delete-frame)
  "Delete current buffer, close selected window (and its frame
if `one-buffer-one-frame'. Beforehand, ask to save file if necessary."
  (interactive) 

  (select-frame-set-input-focus (selected-frame))
 
  (let ((wind (selected-window))
	(killable (and (killable-buffer-p (window-buffer))
		       ;; theoretically, we should check if, in case of force-delete-frame
		       ;; all windows display the same buffer, in which case it is killable again.
		       ;; practically, this situation shouldn't occur to often, so we skip
		       ;; that someone tedious check.

		       (eq (length (find-all-windows-internal 
				    (window-buffer) 
				    'only_visible_ones)) 
			   1))))
					; ask before killing
    (cond ( (and (eq (current-buffer) (window-buffer)) ;; only if a document is shown
		 killable
		 (eq   (string-match "\\*.*\\*" (buffer-name)) nil)
		 (eq   (string-match " SPEEDBAR" (buffer-name)) nil) ; has no minibuffer!
		 )
	    (cond ((buffer-modified-p)
		   (if (progn
			 (unless (minibuffer-window)
			   (setq last-nonmenu-event nil)
			   )
			 (aquamacs-yes-or-no-p "Save this buffer to file before closing window? ")
			 )
		       (progn
			 (save-buffer)
			 (message "File saved.")
			 )
					; mark as not modified, so it will be killed for sure
		     (set-buffer-modified-p nil)
		     ))
		  ((message ""))
		       
		  )      )
	  )
  
  
	
    ;; only if not a *special* buffer
    ;; if the buffer is shown in another window , just delete the current win
    (if one-buffer-one-frame
	(if
	    (if killable 
		(kill-buffer (window-buffer))    
	      t
	      )
	    ;; else
	    ;; always delete 
	    ;; unless user said "no"
	    (progn
	      (message "") 
	      ;; we don't want a message in the echo area of the next window!
	      (delete-window-if-created-for-this-buffer 
	       wind (window-buffer) t) 
	      )
	  )	
      ;; else not one-buffer=one-frame
      (progn
	(if killable  
	    (kill-buffer (window-buffer wind))   
	  )
	(when (window-live-p wind)
	  (if (or force-delete-frame ;; called via frame closer button
		  (window-dedicated-p wind)
		  )
	      (aquamacs-delete-frame (window-frame wind) ) ;; delete window/frame, hide if necessary
	    ;; else
	    (progn
	   
	      (select-window wind)
	      (if (one-window-p 'nomini 'only_selected_frame)
		  (if (not killable)
		      ;; if it's not killable, we need to jump to the next buffer
		      (next-buffer)
		    )
		(aquamacs-delete-window wind)
		)
	      )
	    )
	  )
	)
	 
      )
    )
  )

(if window-system
(defun handle-delete-frame (event)
  "Handle delete-frame events from the X server."
  (interactive "e")
  (let ((frame (posn-window (event-start event)))
	(i 0)
	(delw nil)
	)
    (select-frame frame)
     

    (while 
	(and (frame-first-window frame) 
	(window-live-p (frame-first-window frame))
	(select-window (frame-first-window frame))
	(setq delw (cons (frame-first-window frame) delw))
	
	(close-current-window-asktosave 'force-delete-window)
	 
	(frame-live-p frame)
	(next-window (selected-window) 'nominibuf frame)
	(not (memq  (frame-first-window frame) delw))
	)
      ) 
    )
  )
)
  

;; pressing q in a view should delete the frame
(aquamacs-set-defaults
 '((view-remove-frame-by-deleting t)))




;; make sure that C-mouse-1 menu acts locally
(if window-system
(defadvice mouse-buffer-menu (around select-buffer-same-frame (&rest args) activate) 
 (let ((one-buffer-one-frame nil))
   ad-do-it
) 
)
)
  


;; as a bugfix, we're redefining this
;; in order to create a new frame if all frames are invisible
(if window-system
(defun fancy-splash-frame ()
  "Return the frame to use for the fancy splash screen.
Returning non-nil does not mean we should necessarily
use the fancy splash screen, but if we do use it,
we put it on this frame."
  (let (chosen-frame)
   
    (mapc  
     (lambda (frame) (if (and (frame-visible-p frame)
			      (not (window-minibuffer-p 
				    (frame-selected-window frame))))
			 (setq chosen-frame frame)))
     ;; list:
     (append (frame-list) (list (selected-frame)))
     ) 
    (if chosen-frame
	chosen-frame
      
      (or
       ;; make visible
       (select-frame (car (frame-list))) 
       ;; or create a new one
       (make-frame)
       )
      )
    )
))

(if window-system
(defadvice fancy-splash-screens (around modify-frame (&rest args) activate)

  (let ( (default-frame-alist '( (tool-bar-lines . 0) (minibuffer . nil ) ) ) )
    ad-do-it
    )
  (message "") ;; workaround ("wrong argument")
))






(provide 'one-buffer-one-frame)