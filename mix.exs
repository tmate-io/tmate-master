defmodule Tmate.Mixfile do
  use Mix.Project

  def project do
    [app: :tmate,
     version: "0.0.11",
     elixir: "~> 1.1",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {Tmate, []},
     applications: [:phoenix, :phoenix_html, :cowboy, :logger,
                    :phoenix_ecto, :postgrex, :oauth2, :rollbax,
                    :uuid, :redix, :edeliver]]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [{:phoenix, "~> 1.0.2"},
     {:phoenix_ecto, "~> 1.1"},
     {:postgrex, ">= 0.0.0"},
     {:phoenix_html, "~> 2.1"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:poolboy, "~> 1.0"},
     {:oauth2, ">= 0.0.0"},
     {:uuid, "~> 1.1" },
     {:redix, ">= 0.0.0"},
     {:rollbax, ">= 0.0.0"},
     {:exrm, ">= 0.0.0"},
     {:edeliver, ">= 0.0.0"},
     {:poison, "~> 1.0"},
     {:ex_machina, ">= 0.0.0", only: :test},
     {:cowboy, "~> 1.0"}]
  end
end
