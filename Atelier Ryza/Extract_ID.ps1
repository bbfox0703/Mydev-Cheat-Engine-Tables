# Set PS policy:
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#
# https://github.com/bbfox0703/Mydev-Cheat-Engine-Tables
#
# .\steamapps\common\Atelier Ryza\Data\saves\text_tc\str_monster_name.xml
# .\steamapps\common\Atelier Ryza\Data\saves\text_tc\str_item_name.xml
# .\steamapps\common\Atelier Ryza\Data\saves\text_tc\str_item_potential.xml
# .\steamapps\common\Atelier Ryza\Data\saves\text_tc\str_item_effect.xml
# Ex:
# .\Extract_ID 'G:\SteamLibrary\steamapps\common\Atelier Ryza\saves\text_jp\str_item_effect.xml' 'G:\Github\Mydev-Cheat-Engine-Tables\Atelier Ryza\jp_str_item_effect.csv'
#
# ID is absoulate number related to 1st item ID (curr_ID - 1st_ID)

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
    $idNumber = $item.String_No -replace '\D+(\d+)$', '$1'
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