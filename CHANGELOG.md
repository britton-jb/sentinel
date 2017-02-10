# Changelog
## 2.0.1
Updates documentation in README, and corrects mix install issue, and
fixes bug allowing users to login with multiple ueberauth strategies.

## 2.0.0
Too many changes to list. For the user should be considered a total
rewrite.

## 1.0.2
Thanks to commits from @Draiken

Added a debug log for the confirmation token to make working in dev
easier

Added a get route for user confirmation

Updated session controller bug failing to re-render new with errors

## 1.0.0
`Sentinel.AuthHandler` returns `401` instead of `403` - because I forgot
how to HTTP when writing this library initially

Updates a number of API endpoints to return different HTTP status
codes, more RESTFUL interface.

Lots of general codebase cleanup, thanks in part to
[@Draiken](https://github.com/Draiken), and due to the fact that I'm
becoming more comfortable with Elixir

Email handling is no longer case sensitive. Don't know how this bug got
past me, but now `username` is case sensitive, `email` is not. Added
specs to prevent regression

User rendering is now handled using a user view, rather than pure json,
to allow easy overriding

Updates to Ecto 2

Swapped out email system from `mailer` to
[ThoughtBot's](https://github.com/thoughtbot)
[Bamboo](https://github.com/thoughtbot/bamboo), because I trust their
team, and because I don't have to use a fork in order to get a working
testing utility

HTML Views added

## 0.1.0
Merges in @termoose's changes that declutter compilation output

Updates password reset with unknown email to always return 200, to
prevent malicious fishing for user emails

Adds invitable module, accessible by adding `invitible: true` to your
sentinel config

## 0.0.5
Makes `guardian_db` dependency optional

Updates controllers to use 201 status codes where appropriate

Updates Accounts Controller to render according to the `user_view`
config
