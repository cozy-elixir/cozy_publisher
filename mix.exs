defmodule CozyPublisher.MixProject do
  use Mix.Project

  @version "1.0.0"
  @name "CozyPublisher"
  @description "A minimal filesystem-based publishing engine with Markdown support and code highlighting."
  @source_url "https://github.com/cozy-elixir/cozy_publisher"

  def project do
    [
      app: :cozy_publisher,
      version: @version,
      elixir: "~> 1.12",
      deps: deps(),
      name: @name,
      description: @description,
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      package: package(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:earmark, "~> 1.4", only: [:dev, :test]},
      {:makeup, "~> 1.0", only: [:dev, :test]},
      {:makeup_elixir, ">= 0.0.0", only: [:dev, :test]},
      {:ex_check, "~> 0.15.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.21", only: [:dev]},
      {:credo, ">= 0.0.0", only: [:dev], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      main: "CozyPublisher",
      source_url: @source_url,
      source_ref: @version
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Zeke Dou", "José Valim"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp aliases do
    [publish: ["hex.publish", "tag"], tag: &tag_release/1]
  end

  defp tag_release(_) do
    Mix.shell().info("Tagging release as #{@version}")
    System.cmd("git", ["tag", @version])
    System.cmd("git", ["push", "--tags"])
  end
end
