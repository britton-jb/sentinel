# Roadmap
This is less of a roadmap and more notes about things that I'd like to
change.

## Features
Update readme/docs on API redirect for user_invitation, unlock_account, password_update, user_confirmation

- lockable - 
  move lockable stuff to it's own controller like the passwords controller
  Resend unlock email view
  Unlock route
  unlock email
  specs - 5th attempt sends email out, able to use unlock route


  Dialyzer/typspecs
  Move to Ebert

- It should raise error at compile time if it can't find the
  appropriate root level mounted ueberauth routes - how can we do this?
  Otherwise may have to be runtime on the ueberauth routes

- Use with instead of nested conditional code

- Trackable?
- unconfirmed access number of days

- Enable username rather than email based accounts

- Easy socket auth handling

## Cleanup
- More robust mix task

- excoveralls

- Move the encode and sign stuff into a method that you can pipe into
  rather than having to do a case (auth controller)?
- Extract ueberauthenticate case into a method that you can pipe into?

- Rather than util send error use render view

- improve generated docs