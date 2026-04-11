# Mise Configuration

Global tool version management via [mise](https://mise.jdx.dev/).

## Config

- **`config.toml`** - Global tool versions (Python, Node, Go, Ruby)

## Installing Global npm Packages

Use `mise use -g` instead of `npx` for tools you want always available:

```bash
mise use -g npm:<package>@latest
```

To update later, run the same command again — mise will pull the newest version.

### Installed Global npm Packages

| Package | Description | Install |
|---------|-------------|---------|
| `@tokscale/cli` | Token usage and cost tracking across AI coding assistants (Claude Code, Cursor, Gemini CLI, etc.) | `mise use -g npm:@tokscale/cli@latest` |

## Resources

- [Mise Documentation](https://mise.jdx.dev/)
- [Mise Global Tools](https://mise.jdx.dev/configuration.html)
