# Roadmap
This is less of a roadmap and more notes about things that I'd like to
change.

## Features
- lockable
- Guardian plug wrapper to handle most cases?
- Use with instead of nested conditional code

- Trackable?
- unconfirmed access number of days

- Enable username rather than email based accounts

- Easy socket auth handling

## Cleanup
- It should raise error at run/compile time if it can't find the
  appropriate root level mounted ueberauth routes

- More robust mix task

- excoveralls
- ebert?
- typespecs?

- Move the encode and sign stuff into a method that you can pipe into
  rather than having to do a case (auth controller)?
- Extract ueberauthenticate case into a method that you can pipe into?

- Rather than util send error use render view

- improve generated docs
