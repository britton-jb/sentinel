defmodule SentinelTest do
  use Sentinel.UnitCase
  import CompileTimeAssertions
  alias Mix.Config

  setup_all do
    Config.persist([sentinel: [invitable: true]])
    Config.persist([sentinel: [invitation_registration_url: nil]])
    :ok
  end

  test "when using API in router, when using invitable, without configuring the invitable module" do
    assert_compile_time_raise RuntimeError, "Must configure :sentinel :invitation_registration_url when using sentinel invitable API", fn ->
      require Sentinel
      Sentinel.mount_api
    end
  end
end
