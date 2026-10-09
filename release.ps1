# Builds TextVault.exe from ..\TextVault and publishes it as a GitHub release.
# Usage: .\release.ps1 1.1.0 [-Notes "What changed"]
param(
    [Parameter(Mandatory)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
    [string]$Notes = "Windows x64, self-contained single file."
)
$ErrorActionPreference = 'Stop'

$gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
if (-not $gh) { $gh = "$env:ProgramFiles\GitHub CLI\gh.exe" }

$proj = Join-Path $PSScriptRoot '..\TextVault\src\TextVault.App\TextVault.App.csproj'
$out  = Join-Path $PSScriptRoot 'publish'

dotnet publish $proj -c Release -r win-x64 -p:Platform=x64 -p:Version=$Version -o $out
if ($LASTEXITCODE) { throw "dotnet publish failed" }

& $gh release create "v$Version" (Join-Path $out 'TextVault.exe') --repo TinTranParametrix/TextVault-release --title "TextVault v$Version" --notes $Notes
if ($LASTEXITCODE) { throw "gh release create failed" }
