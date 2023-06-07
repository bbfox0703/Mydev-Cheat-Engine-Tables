# https://github.com/bbfox0703/Mydev-Cheat-Engine-Tables
#
# JA
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_jp\str_monster_name.xml" .\str_monster_name_ja.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_jp\str_fm_landmark.xml" .\str_fm_landmark_ja.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_jp\str_item_name.xml" .\str_item_name_ja.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_jp\str_item_potential.xml" .\str_item_potential_ja.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_jp\str_item_effect.xml" .\str_item_effect_ja.csv
#
# TC
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_tc\str_monster_name.xml" .\str_monster_name_tc.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_tc\str_fm_landmark.xml" .\str_fm_landmark_tc.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_tc\str_item_name.xml" .\str_item_name_tc.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_tc\str_item_potential.xml" .\str_item_potential_tc.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_tc\str_item_effect.xml" .\str_item_effect_tc.csv
#
# EN
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_en\str_monster_name.xml" .\str_monster_name_en.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_en\str_fm_landmark.xml" .\str_fm_landmark_en.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_en\str_item_name.xml" .\str_item_name_en.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_en\str_item_potential.xml" .\str_item_potential_en.csv
# ./Extract_ID.ps1 "E:\SteamLibrary\steamapps\common\Atelier Ryza 3\Data\saves\text_en\str_item_effect.xml" .\str_item_effect_en.csv


[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [string]$InputFile,

    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

if (-not (Test-Path -Path $InputFile -PathType Leaf)) {
	# Throw "Input file not exist!"
    Throw "輸入檔案不存在！"
	# throw [System.Text.Encoding]::Unicode.GetString([System.Text.Encoding]::UTF8.GetBytes("輸入檔案不存在！"))
}

if (Test-Path -Path $OutputFile -PathType Leaf) {
	# Throw "Output file exist!"
    Throw "輸出檔案已存在！"
	# throw [System.Text.Encoding]::Unicode.GetString([System.Text.Encoding]::UTF8.GetBytes("輸出檔案已存在！"))
}

if (-not (Test-Path -Path (Split-Path -Path $OutputFile) -PathType Container)) {
	# Throw "Output directory not exist!"
    Throw "輸出的目錄不存在、或者不是目錄！"
	# throw [System.Text.Encoding]::Unicode.GetString([System.Text.Encoding]::UTF8.GetBytes("輸出的目錄不存在、或者不是目錄！"))
}

# 讀取 XML 檔案，並指定編碼為 UTF8
$xml = [xml](Get-Content -Path  $inputFile -Encoding UTF8)

# 初始化結果陣列
$results = @()

# 提取每一筆資料
foreach ($item in $xml.Root.str) {
    # 從 String_ID 中提取數字部分
    $idNumber = $item.String_ID -replace '\D+(\d+)$', '$1'
    # 取得 Text 的內容
    $text = $item.Text

    # 組合成結果物件
    $result = New-Object PSObject -Property @{
        ID = $idNumber
        Text = $text
    }

    # 將結果物件加入結果陣列
    $results += $result
}

# 將結果陣列輸出成 CSV 檔案，並指定編碼為 UTF8
$results | Export-Csv -Path  $outputFile -Encoding UTF8 -NoTypeInformation