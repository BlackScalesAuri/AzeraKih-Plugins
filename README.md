# AzeraKih-Plugins

A third-party Dalamud plugin repository. Not affiliated with the official plugin distribution.

## Installing (users)

`/xlsettings` → Experimental → Custom Plugin Repositories → add:

```text
https://raw.githubusercontent.com/BlackScalesAuri/AzeraKih-Plugins/master/pluginmaster.json
```

Plugins listed here then show up in `/xlplugins` like any other, updates included. Dalamud
marks anything from a custom repo as third-party before you install it — that's expected.

## How this repo works

Plugins don't live here — each has its own repo with normal GitHub Releases. This repo just
aggregates them:

- `plugins.json` — one entry per plugin: `{ username, repo, branch, configFolder }`, pointing
  at its GitHub repo.
- `generate-repo.ps1` — for each entry, fetches that repo's latest Release (download link,
  publish date, download count) and the manifest committed there at
  `<configFolder>/<repo>.json`, merges them, and writes `pluginmaster.json`.
- `pluginmaster.json` — generated output, this is what Dalamud actually polls. Don't hand-edit
  it; it gets overwritten.
- `.github/workflows/generate_repo.yaml` — reruns the script automatically every 12 hours, on
  manual trigger, or when a plugin repo pings this one via `repository_dispatch`.

## Adding a plugin

1. The plugin needs its own repo with:
   - A manifest committed at `<PluginName>/<PluginName>.json` (the same file `DalamudPackager`
     generates on a Release build — copy it in, keeping `AssemblyVersion` in sync whenever you
     bump the version).
   - A GitHub Release per version, with the built zip attached as the (only) release asset.
     See [HideBeasts's release workflow](https://github.com/BlackScalesAuri/HideBeasts/blob/master/.github/workflows/release.yaml)
     for a tag-triggered example that builds and attaches it automatically.
2. Add one entry for it to `plugins.json` here, commit, push.
3. Either wait for the next scheduled run, or trigger it now:

   ```sh
   gh workflow run generate_repo.yaml --repo BlackScalesAuri/AzeraKih-Plugins
   ```

## Getting a plugin's release to notify this repo immediately

Instead of waiting up to 12 hours: in the plugin's own repo, create a fine-grained GitHub PAT
scoped to this repo (`AzeraKih-Plugins`) with "Contents: Read and write", store it there as a
secret named `DISPATCH_TOKEN`, and have its release workflow POST to
`repos/BlackScalesAuri/AzeraKih-Plugins/dispatches` with `event_type: new-release` once the
release is created. HideBeasts's workflow already does this — it just needs that secret set:

```sh
gh secret set DISPATCH_TOKEN --repo BlackScalesAuri/HideBeasts
```
