# Builds TextVault.exe from ..\TextVault and publishes it as a GitHub release.
# Usage: .\release.ps1 1.1.0 [-Notes "What changed"]
#        .\release.ps1 -Bump patch|minor|major [-Notes "What changed"]   (bumps the latest release tag)
param(
    [ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
    [ValidateSet('patch', 'minor', 'major')][string]$Bump,
    [string]$Notes = "Windows x64, self-contained single file."
)
$ErrorActionPreference = 'Stop'
$repo = 'TinTranParametrix/TextVault-release'

$gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
if (-not $gh) { $gh = "$env:ProgramFiles\GitHub CLI\gh.exe" }

if (-not $Version) {
    if (-not $Bump) { throw "Pass a version (e.g. 1.1.0) or -Bump patch|minor|major" }
    $latest = & $gh release view --repo $repo --json tagName --jq .tagName
    if ($LASTEXITCODE) { throw "Could not read the latest release" }
    $v = [version]$latest.TrimStart('v')
    $Version = switch ($Bump) {
        'major' { "$($v.Major + 1).0.0" }
        'minor' { "$($v.Major).$($v.Minor + 1).0" }
        'patch' { "$($v.Major).$($v.Minor).$($v.Build + 1)" }
    }
    Write-Host "$latest -> v$Version"
}

$proj = Join-Path $PSScriptRoot '..\TextVault\src\TextVault.App\TextVault.App.csproj'
$out  = Join-Path $PSScriptRoot 'publish'

dotnet publish $proj -c Release -r win-x64 -p:Platform=x64 -p:Version=$Version -o $out
if ($LASTEXITCODE) { throw "dotnet publish failed" }

& $gh release create "v$Version" (Join-Path $out 'TextVault.exe') --repo $repo --title "TextVault v$Version" --notes $Notes
if ($LASTEXITCODE) { throw "gh release create failed" }
