# =============================================================================
# Generate_item_id_list.ps1
# -----------------------------------------------------------------------------
# 為 Cheat Engine Table 產生 Item ID -> Name 對照清單，輸出三個檔案：
#   output.txt        英文 (en)        — 全部 ID 都寫入，缺名時 fallback
#   output_zh-tw.txt  繁體中文 (zh-tw) — 缺翻譯就跳過該行
#   output_ja.txt     日文 (ja)        — 缺翻譯就跳過該行
#
# 資料來源優先序 (en)：
#   1. paloc_eng.json          ← 從遊戲 paloc 解出 (官方原文，覆蓋率 100%)
#   2. item_names.json         ← 社群維護的 mapping (備用)
#   3. "Unknown"
#
# 資料來源優先序 (zh-tw / ja)：
#   1. paloc_zho-tw.json / paloc_jpn.json (官方原文)
#   2. 缺翻譯 → 跳過該行
#
# -----------------------------------------------------------------------------
# 取得 Item ID 順序的方式 (NEW — 從遊戲記憶體直接 dump)
# -----------------------------------------------------------------------------
# 為什麼不用 items.jsonl?
#   每次遊戲 patch 後 Rust parser 可能跟不上 (iteminfo.pabgb 結構變動會導致
#   crimson_rs.parse_iteminfo_from_bytes 解不出來)。改用「直接從 process 記憶體
#   讀取遊戲已載入的 itemKey 陣列」更穩、也保證 RuntimeIdx 跟遊戲現況 100% 一致。
#
# 步驟：
#   (1) 啟動遊戲 (CrimsonDesert.exe) 進到主畫面或讀檔即可
#   (2) Cheat Engine attach 到 CrimsonDesert.exe
#   (3) Load CE table 內的 [Dump Item Keys] 條目 (來源 dump_item_keys.CEA)
#       勾選 [ENABLE] -> 自動 AOBScan + 寫出 keys.txt
#       Lua console 會印出 EXPECTED 之後幾筆，讓你確認結尾位置
#   (4) 若 keys.txt 尾段有 garbage (sentinel 0xFFFFFFFF / 0 / 異常大數)，本腳本
#       會自動偵測並停止讀取，不必手動 trim
#   (5) 跑本腳本 -> 三個 output*.txt 完成
#
# 取得 paloc_*.json 的方式 (一次性，patch 後重跑)
#   cd D:\Github\CRIMSON-DESERT-SAVE-EDITOR-AND-GAME-MODS\CrimsonGameMods
#   python list_paloc.py        # 確認語系檔在哪個 group (patch 可能挪動)
#   python extract_paloc.py     # 解出 paloc_eng.json / paloc_zho-tw.json / paloc_jpn.json
# =============================================================================

# ── 路徑設定 ─────────────────────────────────────────────────────────────────
$basePath        = "D:\Github\CRIMSON-DESERT-SAVE-EDITOR-AND-GAME-MODS"
$gameModsPath    = Join-Path $basePath "CrimsonGameMods"

# 輸入：CE Lua 從遊戲記憶體 dump 出來的 itemKey 陣列 (一行一個十進位 key)
$keysPath        = Join-Path $PSScriptRoot "keys.txt"

# 輸入：paloc 解出的官方對照表 (主來源)
$palocEnPath     = Join-Path $gameModsPath "paloc_eng.json"
$palocZhTwPath   = Join-Path $gameModsPath "paloc_zho-tw.json"
$palocJaPath     = Join-Path $gameModsPath "paloc_jpn.json"

# 輸入：英文備用 (社群維護)
$itemNamesPath   = Join-Path $gameModsPath "data\item_names.json"

# 輸出
$outputEnPath    = Join-Path $PSScriptRoot "output.txt"
$outputZhTwPath  = Join-Path $PSScriptRoot "output_zh-tw.txt"
$outputJaPath    = Join-Path $PSScriptRoot "output_ja.txt"


# ── helper：讀 paloc_*.json ({ "key": "name", ... }) ──────────────────────────
function Load-PalocMap {
    param([string]$Path, [string]$Label)

    $map = @{}
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Warning "[$Label] paloc file not found: $Path"
        return $map
    }
    try {
        $data = Get-Content -Raw -Path $Path -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
    } catch {
        Write-Warning "[$Label] failed to parse $Path : $($_.Exception.Message)"
        return $map
    }
    foreach ($prop in $data.PSObject.Properties) {
        $map[[string]$prop.Name] = [string]$prop.Value
    }
    Write-Host ("  [{0,-6}] {1,6} entries  <- {2}" -f $Label, $map.Count, (Split-Path $Path -Leaf))
    return $map
}

# ── garbage 偵測：陣列結尾的 sentinel ────────────────────────────────────────
#   key == 0xFFFFFFFF (4294967295)   ← 實測 sentinel
#   key == 0                          ← 保險：未初始化區域
# 注意：itemKey 可達 9 位數 (例如 391518535)，所以不能用「上限」判斷。
function Test-IsGarbage {
    param([uint64]$Key)
    if ($Key -eq 4294967295) { return $true }
    if ($Key -eq 0)          { return $true }
    return $false
}

# ── 1. 載入官方 paloc 對照表 ──────────────────────────────────────────────────
Write-Host "Loading paloc maps..." -ForegroundColor Cyan
$enPalocMap   = Load-PalocMap -Path $palocEnPath   -Label "en"
$zhTwPalocMap = Load-PalocMap -Path $palocZhTwPath -Label "zh-tw"
$jaPalocMap   = Load-PalocMap -Path $palocJaPath   -Label "ja"

# ── 2. 載入英文備用 item_names.json ──────────────────────────────────────────
Write-Host ""
Write-Host "Loading EN fallback (item_names.json)..." -ForegroundColor Cyan
$enFallbackMap = @{}
if (Test-Path -LiteralPath $itemNamesPath) {
    try {
        $namesData = Get-Content -Raw -Path $itemNamesPath -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
        foreach ($item in $namesData.items) {
            if ($null -ne $item.itemKey) {
                $enFallbackMap[[string]$item.itemKey] = $item.name
            }
        }
        Write-Host ("  [en-fb ] {0,6} entries  <- {1}" -f $enFallbackMap.Count, (Split-Path $itemNamesPath -Leaf))
    } catch {
        Write-Warning "Failed to parse item_names.json: $($_.Exception.Message)"
    }
} else {
    Write-Warning "item_names.json not found at $itemNamesPath"
}

# ── 3. 讀 keys.txt 並組裝輸出 ─────────────────────────────────────────────────
Write-Host ""
Write-Host "Reading keys.txt and generating outputs..." -ForegroundColor Cyan
if (-not (Test-Path -LiteralPath $keysPath)) {
    Write-Error "keys.txt not found at $keysPath"
    Write-Error "請先在 Cheat Engine 載入 dump_item_keys.CEA 並執行 [ENABLE]"
    exit
}

$enResults   = [System.Collections.Generic.List[string]]::new()
$zhTwResults = [System.Collections.Generic.List[string]]::new()
$jaResults   = [System.Collections.Generic.List[string]]::new()

$itemId = 0
$enFromPaloc = 0; $enFromFallback = 0; $enUnknown = 0
$zhTwCount = 0; $jaCount = 0
$stopReason = "EOF"
$rawLines = 0

foreach ($line in Get-Content -Path $keysPath -Encoding UTF8) {
    $rawLines++
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }

    # 解析數字
    $keyU64 = 0UL
    if (-not [uint64]::TryParse($trimmed, [ref]$keyU64)) {
        $stopReason = "non-numeric line at #${rawLines}: '${trimmed}'"
        break
    }

    # 偵測 garbage 結尾
    if (Test-IsGarbage -Key $keyU64) {
        $stopReason = "garbage detected at #${rawLines} (key=${keyU64})"
        break
    }

    $key = [string]$keyU64

    # ── EN：paloc → item_names.json → "Unknown" ────────────────────────────
    if ($enPalocMap.ContainsKey($key)) {
        $enName = $enPalocMap[$key]
        $enFromPaloc++
    } elseif ($enFallbackMap.ContainsKey($key)) {
        $enName = $enFallbackMap[$key]
        $enFromFallback++
    } else {
        $enName = "Unknown"
        $enUnknown++
    }
    $enResults.Add("${itemId}:${enName}/${key}")

    # ── zh-tw：paloc only，缺則跳過 ────────────────────────────────────────
    if ($zhTwPalocMap.ContainsKey($key)) {
        $zhTwResults.Add("${itemId}:$($zhTwPalocMap[$key])/${key}")
        $zhTwCount++
    }

    # ── ja：paloc only，缺則跳過 ───────────────────────────────────────────
    if ($jaPalocMap.ContainsKey($key)) {
        $jaResults.Add("${itemId}:$($jaPalocMap[$key])/${key}")
        $jaCount++
    }

    $itemId++
}

# ── 4. 寫檔 (UTF-8) ───────────────────────────────────────────────────────────
try {
    $enResults   | Out-File -FilePath $outputEnPath   -Encoding utf8
    $zhTwResults | Out-File -FilePath $outputZhTwPath -Encoding utf8
    $jaResults   | Out-File -FilePath $outputJaPath   -Encoding utf8

    Write-Host ""
    Write-Host "Success!" -ForegroundColor Green
    Write-Host ("  {0,-22} {1,6} lines -> {2}" -f "English (en):",        $itemId,    $outputEnPath)
    Write-Host ("  {0,-22} {1,6} lines -> {2}" -f "Traditional (zh-tw):", $zhTwCount, $outputZhTwPath)
    Write-Host ("  {0,-22} {1,6} lines -> {2}" -f "Japanese (ja):",       $jaCount,   $outputJaPath)
    Write-Host ""
    Write-Host ("Total valid items: {0}  (stopped: {1})" -f $itemId, $stopReason) -ForegroundColor White
    Write-Host ""
    Write-Host "EN name source breakdown:" -ForegroundColor White
    Write-Host ("  paloc_eng.json   : {0,6}" -f $enFromPaloc)
    Write-Host ("  item_names.json  : {0,6}  (fallback)" -f $enFromFallback)
    Write-Host ("  Unknown          : {0,6}" -f $enUnknown)
    if ($itemId -gt 0) {
        Write-Host ""
        Write-Host ("Coverage  zh-tw: {0:P1}   ja: {1:P1}" -f ($zhTwCount/$itemId), ($jaCount/$itemId)) -ForegroundColor Yellow
    }
} catch {
    Write-Error "Failed to write output: $($_.Exception.Message)"
}
