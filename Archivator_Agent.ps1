<# =======================================================================
 Archivator_Agent.ps1 — Emergency Snapshot Archivator for Win11
 Author: Trianiuma
 Version: 0.1-emergency
 ======================================================================= #>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

param(
    # Исходная папка (откуда забираем данные)
    [string]$Source = "C:\Users\lkise\OneDrive\LAM\SRC.CHAT.Δ.01\Chat-GPT_archive\Chats",

    # Репозиторий "Trianiuma data base" (куда складываем снапшоты)
    [string]$Repo   = "C:\Users\lkise\OneDrive\LAM\Trianiuma.DataBase",

    # Произвольная метка для снапшота (например, 'EmergencyRestore')
    [string]$Label  = "EmergencySnapshot",

    # Вычислять SHA-256 для каждого файла (заметно медленнее на больших объёмах)
    [switch]$ComputeHash,

    # Создавать также ZIP архивацию payload (обычно не нужно для экстренного режима)
    [switch]$ZipPayload,

    # Принудительно снять "зависший" lock, если есть
    [switch]$Force,

    # Запуск без копирования/изменений (покажет, что БЫЛО БЫ сделано)
    [switch]$DryRun,

    # Кол-во дней хранения снапшотов (>0 — удаление старых)
    [int]$RetentionDays = 0,

    # Отключить любые git-операции (add/commit/push)
    [switch]$NoGit
)

# ------------------------------ Helpers ---------------------------------

function Write-Info($msg)  { Write-Host "[INFO]  $msg" }
function Write-Warn($msg)  { Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Ensure-Dir([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) {
        if ($DryRun) { Write-Info "DRY-RUN: mkdir `$path`" }
        else         { New-Item -ItemType Directory -Force -Path $path | Out-Null }
    }
}

function Get-RelativePath([string]$basePath, [string]$fullPath) {
    $base = (Resolve-Path -LiteralPath $basePath).Path.TrimEnd('\') + '\'
    $uriBase = New-Object System.Uri($base)
    $uriFull = New-Object System.Uri((Resolve-Path -LiteralPath $fullPath).Path)
    $rel = $uriBase.MakeRelativeUri($uriFull).ToString()
    return [System.Uri]::UnescapeDataString($rel).Replace('/','\')
}

function New-Lock([string]$lockPath, [switch]$Force) {
    if (Test-Path -LiteralPath $lockPath) {
        $age = (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc
        Write-Warn "Lock существует: $lockPath (mtime UTC: $age)"
        if (-not $Force) { throw "Lock already present. Use -Force to override." }
        else { Write-Warn "Принудительно снимаем lock (по -Force)..." ; Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    }
    if ($DryRun) { Write-Info "DRY-RUN: создаём lock $lockPath" }
    else {
        Set-Content -LiteralPath $lockPath -Value ("PID={0};UTC={1:o}" -f $PID, (Get-Date).ToUniversalTime()) -Encoding UTF8 -Force
    }
}
function Release-Lock([string]$lockPath) {
    if (Test-Path -LiteralPath $lockPath) {
        if ($DryRun) { Write-Info "DRY-RUN: удаляем lock $lockPath" }
        else { Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    }
}

# Список исключений
$ExcludeDirs  = @(".git", ".idea", ".vs", ".venv", "node_modules", "__pycache__", ".cache", ".mypy_cache")
$ExcludeFiles = @("Thumbs.db", "desktop.ini", "*.tmp", "*.temp", "*.bak", "~$*", "*.lnk")

# ------------------------------ Preconditions ---------------------------

try {
    if (-not (Test-Path -LiteralPath $Source)) { throw "Source not found: $Source" }
    Ensure-Dir $Repo
} catch {
    Write-Err $_
    exit 2
}

# ------------------------------ Snapshot Paths --------------------------

$utcNow      = (Get-Date).ToUniversalTime()
$stamp       = $utcNow.ToString("yyyy-MM-ddTHH-mm-ssZ")  # безопасно для NTFS
$year        = $utcNow.ToString("yyyy")
$yearMonth   = $utcNow.ToString("yyyy-MM")
$snapBase    = Join-Path $Repo "snapshots"
$snapDir     = Join-Path (Join-Path (Join-Path $snapBase $year) $yearMonth) ("{0}__{1}" -f $stamp, $Label)
$payloadDir  = Join-Path $snapDir "payload"
$manifestJson= Join-Path $snapDir "manifest.json"
$manifestMd  = Join-Path $snapDir "manifest.md"
$locksDir    = Join-Path $Repo "locks"
$lockPath    = Join-Path $locksDir "archivator_agent.lock"

try {
    Ensure-Dir $locksDir
    New-Lock -lockPath $lockPath -Force:$Force
} catch {
    Write-Err $_
    exit 3
}

try {
    Ensure-Dir $snapBase
    Ensure-Dir (Split-Path -Parent $snapDir)
    Ensure-Dir $snapDir
    Ensure-Dir $payloadDir
} catch {
    Write-Err "Не удалось подготовить директории снапшота: $snapDir"
    Release-Lock $lockPath
    exit 4
}

# ------------------------------ File Listing ----------------------------

Write-Info "Сканируем исходную папку: $Source"
$allFiles = Get-ChildItem -LiteralPath $Source -Recurse -File -Force -ErrorAction SilentlyContinue

# Фильтрация по каталогам-исключениям
$filtered = $allFiles | Where-Object {
    $dir = Split-Path -Parent $_.FullName
    $exclude = $false
    foreach ($ex in $ExcludeDirs) {
        if ($dir -replace '\\','\' -like ("*\" + $ex + "\*") -or ($dir -like ("*\" + $ex))) {
            $exclude = $true; break
        }
    }
    -not $exclude
} | Where-Object {
    $name = $_.Name
    $ok = $true
    foreach ($pattern in $ExcludeFiles) {
        if ($name -like $pattern) { $ok = $false; break }
    }
    $ok
}

$filesCount = ($filtered | Measure-Object).Count
$bytesTotal = ($filtered | Measure-Object -Sum Length).Sum
Write-Info "Будет обработано файлов: $filesCount, всего байт: $bytesTotal"

if ($filesCount -eq 0) {
    Write-Warn "Нет файлов для архивации после фильтрации. Завершение."
    Release-Lock $lockPath
    exit 0
}

# ------------------------------ Copy (robocopy) -------------------------

Write-Info "Копируем payload через robocopy..."
if ($DryRun) {
    Write-Info "DRY-RUN: robocopy `"$Source`" `"$payloadDir`" /E ..."
} else {
    $rcCmd = @(
        'robocopy',
        "`"$Source`"", "`"$payloadDir`"",
        '/E', '/COPY:DAT', '/DCOPY:T',
        '/R:2', '/W:5',
        '/NFL', '/NDL', '/NP', '/MT:8',
        '/XJ'
    )

    # Исключения файлов
    if ($ExcludeFiles.Count -gt 0) {
        $rcCmd += '/XF'
        $rcCmd += $ExcludeFiles
    }
    # Исключения директорий
    if ($ExcludeDirs.Count -gt 0) {
        $rcCmd += '/XD'
        $rcCmd += $ExcludeDirs
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'cmd.exe'
    $psi.Arguments = '/c ' + ($rcCmd -join ' ')
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $p = [System.Diagnostics.Process]::Start($psi)
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()

    Write-Host $stdout
    if ($stderr.Trim().Length -gt 0) { Write-Warn $stderr }

    # robocopy: 0–7 считаются успехом
    if ($p.ExitCode -gt 7) {
        Write-Err "robocopy завершился с кодом $($p.ExitCode)."
        Release-Lock $lockPath
        exit 5
    }
}

# ------------------------------ Manifest --------------------------------

Write-Info "Формируем манифест..."
$manifest = [ordered]@{
    tool                = "Archivator_Agent.ps1"
    version             = "0.1-emergency"
    snapshot_id         = Split-Path -Leaf $snapDir
    created_utc         = $utcNow.ToString("o")
    source_path         = $Source
    repo_path           = $Repo
    host                = $env:COMPUTERNAME
    user                = $env:USERNAME
    label               = $Label
    excluded_dirs       = $ExcludeDirs
    excluded_files      = $ExcludeFiles
    counts              = [ordered]@{
        files = $filesCount
        bytes = $bytesTotal
    }
    files               = @()
}

if ($ComputeHash) { Write-Info "Вычисляем SHA-256 (это может занять время)..." }

foreach ($f in $filtered) {
    $rel = Get-RelativePath -basePath $Source -fullPath $f.FullName
    $item = [ordered]@{
        rel_path   = $rel
        size       = $f.Length
        mtime_utc  = $f.LastWriteTimeUtc.ToString("o")
    }
    if ($ComputeHash) {
        try {
            $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop
            $item.sha256 = $h.Hash
        } catch {
            $item.sha256 = $null
            Write-Warn "Hash fail: $($f.FullName)"
        }
    }
    $manifest.files += $item
}

if ($DryRun) {
    Write-Info "DRY-RUN: пропускаем запись manifest.json/manifest.md"
} else {
    try {
        ($manifest | ConvertTo-Json -Depth 10) | Out-File -LiteralPath $manifestJson -Encoding utf8
        $md = @()
        $md += "# Snapshot: $($manifest.snapshot_id)"
        $md += ""
        $md += "- Created (UTC): $($manifest.created_utc)"
        $md += "- Source: `$($manifest.source_path)`"
        $md += "- Repo:   `$($manifest.repo_path)`"
        $md += "- Label:  $($manifest.label)"
        $md += "- Files:  $($manifest.counts.files)"
        $md += "- Bytes:  $($manifest.counts.bytes)"
        $md += ""
        $md += "Excluded dirs: " + ($ExcludeDirs -join ", ")
        $md += "Excluded files: " + ($ExcludeFiles -join ", ")
        $md += ""
        $mdText = ($md -join "`r`n")
        $mdText | Out-File -LiteralPath $manifestMd -Encoding utf8
    } catch {
        Write-Warn "Не удалось записать манифесты: $manifestJson / $manifestMd"
    }
}

# ------------------------------ Optional ZIP ----------------------------

if ($ZipPayload) {
    $zipPath = Join-Path $snapDir "payload.zip"
    if ($DryRun) {
        Write-Info "DRY-RUN: Compress-Archive '$payloadDir' -> '$zipPath'"
    } else {
        try {
            # Примечание: для очень длинных путей Compress-Archive может быть капризным.
            if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
            Compress-Archive -Path (Join-Path $payloadDir '*') -DestinationPath $zipPath -CompressionLevel Optimal -ErrorAction Stop
            Write-Info "ZIP создан: $zipPath"
        } catch {
            Write-Warn "Не удалось упаковать ZIP: $zipPath"
        }
    }
}

# ------------------------------ Git (optional) --------------------------

function Do-Git($args) {
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
    if ($e.Trim().Length -gt 0) { Write-Warn $e }
    return $p.ExitCode
}

if (-not $NoGit -and (Test-Path -LiteralPath (Join-Path $Repo ".git"))) {
    $gitExists = (Get-Command git -ErrorAction SilentlyContinue) -ne $null
    if ($gitExists) {
        Write-Info "Git-репозиторий обнаружен. Фиксируем снапшот."
        $relSnapPath = Get-RelativePath -basePath $Repo -fullPath $snapDir
        if (-not $DryRun) {
            [void](Do-Git "add -- `"$relSnapPath`"")
            $msg = "Archivator_Agent: $($manifest.snapshot_id) | $Label"
            [void](Do-Git "commit -m `"$msg`"")
            # Пытаемся аккуратно подтянуть и запушить
            [void](Do-Git "pull --rebase")
            [void](Do-Git "push")
        } else {
            Write-Info "DRY-RUN: git add/commit/push ($relSnapPath)"
        }
    } else {
        Write-Warn "git.exe не найден в PATH — пропускаем git-операции."
    }
} else {
    Write-Info "Git-операции отключены или .git не найдено — пропуск."
}

# ------------------------------ Prune -----------------------------------

if ($RetentionDays -gt 0) {
    Write-Info "Чистим снимки старше $RetentionDays дн."
    $limit = (Get-Date).AddDays(-$RetentionDays)
    $snapRoot = Get-ChildItem -LiteralPath $snapBase -Directory -Recurse -ErrorAction SilentlyContinue
    foreach ($dir in $snapRoot) {
        # Удаляем только конечные директории-снимки (где есть manifest.json)
        $mj = Join-Path $dir.FullName "manifest.json"
        if (Test-Path -LiteralPath $mj) {
            $mt = (Get-Item -LiteralPath $dir.FullName).LastWriteTime
            if ($mt -lt $limit) {
                if ($DryRun) { Write-Info "DRY-RUN: Remove '$($dir.FullName)'" }
                else {
                    try { Remove-Item -LiteralPath $dir.FullName -Recurse -Force }
                    catch { Write-Warn "Не удалось удалить: $($dir.FullName)" }
                }
            }
        }
    }
}

Write-Info "Готово: $snapDir"
Release-Lock $lockPath
exit 0
