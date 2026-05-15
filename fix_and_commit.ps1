<#
.SYNOPSIS
  掃描並將文字檔轉為 UTF-8 (no BOM)，安裝 dev 依賴，執行 pre-commit，commit 並 push。

.PARAMETER DryRun
  指定後僅列出會被處理的檔案與動作，不會修改檔案或執行 git commit/push。
#>

param([switch]$DryRun)

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

Info "開始腳本（DryRun=$DryRun）"

# 建議：若工作目錄有未提交變更，先 stash 或切到新分支
$gitStatus = git status --porcelain 2>$null
if ($gitStatus) {
  Warn "工作目錄有未提交變更，建議先 stash 或切分支再執行。"
}

# 掃描檔案（排除 .git）
Info "掃描專案檔案（尋找 UTF-16 或含 UTF-8 BOM 的檔案）..."
$files = Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\.git\\' -and $_.Length -gt 0 }
$toConvert = @()
foreach ($f in $files) {
  try {
    $b = [System.IO.File]::ReadAllBytes($f.FullName)
    if ($b.Length -ge 2 -and $b[0] -eq 0xFF -and $b[1] -eq 0xFE) { $toConvert += [PSCustomObject]@{Path=$f.FullName;Type='UTF-16-LE'} }
    elseif ($b.Length -ge 2 -and $b[0] -eq 0xFE -and $b[1] -eq 0xFF) { $toConvert += [PSCustomObject]@{Path=$f.FullName;Type='UTF-16-BE'} }
    elseif ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { $toConvert += [PSCustomObject]@{Path=$f.FullName;Type='UTF-8-BOM'} }
  } catch { }
}

if (-not $toConvert) {
  Info "未發現需要轉碼的檔案。"
} else {
  Info "發現需要轉碼的檔案："
  $toConvert | ForEach-Object { Write-Host "$($_.Type)  $($_.Path)" }
}

if ($DryRun) {
  Info "DryRun 模式，腳本到此結束（不會修改檔案或提交）。"
  exit 0
}

# 實際轉檔
if ($toConvert) {
  Info "開始轉檔（以 UTF-8 無 BOM 覆寫原檔）..."
  foreach ($item in $toConvert) {
    try {
      $p = $item.Path
      $b = [System.IO.File]::ReadAllBytes($p)
      if ($b.Length -ge 2 -and $b[0] -eq 0xFF -and $b[1] -eq 0xFE) { $text = [System.Text.Encoding]::Unicode.GetString($b) }
      elseif ($b.Length -ge 2 -and $b[0] -eq 0xFE -and $b[1] -eq 0xFF) { $text = [System.Text.Encoding]::BigEndianUnicode.GetString($b) }
      elseif ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { $text = [System.Text.Encoding]::UTF8.GetString($b,3,$b.Length-3) }
      else { try { $text = [System.Text.Encoding]::UTF8.GetString($b) } catch { $text = [System.Text.Encoding]::Unicode.GetString($b) } }
      [System.IO.File]::WriteAllText($p, $text, (New-Object System.Text.UTF8Encoding($false)))
      Info "已轉檔: $p"
    } catch {
      Err "轉檔失敗: $p  錯誤: $_"
    }
  }
} else {
  Info "沒有需要轉檔的檔案，跳過轉檔步驟。"
}

# 安裝開發依賴（若存在 requirements-dev.txt）
$req = Join-Path (Get-Location) 'requirements-dev.txt'
if (Test-Path $req) {
  Info "安裝開發依賴：requirements-dev.txt"
  python -m pip install --upgrade pip
  python -m pip install -r $req
} else {
  Warn "找不到 requirements-dev.txt，跳過安裝。"
}

# 執行 pre-commit
Info "執行 pre-commit run --all-files"
pre-commit run --all-files
if ($LASTEXITCODE -ne 0) {
  Err "pre-commit 有錯誤，請先修正再執行腳本。"
  exit 1
}

# git add / commit / push
Info "將變更加入暫存並提交到遠端"
git add -A
$status = git status --porcelain
if (-not $status) {
  Info "沒有變更需要提交。"
} else {
  git commit -m "Normalize encodings, run pre-commit and apply fixes"
  if ($LASTEXITCODE -ne 0) {
    Err "git commit 失敗，請檢查錯誤訊息。"
    exit 1
  }
  git push
  if ($LASTEXITCODE -ne 0) {
    Err "git push 失敗，請檢查遠端權限或網路。"
    exit 1
  }
  Info "已成功 push 到遠端。"
}

Info "腳本完成。"