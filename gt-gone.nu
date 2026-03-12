#!/usr/bin/env nu

# gt-gone: Remove all traces of Graphite (gt) from your system.
# Dry-run by default — pass --run to execute.

def main [
  --run       # Actually execute removals (default: dry-run)
  --repos: string = "~/repos"  # Base directory to scan for repos
] {
  let repos_dir = ($repos | path expand)
  let dry = not $run
  let mode = if $dry { $"(ansi yellow_bold)DRY RUN(ansi reset)" } else { $"(ansi red_bold)LIVE(ansi reset)" }

  print $"(ansi cyan_bold)gt-gone(ansi reset) — remove all traces of Graphite"
  print $"Mode: ($mode)"
  print ""

  mut stats = { files_removed: 0, repos_cleaned: 0, gitconfig: false, windsurf_rule: false, brew_uninstall: false, brew_untap: false }

  # ── 1. Per-repo .git/.graphite_* files ──────────────────────────────
  print $"(ansi cyan_bold)① Scanning repos in ($repos_dir)(ansi reset)"

  let graphite_files = (
    glob $"($repos_dir)/**/.git/.graphite_*" --depth 4
  )

  if ($graphite_files | is-empty) {
    print "  No .graphite_* files found."
  } else {
    let repos_affected = (
      $graphite_files
      | each { path dirname | path dirname }
      | uniq
    )

    for file in $graphite_files {
      let rel = ($file | str replace $repos_dir "~")
      if $dry {
        print $"  (ansi yellow)would remove(ansi reset) ($rel)"
      } else {
        rm $file
        print $"  (ansi green)removed(ansi reset) ($rel)"
      }
    }

    $stats.files_removed = ($graphite_files | length)
    $stats.repos_cleaned = ($repos_affected | length)
  }

  print ""

  # ── 2. Global gitconfig [graphite] section ──────────────────────────
  print $"(ansi cyan_bold)② Global gitconfig(ansi reset)"

  let has_graphite_config = (
    do { git config --global --get-regexp '^graphite\.' } | complete
  )

  if ($has_graphite_config.exit_code == 0) {
    let entries = ($has_graphite_config.stdout | str trim)
    if $dry {
      print $"  (ansi yellow)would remove(ansi reset) [graphite] section:"
      print $"    ($entries)"
    } else {
      git config --global --remove-section graphite
      print $"  (ansi green)removed(ansi reset) [graphite] section"
    }
    $stats.gitconfig = true
  } else {
    print "  No [graphite] section found."
  }

  print ""

  # ── 3. Windsurf rule file ───────────────────────────────────────────
  print $"(ansi cyan_bold)③ Windsurf rules(ansi reset)"

  let windsurf_rule = ($repos_dir | path join "ismar.ch/.windsurf/rules/graphite.md")

  if ($windsurf_rule | path exists) {
    if $dry {
      print $"  (ansi yellow)would remove(ansi reset) ~/repos/ismar.ch/.windsurf/rules/graphite.md"
    } else {
      rm $windsurf_rule
      print $"  (ansi green)removed(ansi reset) ~/repos/ismar.ch/.windsurf/rules/graphite.md"
      print $"  (ansi faint)note: commit this removal in the ismar.ch repo(ansi reset)"
    }
    $stats.windsurf_rule = true
  } else {
    print "  No Windsurf graphite rule found."
  }

  print ""

  # ── 4. Homebrew uninstall ───────────────────────────────────────────
  print $"(ansi cyan_bold)④ Homebrew(ansi reset)"

  # Check if graphite formula is installed (NOT graphite2 the font library)
  let brew_graphite = (do { brew list graphite } | complete)

  if ($brew_graphite.exit_code == 0) {
    if $dry {
      print $"  (ansi yellow)would run(ansi reset) brew uninstall graphite"
    } else {
      brew uninstall graphite
      print $"  (ansi green)uninstalled(ansi reset) graphite"
    }
    $stats.brew_uninstall = true
  } else {
    print "  graphite formula not installed."
  }

  # Check for the tap
  let tap_exists = ("/opt/homebrew/Library/Taps/withgraphite" | path exists)

  if $tap_exists {
    if $dry {
      print $"  (ansi yellow)would run(ansi reset) brew untap withgraphite/tap"
    } else {
      brew untap withgraphite/tap
      print $"  (ansi green)untapped(ansi reset) withgraphite/tap"
    }
    $stats.brew_untap = true
  } else {
    print "  withgraphite/tap not present."
  }

  print ""

  # ── Summary ─────────────────────────────────────────────────────────
  print $"(ansi cyan_bold)Summary(ansi reset)"

  let verb = if $dry { "would be" } else { "were" }

  [
    [item action];
    [$"Repo files ($verb) removed" $stats.files_removed]
    [$"Repos ($verb) cleaned" $stats.repos_cleaned]
    ["Gitconfig section" (if $stats.gitconfig { if $dry { "would remove" } else { "removed" } } else { "not found" })]
    ["Windsurf rule" (if $stats.windsurf_rule { if $dry { "would remove" } else { "removed" } } else { "not found" })]
    ["Brew formula" (if $stats.brew_uninstall { if $dry { "would uninstall" } else { "uninstalled" } } else { "not installed" })]
    ["Brew tap" (if $stats.brew_untap { if $dry { "would untap" } else { "untapped" } } else { "not present" })]
  ] | table --theme rounded | print

  if $dry {
    print ""
    print $"(ansi yellow_bold)This was a dry run. Pass --run to execute.(ansi reset)"
  } else {
    print ""
    print $"(ansi green_bold)Done! Graphite has been removed.(ansi reset)"
  }
}
