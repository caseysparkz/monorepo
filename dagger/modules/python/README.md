# Python Dagger Module

This dagger module provides the following checks:

* **mypy**. Runs `mypy`.
* **pip-audit**. Runs `pip-audit`.
* **pylock**. Checks if `pylock.toml` is up-to-date.
* **pytest**. Runs `pytest`.
* **ruff-check**. Runs `ruff check`.
* **ruff-format**. Runs `ruff format --check`.

`mypy`, `pytest`, `ruff-check`, and `ruff-format` accept an optional `--file`
list of files/directories to run against (default: `.`).

The module accepts the following optional arguments:

* `--python-version`: Default `3.13`.
* `--py-path`: Default `.`.
* `--pkg`: Package to install. Default `.[all]`.
* `--source`: Defaults to the repository root directory.
