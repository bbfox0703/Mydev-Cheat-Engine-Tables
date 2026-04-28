# 設定基礎路徑變數
$basePath = "D:\Github\CRIMSON-DESERT-SAVE-EDITOR-AND-GAME-MODS"

# 定義檔案路徑
$itemsJsonlPath = Join-Path $basePath "CrimsonGameMods\data\iteminfo_dump\items.jsonl"
$itemNamesPath  = Join-Path $basePath "CrimsonGameMods\data\item_names.json"
$zhTwNamesPath  = Join-Path $basePath "language\names_zh-tw.json"
$jaNamesPath    = Join-Path $basePath "language\names_ja.json"

$outputEnPath   = Join-Path $PSScriptRoot "output.txt"
$outputZhTwPath = Join-Path $PSScriptRoot "output_zh-tw.txt"
$outputJaPath   = Join-Path $PSScriptRoot "output_ja.txt"

# 將 names_xx.json 的 items 物件轉成 Hashtable (key 統一為字串)
function Load-NamePack {
    param([string]$Path)

    $map = @{}
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Warning "Name pack not found: $Path"
        return $map
    }
    try {
        $data = Get-Content -Raw -Path $Path -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
    } catch {
        Write-Warning "Failed to parse $Path : $($_.Exception.Message)"
        return $map
    }
    if ($null -eq $data.items) { return $map }

    foreach ($prop in $data.items.PSObject.Properties) {
        $map[[string]$prop.Name] = $prop.Value
    }
    return $map
}

# 1. 載入英文 (item_names.json: items 是 array)
Write-Host "Reading English item names..." -ForegroundColor Cyan
$enMap = @{}
try {
    $namesData = Get-Content -Raw -Path $itemNamesPath -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
    foreach ($item in $namesData.items) {
        if ($null -ne $item.itemKey) {
            $enMap[[string]$item.itemKey] = $item.name
        }
    }
} catch {
    Write-Error "Failed to read item_names.json: $($_.Exception.Message)"
    exit
}

# 2. 載入 zh-tw / ja name packs
Write-Host "Reading zh-tw / ja name packs..." -ForegroundColor Cyan
$zhTwMap = Load-NamePack -Path $zhTwNamesPath
$jaMap   = Load-NamePack -Path $jaNamesPath

# 3. 處理 items.jsonl，分別累積三組結果
Write-Host "Processing items.jsonl..." -ForegroundColor Cyan
$enResults   = [System.Collections.Generic.List[string]]::new()
$zhTwResults = [System.Collections.Generic.List[string]]::new()
$jaResults   = [System.Collections.Generic.List[string]]::new()

$itemId = 0
$enCount = 0; $zhTwCount = 0; $jaCount = 0

try {
    $lines = Get-Content -Path $itemsJsonlPath -Encoding UTF8 -ErrorAction Stop
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $itemInfo = $line | ConvertFrom-Json
        $key = [string]$itemInfo.key

        # 英文 — 沒翻譯就標 Unknown，全部寫入
        $enName = if ($enMap.ContainsKey($key)) { $enMap[$key] } else { "Unknown" }
        $enResults.Add("${itemId}:${enName}/${key}")
        $enCount++

        # zh-tw — 沒翻譯就跳過
        if ($zhTwMap.ContainsKey($key)) {
            $zhTwResults.Add("${itemId}:$($zhTwMap[$key])/${key}")
            $zhTwCount++
        }

        # ja — 沒翻譯就跳過
        if ($jaMap.ContainsKey($key)) {
            $jaResults.Add("${itemId}:$($jaMap[$key])/${key}")
            $jaCount++
        }

        $itemId++
    }
} catch {
    Write-Error "Error processing items.jsonl: $($_.Exception.Message)"
    exit
}

# 4. 寫檔 (UTF-8)
try {
    $enResults   | Out-File -FilePath $outputEnPath   -Encoding utf8
    $zhTwResults | Out-File -FilePath $outputZhTwPath -Encoding utf8
    $jaResults   | Out-File -FilePath $outputJaPath   -Encoding utf8

    Write-Host ""
    Write-Host "Success!" -ForegroundColor Green
    Write-Host ("  {0,-20} {1,6} lines -> {2}" -f "English (en):",   $enCount,   $outputEnPath)
    Write-Host ("  {0,-20} {1,6} lines -> {2}" -f "Traditional (zh-tw):", $zhTwCount, $outputZhTwPath)
    Write-Host ("  {0,-20} {1,6} lines -> {2}" -f "Japanese (ja):",  $jaCount,   $outputJaPath)
    Write-Host ""
    Write-Host ("Total items in source: {0}" -f $itemId) -ForegroundColor White
    Write-Host ("Coverage  zh-tw: {0:P1}   ja: {1:P1}" -f ($zhTwCount/$itemId), ($jaCount/$itemId)) -ForegroundColor Yellow
} catch {
    Write-Error "Failed to write output: $($_.Exception.Message)"
}
