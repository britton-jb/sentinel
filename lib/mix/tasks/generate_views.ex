defmodule Mix.Tasks.Sentinel.GenerateViews do
  @moduledoc """
  Used to generate sentinel views for customization
  """
  @shortdoc "Used to copy and configure sentinel views"

  use Mix.Task

  def run(args) do
    view_name = validate_arg!(args)
    view_module = view_module(view_name)

    views_path = Mix.Phoenix.web_path("views")
    templates_path = Mix.Phoenix.web_path("templates")
    binding = Mix.Phoenix.inflect(view_module)
    binding = Keyword.put(binding, :module, "#{binding[:web_module]}.#{binding[:scoped]}")

    Mix.Phoenix.check_module_name_availability!(binding[:module])

    Mix.Phoenix.copy_from paths(), "priv/templates/views", "", binding, [
      {:eex, "#{binding[:singular]}_template.ex", Path.join(views_path, "#{binding[:path]}.ex")}
    ]

    Mix.Phoenix.copy_from paths(), "lib/sentinel/web/templates", "", binding,
      template_files(templates_path, binding[:singular])

   Mix.shell.info """

    Update config.exs to set your custom views:

        config :sentinel,
          views: %{
            session: MyApp.Web.SessionView,
            user: MyApp.Web.UserView
          }
    """
  end

  @spec raise_with_help() :: no_return()
  defp raise_with_help do
    Mix.raise """
    mix sentinel.gen.views expects just the view name:
        mix sentinel.gen.views user

    Valid values are "email", "error", "password", "session", "shared", "user"
    """
  end

  defp validate_arg!([arg] = args) do
    if length(args) == 1 && Enum.find(valid_values, fn(x) -> x == arg end) do
      arg
    else
      raise_with_help()
    end
  end

  defp valid_values do
    ["email", "error", "password", "session", "shared", "user"]
  end

  defp view_module(name) when is_binary(name) do
    name
    |> String.downcase
    |> String.trim_trailing("view")
    |> String.capitalize
    |> Kernel.<>("View")
  end
  defp view_module(name), do: view_module(to_string(name))

  defp paths do
    Mix.Phoenix.generator_paths() ++ ["deps/sentinel", :sentinel]
  end

  defp template_files(templates_path, "email_view") do
    [
      {:text, "email/invite.html.eex", Path.join(templates_path, "email/invite.html.eex")},
      {:text, "email/invite.text.eex", Path.join(templates_path, "email/invite.text.eex")},
      {:text, "email/new_email_address.html.eex", Path.join(templates_path, "email/new_email_address.html.eex")},
      {:text, "email/new_email_address.text.eex", Path.join(templates_path, "email/new_email_address.text.eex")},
      {:text, "email/password_reset.html.eex", Path.join(templates_path, "email/password_reset.html.eex")},
      {:text, "email/password_reset.text.eex", Path.join(templates_path, "email/password_reset.text.eex")},
      {:text, "email/welcome.html.eex", Path.join(templates_path, "email/welcome.html.eex")},
      {:text, "email/welcome.text.eex", Path.join(templates_path, "email/welcome.text.eex")}
    ]
  end
  defp template_files(templates_path, "password_view") do
    [
      {:text, "password/edit.html.eex", Path.join(templates_path, "password/edit.html.eex")},
      {:text, "password/new.html.eex", Path.join(templates_path, "password/new.html.eex")}
    ]
  end
  defp template_files(templates_path, "session_view") do
    [
      {:text, "session/new.html.eex", Path.join(templates_path, "session/new.html.eex")}
    ]
  end
  defp template_files(templates_path, "shared_view") do
    [
      {:text, "shared/links.html.eex", Path.join(templates_path, "shared/links.html.eex")}
    ]
  end
  defp template_files(templates_path, "user_view") do
    [
      {:text, "user/confirmation_instructions.html.eex", Path.join(templates_path, "user/confirmation_instructions.html.eex")},
      {:text, "user/edit.html.eex", Path.join(templates_path, "user/edit.html.eex")},
      {:text, "user/invitation_registration.html.eex", Path.join(templates_path, "user/invitation_registration.html.eex")},
      {:text, "user/new.html.eex", Path.join(templates_path, "user/new.html.eex")}
    ]
  end
  defp template_files(templates_path, _), do: []
end
