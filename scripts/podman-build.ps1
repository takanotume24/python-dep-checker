# Build the python-dep-checker container image with Podman.
#
# This script can be run from any directory; the repository root (the parent
# directory of this script) is always used as the build context.
#
# Environment variables:
#   PDC_IMAGE  Image name (default: python-dep-checker)

[CmdletBinding()]
param(
    [string] $Image,
    [switch] $NoCache,
    [switch] $Pull
)

$ErrorActionPreference = "Stop"

if (-not $Image) {
    $Image = if ($env:PDC_IMAGE) { $env:PDC_IMAGE } else { "python-dep-checker" }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$buildArguments = @(
    "build",
    "--tag", $Image,
    "--file", "Dockerfile"
)
if ($NoCache) {
    $buildArguments += "--no-cache"
}
if ($Pull) {
    $buildArguments += "--pull"
}
$buildArguments += "."

Push-Location $repoRoot
try {
    Write-Host "Building image '$Image' from $repoRoot ..."
    Write-Host "The first build downloads Nix and GHC, so it can take a while."
    & podman @buildArguments
    if ($LASTEXITCODE -ne 0) {
        Write-Host "podman build failed with exit code $LASTEXITCODE." -ForegroundColor Red
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}

Write-Host "Image '$Image' is ready." -ForegroundColor Green
