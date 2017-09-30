# Roadmap
This is more notes about things that I'd like to change.

## Features
Dialyzer - figure out how to read it, fix them.

lib/mix/tasks/sentinel.gen.views.ex:61: The call 'Elixir.Mix.Phoenix':web_path(<<_:40>>) will never return since it differs in the 1st argument from the success typing arguments: (atom())
lib/mix/tasks/sentinel.gen.views.ex:69: The call 'Elixir.Mix.Phoenix':web_path(<<_:72>>) will never return since it differs in the 1st argument from the success typing arguments: (atom())
lib/sentinel/helpers/redirect_helper.ex:18: The call 'Elixir.Enum':map_join(params@1::any(),#{#<38>(8, 1, 'integer', ['unsigned', 'big'])}#,fun((_,_) -> <<_:8,_:_*8>>)) will never return since the success typing is (any(),binary(),fun((_) -> any())) -> binary() and the contract is (t(),'Elixir.String':t(),fun((element()) -> any())) -> 'Elixir.String':t()
lib/sentinel/schema/ueberauth.ex:56: Invalid type specification for function 'Elixir.Sentinel.Ueberauth':increment_failed_attempts/1. The success typing is (#{'__struct__':=atom(), 'failed_attempts':='false' | 'nil' | number(), atom()=>_}) -> {'ok',_}
lib/sentinel/schema/ueberauth.ex:64: Invalid type specification for function 'Elixir.Sentinel.Ueberauth':lock/1. The success typing is ({map(),map()} | #{'__struct__':=atom(), atom()=>_}) -> {'ok',atom() | #{'unlock_token':=binary(), 'user':=#{'__struct__'=>atom(), atom()=>_}, _=>_}}
lib/sentinel/web/controllers/html/unlock_controller.ex:24: The pattern {'ok', _auth@1} can never match the type #{'__meta__':=_, '__struct__':='Elixir.Sentinel.Ueberauth', 'expires_at':=_, 'failed_attempts':=_, 'hashed_password':=_, 'hashed_password_reset_token':=_, 'id':=_, 'inserted_at':=_, 'locked_at':=_, 'provider':=_, 'uid':=_, 'unlock_token':=_, 'updated_at':=_, 'user':=_, 'user_id':=_}
lib/sentinel/web/controllers/json/unlock_controller.ex:12: The pattern {'ok', _auth@1} can never match the type #{'__meta__':=_, '__struct__':='Elixir.Sentinel.Ueberauth', 'expires_at':=_, 'failed_attempts':=_, 'hashed_password':=_, 'hashed_password_reset_token':=_, 'id':=_, 'inserted_at':=_, 'locked_at':=_, 'provider':=_, 'uid':=_, 'unlock_token':=_, 'updated_at':=_, 'user':=_, 'user_id':=_}

Params nesting per readme?
Null warning per readme?

Can I simplify the configuration piece?
Can I remove the permissions stuff?

- Trackable?
- unconfirmed access number of days

- Enable username rather than email based accounts

- Easy socket auth handling

## Cleanup
- Credo strict
- typespecs
- improve generated docs
- excoveralls
- Extract shared logic from controllers into modules
- Use with instead of nested conditional code
- Rather than util send error use render view
