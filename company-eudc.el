;;; company-eudc.el --- Company-Mode Completion Backend for EUCD  -*- lexical-binding: t -*-

;; Copyright (C) 2020-2021 condition-alpha.com

;; Author: Alexander Adolf <emacs@condition-alpha.com>
;; Maintainer: Alexander Adolf <emacs@condition-alpha.com>
;; Package-Version: 1.0
;; Package-Requires: ((emacs "25.1") (company "0.9"))
;; Keywords: comm, abbrev, convenience, matching, mail
;; URL: https://github.com/condition-alpha/company-eudc

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;    This library provides an interface to EUDC for `company-mode'.
;;    EUDC is the Emacs Unified Directory Client, a common interface
;;    to directory servers and contact information, and part of core
;;    Emacs. EUDC can consult mutiple servers for each query,
;;    providing the combined results through a single interface. EUDC
;;    has backends for LDAP servers, and to the BBDB.

;;; Usage:
;;    (require 'company-eudc)
;;
;;    See `company-eudc-expand-inline' and
;;    `company-eudc-activate-autocomplete' for further details.

;;; Code:

;;{{{      Internal cooking

(require 'eudc)
(require 'company)
(require 'cl-lib)

(defun company-eudc--email-address-from-alist (rec)
  "Generate an email address string (\"first last <email>\") from the REC attribute list."
  (let* ((name (cdr (assoc 'name rec)))
	 (firstname (cdr (assoc 'firstname rec)))
	 (email (cdr (assoc 'email rec)))
	 (candidate ""))
    (if firstname
	(setq candidate (format "%s %s <%s>" firstname name email))
      (setq candidate (format "%s <%s>" name email)))
    candidate))

;;}}}

;;{{{      High-level interfaces

;;;###autoload
(defun company-eudc (command &optional arg &rest ignored)
  "Completion backend for EUDC for use with the company package.

EUDC is the Emacs Unified Directory Client, a common interface to
directory servers and contact information.

Completion will be attempted in the To, Cc, Bcc, From, and
Reply-To header fields of message buffers only.  I.e. you can not
use this backend for completing email addresses outside a message
header.

To load the `company-eudc' backend, simply do

    (require 'company-eudc)

With this alone, no completions from EUDC will be offered yet.
You will additionally need to decide how you want to use it.
Since EUDC can query remote resources (such as e.g. LDAP
servers), the completion process may take a while. Depending on
how you have configured the command `company-mode', this may
result in Emacs being blocked for extensive periods of time. To
accommodate this, the `company-eudc' backend can either install
itself into the list of company backends (see variable
`company-backends') for `message-mode' (see function
`company-eudc-activate-autocomplete'), or provide company
auto-completion through EUDC only when bound to a key (see
function `company-eudc-expand-inline').

For the semantics of COMMAND, ARG, and IGNORED see `company-backends'."
  (interactive (list 'interactive))
  (pcase command
    (`interactive (company-begin-backend #'company-eudc))
    (`prefix (and (derived-mode-p 'message-mode)
		  (let ((case-fold-search t))
		    (looking-back
		     "^\\([^ :]*-\\)?\\(To\\|B?Cc\\|From\\|Reply-to\\):.*? *\\([^,;]*\\)"
		     (line-beginning-position)))
		  (company-grab-symbol)))
    (`candidates (let* ((q-result (eudc-query `((name . ,arg)))))
		   (cl-loop for person-record in q-result
			    collect (company-eudc--email-address-from-alist
				     person-record))))
    (`match (let* ((start 0) (end 0) res)
              (while (setq start (string-match company-prefix arg end))
                (setq end (match-end 0))
                (push (cons start end) res))
              (nreverse res)))
    (`sorted t)
    (`ignore-case t)))

;;;###autoload
(defun company-eudc-activate-autocomplete ()
  "Provide `company-eudc' completions under company mode control.

This function installs `company-eudc' in the list of company
backends for `message-mode' (and will hence also work for modes
derived from it). Completion candidates from EUDC will thus be
offered by company mode as any other candidate.

To get this behaviour, do

    (require 'company-eudc)
    (company-eudc-activate-autocomplete)

If you have configured many and/or slow servers for EUDC, this
will block Emacs for some time (i.e. until EUDC has delivered its
results).  If this is a frequent issue, and you would like to
avoid this, use `company-eudc-expand-inline' instead."
  (interactive)
  (add-to-list 'company-backends #'company-eudc)
  (add-hook 'message-mode-hook
	    (lambda () (add-to-list 'company-backends #'company-eudc))))

;;;###autoload
(defun company-eudc-expand-inline ()
  "Provide `company-eudc' completions in `message-mode' modes interactively.

This function triggers company mode's completion at point, using
the `company-eudc' backend only. It is intended for being bound
to a key chord; for example:

    (require 'company-eudc)
    (with-eval-after-load \"message\"
      (define-key message-mode-map (kbd \"<C-tab>\") 'company-eudc-expand-inline))

This may be advantageous if you have configured many and/or slow
servers for EUDC. By deferring potentialliy lengthy EUDC queries
to a specific key chord, the waiting time for the EUDC results to
arrive will be incurred on your explicit request only, and will
not seemingly block the otherwise speedy company mode user
interface.

The advantage of binding `company-eudc-expand-inline' to a key,
instead of using `eudc-expand-inline' directly, is that
`company-eudc-expand-inline' uses the company mode user
interface, whereas `eudc-expand-inline' provides its own user
interface, and which is different from company mode's."
  (interactive)
  (company-begin-backend #'company-eudc))

;;}}}

(provide 'company-eudc)
;;; company-eudc.el ends here
