# AzeraKih-Plugins

A third-party Dalamud plugin repository. Not affiliated with the official plugin distribution.

## Installing (users)

`/xlsettings` → Experimental → Custom Plugin Repositories → add:

```
https://raw.githubusercontent.com/BlackScalesAuri/AzeraKih-Plugins/master/pluginmaster.json
```

Plugins listed here then show up in `/xlplugins` like any other, updates included. Dalamud
marks anything from a custom repo as third-party before you install it — that's expected.

## Layout

```
pluginmaster.json       - the repo index Dalamud actually polls
plugins/<Name>/latest.zip
scripts/Add-Plugin.ps1  - adds/updates one plugin's entry from its Release build
```

## Publishing a plugin here (author)

1. In the plugin's own project, bump `<Version>` in its `.csproj` — this becomes
   `AssemblyVersion` and is how Dalamud detects there's an update.
2. `dotnet build -c Release`.
3. From this repo:
   ```
   .\scripts\Add-Plugin.ps1 `
     -ReleaseOutputDir "<path to the plugin's bin\x64\Release>" `
     -RepoBaseUrl "https://raw.githubusercontent.com/BlackScalesAuri/AzeraKih-Plugins/master"
   ```
   This copies `latest.zip` into `plugins/<InternalName>/` and adds or updates that plugin's
   entry in `pluginmaster.json`.
4. Review the diff, commit, push.

Skipping step 1 means the zip changes but `AssemblyVersion` doesn't, so existing installs
won't see an update available.
