defmodule FsBuild.MixProject do
  use Mix.Project

  @version "1.0.3"
  @name "FsBuild"
  @description "A filesystem-based build engine which provides a flexible mechanism for parsing and processing files."
  @source_url "https://github.com/cozy-elixir/fs_build"

  def project do
    [
      app: :fs_build,
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
      {:earmark, "~> 1.4", optional: true},
      {:makeup, "~> 1.0", optional: true},
      {:makeup_elixir, ">= 0.0.0", optional: true},
      {:ex_check, "~> 0.15.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.21", only: [:dev]},
      {:credo, ">= 0.0.0", only: [:dev], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["CHANGELOG.md"],
      main: "FsBuild",
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Zeke Dou", "Jos\351 Valim"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp aliases do
    [publish: ["hex.publish", "tag"], tag: &tag_release/1]
  end

  defp tag_release(_) do
    Mix.shell().info("Tagging release as v#{@version}")
    System.cmd("git", ["tag", "v#{@version}"])
    System.cmd("git", ["push", "--tags"])
  end
end
