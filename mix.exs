defmodule Tmate.Mixfile do
  use Mix.Project

  def project do
    [app: :tmate,
     version: "0.1.1",
     elixir: "~> 1.8",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  # Type `mix help compile.app` for more information
  def application do
    [mod: {Tmate, []},
     applications: [:phoenix, :phoenix_html, :cowboy, :plug_cowboy, :logger,
                    :phoenix_ecto, :postgrex, :oauth2,
                    :uuid, :redix, :poolboy, :jason, :ecto_sql]]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [
      {:phoenix, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.3"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:poolboy, "~> 1.0"},
      {:oauth2, ">= 0.0.0"},
      {:uuid, "~> 1.1" },
      {:redix, ">= 0.0.0"},
      {:jason, ">= 0.0.0"},
      {:ex_machina, ">= 0.0.0", only: :test},
      {:cowboy, "~> 2.0"},
      {:plug_cowboy, ">= 0.0.0"},
      {:distillery, "~> 2.0"},
    ]
  end
end
