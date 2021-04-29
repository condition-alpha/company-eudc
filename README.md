# company-eudc
Company-Mode Completion Backend for EUDC

## What This Package Does

[`company-mode`](https://company-mode.github.io/) in conjunction with
[`yasnippet`](https://joaotavora.github.io/yasnippet/) makes composing
emails a breeze. Where things fall short, is the completion of email
addresses, however. Some Emacs MUA packages feed the addresses of
emails in your archive into the completion system. But what about
those in your contacts app, or those on the LDAP directory of your
organisation?

The [Emacs Unified Directory Client
(EUDC)](https://www.gnu.org/software/emacs/manual/html_mono/eudc.html),
which is part of core Emacs, can make information from your contacts
app, or from LDAP servers available. But there is no way of getting
these to be presented as completion candidates in `company-mode`.

`company-eudc` closes this gap by implementing a `comapny` back-end,
that retrieves names and email addresses from EUDC.

## Installation

Download `company-eudc.el` to somewhere in your `load-path`, and then
put

```elisp
(require 'company-eudc)
```

in your init file.

## Configuration

`company-eudc` does not have any adjustable parameters.

## Putting It to Use

After installation, nothing will happen yet. There are two ways in
which you can use `company-eudc`.

The **recommended way** is to bind the function
`company-eudc-expand-inline` to a key-chord in `message-mode-map`. For
example:

```elisp
(require 'company-eudc)
(with-eval-after-load "message"
  (define-key message-mode-map (kbd "<C-tab>") 'company-eudc-expand-inline))
```

If you now create a new email message (`C-x m`), put the cursor on a
header line where you are expected to enter an email address (for
instance "From:", or "To:"), type a couple of characters, and then
type the key-chord to invoke `company-eudc-expand-inline`.

The **alternative way** of using `company-eudc` is to not bind any
key-chord for it, but instead insert it into the list of company
backends. This can be achieved by putting this into your init file:

```elisp
(require 'company-eudc)
(company-eudc-activate-autocomplete)
```

This means that `company-eudc` will query EUDC each time
`company-mode` attempts to complete an email address. Depending on
your configuration, this can occur after each and every keystroke, and
Emacs will be blocked until the query returns. If the server(s) that
EUDC will query take some time to respond, this can be quite annoying,
because you cannot type until the query returns. Using
`company-eudc-activate-autocomplete` is thus recommended for those
specific situations only, where you are certain the EUDC queries will
return fast always.

## Things to Keep in Mind

`company-eudc` will only provide completion candidates if, and only
if, all of the following apply:

1. the major mode of the current buffer is `message-mode`, or a
   derived mode (e.g. `notmuch-message-mode`);

2. the cursor is on the line of a message header field that requires
   one or more email addresses (From, To, Cc, Bcc, or Reply-to).

This prevents most likely useless completion proposals with email
addresses when typing names in the body of an email message ("Dear
John, ..."), or in non email related modes.
