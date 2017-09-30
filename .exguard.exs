use ExGuard.Config

guard("Visual Studio compilation", run_on_start: true)
|> command("mix compile")
|> watch({~r{lib/(?<dir>.+)/(?<file>.+).ex$}i, fn m -> "test/#{m["lib_dir"]}/#{m["dir"]}/#{m["file"]}_test.exs" end})
|> ignore(~r{deps})

guard("Specs", run_on_start: true)
|> command("mix test --color")
|> watch(~r{(lib|test)/(?<dir>.+)/(?<file>.+)(.ex|_test.exs)$}i)
|> ignore(~r{deps})

guard("Dialyzer", run_on_start: true)
|> command("mix dialyzer")
|> watch(~r{lib/(?<dir>.+)/(?<file>.+).ex$}i)
|> ignore(~r{deps})

guard("Credo", run_on_start: true)
|> command("mix credo")
|> watch({~r{lib/(?<dir>.+)/(?<file>.+).ex$}i, fn m -> "test/#{m["lib_dir"]}/#{m["dir"]}/#{m["file"]}_test.exs" end})
|> ignore(~r{deps})
