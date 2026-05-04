# Mise Configuration

Global tool version management via [mise](https://mise.jdx.dev/).

## Config

- **`config.toml`** - Global tool versions (Python, Node, Go, Ruby)

## Installing Global npm Packages

Use `mise use -g` instead of `npx` for tools you want always available:

```bash
mise use -g npm:<package>@latest
```

## Updating a Global Installation

Re-run the install command with `@latest` — mise resolves the newest version and replaces the existing one:

```bash
mise use -g npm:<package>@latest
```

Example — updating `@tokscale/cli`:

```bash
mise use -g npm:@tokscale/cli@latest
```

To check what's currently installed:

```bash
mise ls
```

## Cleaning Up Old Versions

Updating leaves the previous version on disk. To remove versions no longer referenced by any config:

```bash
mise prune --dry-run   # preview what would be deleted
mise prune             # delete them
```

To uninstall a specific version manually:

```bash
mise uninstall npm:<package>@<version>
```

To remove a tool entirely (both from `config.toml` and disk):

```bash
mise rm -g npm:<package>
```

## Resources

- [Mise Documentation](https://mise.jdx.dev/)
- [Mise Global Tools](https://mise.jdx.dev/configuration.html)
