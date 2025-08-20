<# =======================================================================
 Archivator_Agent.ps1  —  Emergency Snapshot Archivator for Windows 11
 ASCII-safe version (no non-ASCII comments/strings)
 ======================================================================= #>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

param(
    [Parameter(Mandatory=$true)]
    [string]$Source,                   # folder to copy from

    [Parameter(Mandatory=$true)]
    [string]$Repo,                     # target repo with snapshots/

    [string]$Label = "EmergencySnapshot",

    [switch]$ComputeHash,              # calculate SHA-256 for each file
    [switch]$ZipPayload,               # also zip payload
    [switch]$Force,                    # force remove existing lock
    [switch]$DryRun,                   # show actions only
    [int]$RetentionDays = 0,           # prune old snapshots
    [switch]$NoGit                     # disable git ops
)

# ------------------------------ helpers ---------------------------------

function Info ($m) { Write-Host "[INFO]  $m" }
function Warn ($m) { Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function Err  ($m) { Write-Host "[ERROR] $m" -ForegroundColor Red }

function Ensure-Dir([string]$p) {
    if (-not (Test-Path -LiteralPath $p)) {
        if ($DryRun) { Info "DRY-RUN mkdir $p" }
        else { New-Item -ItemType Directory -Force -Path $p | Out-Null }
    }
}

function Get-RelPath([string]$basePath, [string]$fullPath) {
    $b = (Resolve-Path -LiteralPath $basePath).Path.TrimEnd('\') + '\'
    $ub = [Uri]$b
    $uf = [Uri]((Resolve-Path -LiteralPath $fullPath).Path)
    return [Uri]::UnescapeDataString($ub.MakeRelativeUri($uf).ToString()).Replace('/','\')
}

function New-Lock([string]$lockPath, [switch]$Force) {
    if (Test-Path -LiteralPath $lockPath) {
        $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
        Warn "Lock exists: $lockPath (mtime UTC: $age)"
        if (-not $Force) { throw "Lock already present. Use -Force to override." }
        else { Warn "Removing lock by -Force"; Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    }
    if ($DryRun) { Info "DRY-RUN create lock $lockPath" }
    else { Set-Content -LiteralPath $lockPath -Value ("PID={0};UTC={1:o}" -f $PID,(Get-Date).ToUniversalTime()) -Encoding UTF8 -Force }
}
function Release-Lock([string]$lockPath) {
    if (Test-Path -LiteralPath $lockPath) {
        if ($DryRun) { Info "DRY-RUN remove lock $lockPath" }
        else { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    }
}

$ExcludeDirs  = @(".git", ".idea", ".vs", ".venv", "node_modules", "__pycache__", ".cache", ".mypy_cache")
$ExcludeFiles = @("Thumbs.db", "desktop.ini", "*.tmp", "*.temp", "*.bak", "~$*", "*.lnk")

# ------------------------------ checks ----------------------------------

try {
    if (-not (Test-Path -LiteralPath $Source)) { throw "Source not found: $Source" }
    Ensure-Dir $Repo
} catch { Err $_ ; exit 2 }

# ------------------------------ paths -----------------------------------

$utcNow      = (Get-Date).ToUniversalTime()
$stamp       = $utcNow.ToString("yyyy-MM-ddTHH-mm-ssZ")
$year        = $utcNow.ToString("yyyy")
$yearMonth   = $utcNow.ToString("yyyy-MM")

$snapBase    = Join-Path $Repo "snapshots"
$snapDir     = Join-Path (Join-Path (Join-Path $snapBase $year) $yearMonth) ("{0}__{1}" -f $stamp,$Label)
$payloadDir  = Join-Path $snapDir "payload"
$manifestJson= Join-Path $snapDir "manifest.json"
$manifestMd  = Join-Path $snapDir "manifest.md"
$locksDir    = Join-Path $Repo "locks"
$lockPath    = Join-Path $locksDir "archivator_agent.lock"

try {
    Ensure-Dir $locksDir
    New-Lock -lockPath $lockPath -Force:$Force
} catch { Err $_ ; exit 3 }

try {
    Ensure-Dir $snapBase
    Ensure-Dir (Split-Path -Parent $snapDir)
    Ensure-Dir $snapDir
    Ensure-Dir $payloadDir
} catch {
    Err "Failed to prepare snapshot dirs: $snapDir"
    Release-Lock $lockPath
    exit 4
}

# ------------------------------ listing ---------------------------------

Info "Scanning: $Source"
$allFiles = Get-ChildItem -LiteralPath $Source -Recurse -File -Force -ErrorAction SilentlyContinue

$filtered = $allFiles | Where-Object {
    $dir = Split-Path -Parent $_.FullName
    $skip = $false
    foreach ($ex in $ExcludeDirs) {
        if ($dir -replace '\\','\' -like ("*\"+$ex+"\*") -or ($dir -like ("*\"+$ex))) { $skip = $true; break }
    }
    -not $skip
} | Where-Object {
    $name = $_.Name
    $ok = $true
    foreach ($p in $ExcludeFiles) { if ($name -like $p) { $ok=$false; break } }
    $ok
}

$filesCount = ($filtered | Measure-Object).Count
$bytesTotal = ($filtered | Measure-Object -Sum Length).Sum
Info "Files: $filesCount ; Bytes: $bytesTotal"

if ($filesCount -eq 0) {
    Warn "Nothing to archive after filters. Exit."
    Release-Lock $lockPath
    exit 0
}

# ------------------------------ copy ------------------------------------

Info "Copy payload via robocopy..."
if ($DryRun) {
    Info "DRY-RUN robocopy `"$Source`" `"$payloadDir`" /E ..."
} else {
    $rc = @('robocopy', "`"$Source`"", "`"$payloadDir`"", '/E','/COPY:DAT','/DCOPY:T','/R:2','/W:5','/NFL','/NDL','/NP','/MT:8','/XJ')
    if ($ExcludeFiles.Count -gt 0) { $rc += '/XF'; $rc += $ExcludeFiles }
    if ($ExcludeDirs.Count  -gt 0) { $rc += '/XD'; $rc += $ExcludeDirs  }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'cmd.exe'
    $psi.Arguments = '/c ' + ($rc -join ' ')
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $p = [System.Diagnostics.Process]::Start($psi)
    $out = $p.StandardOutput.ReadToEnd()
    $err = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    if ($out.Trim().Length -gt 0) { Write-Host $out }
    if ($err.Trim().Length -gt 0) { Warn $err }
    if ($p.ExitCode -gt 7) { Err "robocopy exitcode $($p.ExitCode)"; Release-Lock $lockPath; exit 5 }
}

# ------------------------------ manifest --------------------------------

Info "Build manifest..."
$manifest = [ordered]@{
    tool        = "Archivator_Agent.ps1"
    version     = "0.1a-ascii"
    snapshot_id = Split-Path -Leaf $snapDir
    created_utc = $utcNow.ToString("o")
    source_path = $Source
    repo_path   = $Repo
    host        = $env:COMPUTERNAME
    user        = $env:USERNAME
    label       = $Label
    excluded_dirs  = $ExcludeDirs
    excluded_files = $ExcludeFiles
    counts = [ordered]@{ files = $filesCount; bytes = $bytesTotal }
    files = @()
}

if ($ComputeHash) { Info "Hashing (SHA-256)..." }

foreach ($f in $filtered) {
    $rel = Get-RelPath -basePath $Source -fullPath $f.FullName
    $entry = [ordered]@{
        rel_path  = $rel
        size      = $f.Length
        mtime_utc = $f.LastWriteTimeUtc.ToString("o")
    }
    if ($ComputeHash) {
        try { $entry.sha256 = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash }
        catch { $entry.sha256 = $null ; Warn "Hash failed: $($f.FullName)" }
    }
    $manifest.files += $entry
}

if (-not $DryRun) {
    try {
        ($manifest | ConvertTo-Json -Depth 10) | Out-File -LiteralPath $manifestJson -Encoding utf8
        $md = @(
            "# Snapshot: $($manifest.snapshot_id)",
            "",
            "- Created (UTC): $($manifest.created_utc)",
            "- Source: `$($manifest.source_path)`",
            "- Repo:   `$($manifest.repo_path)`",
            "- Label:  $($manifest.label)",
            "- Files:  $($manifest.counts.files)",
            "- Bytes:  $($manifest.counts.bytes)",
            "",
            "Excluded dirs: " + ($ExcludeDirs -join ", "),
            "Excluded files: " + ($ExcludeFiles -join ", ")
        ) -join "`r`n"
        $md | Out-File -LiteralPath $manifestMd -Encoding utf8
    } catch { Warn "Failed to write manifest files." }
} else {
    Info "DRY-RUN: skip writing manifest files"
}

# ------------------------------ zip (opt) -------------------------------

if ($ZipPayload) {
    $zipPath = Join-Path $snapDir "payload.zip"
    if ($DryRun) { Info "DRY-RUN zip $zipPath" }
    else {
        try {
            if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
            Compress-Archive -Path (Join-Path $payloadDir '*') -DestinationPath $zipPath -CompressionLevel Optimal -ErrorAction Stop
            Info "ZIP created: $zipPath"
        } catch { Warn "ZIP failed: $zipPath" }
    }
}

# ------------------------------ git (opt) -------------------------------

function GitDo($args) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = $args
    $psi.WorkingDirectory = $Repo
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $p = [System.Diagnostics.Process]::Start($psi)
    $o = $p.StandardOutput.ReadToEnd()
    $e = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    if ($o.Trim().Length -gt 0) { Write-Host $o }
    if ($e.Trim().Length -gt 0) { Warn $e }
    return $p.ExitCode
}

if (-not $NoGit -and (Test-Path -LiteralPath (Join-Path $Repo ".git"))) {
    $hasGit = (Get-Command git -ErrorAction SilentlyContinue) -ne $null
    if ($hasGit) {
        Info "Git repo detected. Commit snapshot."
        $relSnap = Get-RelPath -basePath $Repo -fullPath $snapDir
        if (-not $DryRun) {
            [void](GitDo "add -- `"$relSnap`"")
            $msg = "Archivator_Agent: $($manifest.snapshot_id) | $Label"
            [void](GitDo "commit -m `"$msg`"")
            [void](GitDo "pull --rebase")
            [void](GitDo "push")
        } else { Info "DRY-RUN git add/commit/push ($relSnap)" }
    } else { Warn "git.exe not in PATH. Skip git operations." }
} else {
    Info "Git ops disabled or .git not found. Skip."
}

# ------------------------------ prune (opt) -----------------------------

if ($RetentionDays -gt 0) {
    Info "Prune snapshots older than $RetentionDays days."
    $limit = (Get-Date).AddDays(-$RetentionDays)
    $dirs = Get-ChildItem -LiteralPath $snapBase -Directory -Recurse -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        $mj = Join-Path $d.FullName "manifest.json"
        if (Test-Path -LiteralPath $mj) {
            $mt = (Get-Item -LiteralPath $d.FullName).LastWriteTime
            if ($mt -lt $limit) {
                if ($DryRun) { Info "DRY-RUN remove $($d.FullName)" }
                else { try { Remove-Item -LiteralPath $d.FullName -Recurse -Force } catch { Warn "Remove failed: $($d.FullName)" } }
            }
        }
    }
}

Info "Done: $snapDir"
Release-Lock $lockPath
exit 0
