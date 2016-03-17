# Changelog
## 0.0.6
Merges in @termoose's changes that declutter compilation output

Updates password reset with unknown email to always return 200, to
prevent malicious fishing for user emails

## 0.0.5
Makes `guardian_db` dependency optional

Updates controllers to use 201 status codes where appropriate

Updates Accounts Controller to render according to the `user_view`
config
