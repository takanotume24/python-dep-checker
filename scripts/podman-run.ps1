# Run python-dep-checker in a Podman container on Windows.
#
# The current directory is mounted at /work and every argument is forwarded to
# python-dep-checker. Backslashes are converted to slashes so that Windows-style
# relative paths such as examples\script.py work inside the Linux container.
#
# Environment variables:
#   PDC_IMAGE         Image name (default: python-dep-checker)
#   PDC_ALWAYS_BUILD  Set to 1/true/yes to rebuild the image before running
#   PDC_NO_BUILD      Set to 1/true/yes to never build the image automatically
#   PDC_MOUNT_SOURCE  Override the host directory mounted at /work

$ErrorActionPreference = "Stop"

$Image = if ($env:PDC_IMAGE) { $env:PDC_IMAGE } else { "python-dep-checker" }
$workDir = (Get-Location -PSProvider FileSystem).Path
$mountSource = if ($env:PDC_MOUNT_SOURCE) { $env:PDC_MOUNT_SOURCE } else { $workDir }

function Convert-ToolArgument {
    param([string] $Argument)

    $normalized = $Argument -replace '\\', '/'

    if ($normalized.StartsWith("--root=")) {
        $value = $normalized.Substring("--root=".Length)
        return "--root=" + (Convert-ToolArgument $value)
    }

    if ($normalized -notmatch '^[A-Za-z]:' -and -not $normalized.StartsWith("//")) {
        return $normalized
    }

    $mountPath = ($workDir -replace '\\', '/').TrimEnd('/')
    $mountPrefix = $mountPath + '/'
    $comparison = [System.StringComparison]::OrdinalIgnoreCase

    if ($normalized.Equals($mountPath, $comparison) -or
        $normalized.Equals($mountPrefix, $comparison)) {
        return "."
    }
    if ($normalized.StartsWith($mountPrefix, $comparison)) {
        return $normalized.Substring($mountPrefix.Length)
    }

    Write-Host "ERROR: '$Argument' is outside the current directory ($workDir)." -ForegroundColor Red
    Write-Host "The current directory is the only directory mounted at /work." -ForegroundColor Red
    Write-Host "Run the command from a directory that contains the file and use a relative path." -ForegroundColor Red
    exit 1
}

function Invoke-ImageBuild {
    $buildScript = Join-Path $PSScriptRoot "podman-build.ps1"
    & $buildScript -Image $Image
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$truthy = @("1", "true", "yes")

if ($truthy -contains $env:PDC_ALWAYS_BUILD) {
    Invoke-ImageBuild
}
else {
    & podman image exists $Image *> $null
    if ($LASTEXITCODE -ne 0) {
        if ($truthy -contains $env:PDC_NO_BUILD) {
            Write-Host "Container image '$Image' was not found." -ForegroundColor Red
            Write-Host "Build it first with: $(Join-Path $PSScriptRoot 'podman-build.cmd')" -ForegroundColor Red
            exit 1
        }
        Write-Host "Container image '$Image' was not found. Building it first ..." -ForegroundColor Yellow
        Invoke-ImageBuild
    }
}

$toolArguments = @()
foreach ($argument in $args) {
    $toolArguments += Convert-ToolArgument $argument
}

$podmanArguments = @(
    "run",
    "--rm",
    "--volume", "$($mountSource):/work",
    "--workdir", "/work",
    $Image
) + $toolArguments

& podman @podmanArguments
exit $LASTEXITCODE
