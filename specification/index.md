
# Specification overview

This project uses TOML files to represent configuration and actions to modify existing "components" (packages) in (remote) dist-git, into local (modified) dist-git format. This specification describes the format of the TOML files and exactly how a parser must parse them, as well as the specific modifications/actions to take to convert the (remote) dist-git content into local modified dist-git.

## Parsing the TOML file structure

The [parsing documentation](./parsing.md) details exactly how to parse the TOML files.

## Logical objects

The details on the top-level logical objects are [detailed here](./objects.md).
