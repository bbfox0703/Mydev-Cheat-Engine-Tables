# Set PS policy:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#
# https://github.com/bbfox0703/Mydev-Cheat-Engine-Tables
#
# .\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_tc\str_monster_name.xml
# .\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_tc\str_item_name.xml
# .\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_tc\str_item_potential.xml
# .\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_tc\str_item_effect.xml
# Ex:
<#

.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_jp\str_item_name.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\jp_str_name.csv'
.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_jp\str_item_effect.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\jp_str_item_effect.csv'
.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_jp\str_item_potential.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\jp_str_item_potential.csv'

.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_en\str_item_name.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\en_str_name.csv'
.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_en\str_item_effect.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\en_str_item_effect.csv'
.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_en\str_item_potential.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\en_str_item_potential.csv'

.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_tc\str_item_name.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\tc_str_name.csv'
.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_tc\str_item_effect.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\tc_str_item_effect.csv'
.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_tc\str_item_potential.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\tc_str_item_potential.csv'

.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_kr\str_item_name.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\kr_str_name.csv'
.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_kr\str_item_effect.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\kr_str_item_effect.csv'
.\Extract_ID2 'D:\SteamLibrary\steamapps\common\Atelier Ryza 2 DX\Data\saves\text_kr\str_item_potential.xml' 'D:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza 2 Lost Legends & the Secret Fairy DX\kr_str_item_potential.csv'

#>

# ID is relative offset from first item ID (curr_ID - first_ID) in 4-digit hexadecimal format
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

if (-not (Test-Path -Path $InputFile -PathType Leaf)) {
    Throw "輸入檔案不存在！"
}

if (Test-Path -Path $OutputFile -PathType Leaf) {
    Throw "輸出檔案已存在！"
}

if (-not (Test-Path -Path (Split-Path -Path $OutputFile) -PathType Container)) {
    Throw "輸出的目錄不存在、或者不是目錄！"
}

# 讀取 XML 檔案，並指定編碼為 UTF8
$xml = [xml](Get-Content -Path $InputFile -Encoding UTF8)

# 初始化結果陣列
$results = @()

# 取得第一筆資料的 String_No 作為基準值
$firstItem = $xml.Root.str | Select-Object -First 1
if ($null -eq $firstItem) {
    Throw "XML 檔案中沒有資料！"
}

# 從 String_No 中提取數字部分作為基準
$baseId = [int]($firstItem.String_No -replace '\D')

# 提取每一筆資料
foreach ($item in $xml.Root.str) {
    # 從 String_No 中提取數字部分
    $currentId = [int]($item.String_No -replace '\D')
    
    # 計算相對於第一筆的偏移量
    $offset = $currentId - $baseId
    
    # 取得 Text 的內容
    $text = $item.Text
    
    # 將偏移量轉換為 4 位 16 進位格式（大寫）
    $hexOffset = "{0:X4}" -f $offset
    
    # 組合成 "XXXX:文字" 格式
    $line = "${hexOffset}:${text}"
    
    # 將結果加入結果陣列
    $results += $line
}

# 將結果陣列輸出成文字檔案，並指定編碼為 UTF8
$results | Out-File -FilePath $OutputFile -Encoding UTF8