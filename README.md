# gt-gone

Remove all traces of [Graphite](https://graphite.dev) (`gt`) from your system. Written in [Nushell](https://www.nushell.sh/).

## What it removes

1. **Per-repo files** — `.git/.graphite_*` (cache, PR info, repo config)
2. **Global gitconfig** — `[graphite]` section
3. **Windsurf rules** — `example/.windsurf/rules/graphite.md`
4. **Homebrew** — `graphite` formula + `withgraphite/tap` (leaves `graphite2` font library untouched)

## Usage

```nu
# Dry run (default) — shows what would happen
nu gt-gone.nu

# Actually remove everything
nu gt-gone.nu --run

# Custom repos directory
nu gt-gone.nu --repos ~/projects
```

## Requirements

- [Nushell](https://www.nushell.sh/) ≥ 0.100
- `git` (for gitconfig cleanup)
- `brew` (for formula/tap removal)
