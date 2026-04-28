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
#   3. items.jsonl 的 string_key ← 內部代號 (例: "Paper_Doni_I_1")
#   4. "Unknown"
#
# 資料來源優先序 (zh-tw / ja)：
#   1. paloc_zho-tw.json / paloc_jpn.json (官方原文)
#   2. 缺翻譯 → 跳過該行
#
# -----------------------------------------------------------------------------
# 前置作業：要在 CrimsonGameMods/ 底下跑這兩支 Python 腳本，產生 paloc_*.json
# -----------------------------------------------------------------------------
#
# (1) list_paloc.py — 列出遊戲 PAZ 內所有 .paloc 檔，找出各語系正確的 group 編號
#                     與檔名 (例如繁中為 localizationstring_zho-tw.paloc / group 0031)。
#     用法:
#         cd D:\Github\CRIMSON-DESERT-SAVE-EDITOR-AND-GAME-MODS\CrimsonGameMods
#         python list_paloc.py
#     遊戲 patch 後若解不到，重跑這支看 group 是否被挪動 (預設掃 0020-0035)。
#
# (2) extract_paloc.py — 從遊戲 .paz 解開語系字串檔，過濾出 item 名稱
#                        ((id & 0xFF) == 0x70)，輸出成 paloc_<lang>.json。
#     用法:
#         cd D:\Github\CRIMSON-DESERT-SAVE-EDITOR-AND-GAME-MODS\CrimsonGameMods
#         python extract_paloc.py
#     會在 CrimsonGameMods/ 產生 paloc_eng.json / paloc_zho-tw.json / paloc_jpn.json。
#     檔案不必複製到本 ps1 資料夾，本腳本會直接從 CrimsonGameMods/ 讀取。
#
# 兩支 Python 腳本內部呼叫 crimson_rs.pyd (repo 已內建編譯好的 Rust 解析器)，
# 不需要安裝 Rust toolchain。每次遊戲版本更新後，依序重跑：
#     python tools\dump_iteminfo.py    (重產 items.jsonl)
#     python extract_paloc.py          (重產 paloc_*.json)
#     pwsh   Generate_item_id_list.ps1 (重產 output*.txt)
# =============================================================================

# 設定基礎路徑變數
$basePath        = "D:\Github\CRIMSON-DESERT-SAVE-EDITOR-AND-GAME-MODS"
$gameModsPath    = Join-Path $basePath "CrimsonGameMods"

# 輸入：items.jsonl
$itemsJsonlPath  = Join-Path $gameModsPath "data\iteminfo_dump\items.jsonl"

# 輸入：官方 paloc 解出的對照表 (主來源)
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
    Write-Host ("  [{0}] loaded {1,6} entries from {2}" -f $Label, $map.Count, (Split-Path $Path -Leaf))
    return $map
}

# ── 1. 載入官方 paloc 對照表 (en / zh-tw / ja) ─────────────────────────────────
Write-Host "Loading paloc maps..." -ForegroundColor Cyan
$enPalocMap   = Load-PalocMap -Path $palocEnPath   -Label "en"
$zhTwPalocMap = Load-PalocMap -Path $palocZhTwPath -Label "zh-tw"
$jaPalocMap   = Load-PalocMap -Path $palocJaPath   -Label "ja"

# ── 2. 載入英文備用 item_names.json (社群維護的 array 結構) ────────────────────
Write-Host "Loading fallback item_names.json (community)..." -ForegroundColor Cyan
$enFallbackMap = @{}
if (Test-Path -LiteralPath $itemNamesPath) {
    try {
        $namesData = Get-Content -Raw -Path $itemNamesPath -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
        foreach ($item in $namesData.items) {
            if ($null -ne $item.itemKey) {
                $enFallbackMap[[string]$item.itemKey] = $item.name
            }
        }
        Write-Host ("  [en-fallback] loaded {0,6} entries from item_names.json" -f $enFallbackMap.Count)
    } catch {
        Write-Warning "Failed to parse item_names.json: $($_.Exception.Message)"
    }
} else {
    Write-Warning "item_names.json not found at $itemNamesPath"
}

# ── 3. 處理 items.jsonl ───────────────────────────────────────────────────────
Write-Host "Processing items.jsonl..." -ForegroundColor Cyan
$enResults   = [System.Collections.Generic.List[string]]::new()
$zhTwResults = [System.Collections.Generic.List[string]]::new()
$jaResults   = [System.Collections.Generic.List[string]]::new()

$itemId = 0
$enFromPaloc = 0; $enFromFallback = 0; $enFromStringKey = 0; $enUnknown = 0
$zhTwCount = 0; $jaCount = 0

try {
    $lines = Get-Content -Path $itemsJsonlPath -Encoding UTF8 -ErrorAction Stop
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $itemInfo = $line | ConvertFrom-Json
        $key      = [string]$itemInfo.key

        # ── EN：paloc → item_names.json → string_key → "Unknown" ────────────
        if ($enPalocMap.ContainsKey($key)) {
            $enName = $enPalocMap[$key]
            $enFromPaloc++
        } elseif ($enFallbackMap.ContainsKey($key)) {
            $enName = $enFallbackMap[$key]
            $enFromFallback++
        } elseif (-not [string]::IsNullOrWhiteSpace($itemInfo.string_key)) {
            $enName = $itemInfo.string_key
            $enFromStringKey++
        } else {
            $enName = "Unknown"
            $enUnknown++
        }
        $enResults.Add("${itemId}:${enName}/${key}")

        # ── zh-tw：paloc only，缺則跳過 ─────────────────────────────────────
        if ($zhTwPalocMap.ContainsKey($key)) {
            $zhTwResults.Add("${itemId}:$($zhTwPalocMap[$key])/${key}")
            $zhTwCount++
        }

        # ── ja：paloc only，缺則跳過 ────────────────────────────────────────
        if ($jaPalocMap.ContainsKey($key)) {
            $jaResults.Add("${itemId}:$($jaPalocMap[$key])/${key}")
            $jaCount++
        }

        $itemId++
    }
} catch {
    Write-Error "Error processing items.jsonl: $($_.Exception.Message)"
    exit
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
    Write-Host ("Total items in source: {0}" -f $itemId) -ForegroundColor White
    Write-Host "EN name source breakdown:" -ForegroundColor White
    Write-Host ("  paloc_eng.json   : {0,6}" -f $enFromPaloc)
    Write-Host ("  item_names.json  : {0,6}  (fallback)" -f $enFromFallback)
    Write-Host ("  string_key       : {0,6}  (last resort)" -f $enFromStringKey)
    Write-Host ("  Unknown          : {0,6}" -f $enUnknown)
    if ($itemId -gt 0) {
        Write-Host ""
        Write-Host ("Coverage  zh-tw: {0:P1}   ja: {1:P1}" -f ($zhTwCount/$itemId), ($jaCount/$itemId)) -ForegroundColor Yellow
    }
} catch {
    Write-Error "Failed to write output: $($_.Exception.Message)"
}
