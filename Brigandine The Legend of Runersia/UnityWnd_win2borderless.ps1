# bbfox@https://opencheattables.com

# 接受參數，允許傳遞視窗類別名稱
param (
    [string]$classNameToFind = "UnityWndClass"  # 默認值為 UnityWndClass
)
# 
# pwsh ./UnityWnd_win2borderless.ps1 -classNameToFind "AnotherWinClassName"
#

if ((Get-ExecutionPolicy) -ne "RemoteSigned" -and (Get-ExecutionPolicy) -ne "Bypass") {
    # English
    Write-Host "The script requires the execution policy to be RemoteSigned or Bypass."
    Write-Host "Please run the following command to change it:"
    Write-Host "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
    Write-Host ""
    
    # 中文提示
    Write-Host "此腳本需要執行Powershell策略設置為 RemoteSigned 或 Bypass。"
    Write-Host "請運行以下指令進行更改："
    Write-Host "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
    Write-Host ""
    
    # 日本語
    Write-Host "このスクリプトを実行するには、実行ポリシーを RemoteSigned または Bypass に設定する必要があります。"
    Write-Host "次のコマンドを実行して変更してください："
    Write-Host "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
    
    exit
}

# 載入 System.Windows.Forms 來使用螢幕資訊
Add-Type -AssemblyName System.Windows.Forms

# 定義使用的 WinAPI 函數
Add-Type @"
    using System;
    using System.Text;
    using System.Runtime.InteropServices;

    public class WinAPI {
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

        [DllImport("user32.dll")]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr GetWindowLong(IntPtr hWnd, int nIndex);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

        public const int GWL_STYLE = -16;
        public const int GWL_EXSTYLE = -20;
        public const int WS_BORDER = 0x00800000;
        public const int WS_CAPTION = 0x00C00000;
        public const int WS_THICKFRAME = 0x00040000;
        public const int WS_EX_CLIENTEDGE = 0x00000200; 
        public const uint SWP_NOMOVE = 0x0002;
        public const uint SWP_NOSIZE = 0x0001;
        public const uint SWP_FRAMECHANGED = 0x0020;
        public const uint SWP_SHOWWINDOW = 0x0040;
        public const int HWND_TOP = 0;
    }
"@ -PassThru

# 初始化一個緩衝區來存放視窗類別名稱
# $classNameToFind = "ElixirFramework"
$foundWindowHandle = [IntPtr]::Zero

# 定義回調函數，列舉所有視窗並檢查類別名稱
$enumProc = [WinAPI+EnumWindowsProc]{
    param ($hWnd, $lParam)

    # 取得視窗的類別名稱
    $className = [System.Text.StringBuilder]::new(256)
    [WinAPI]::GetClassName($hWnd, $className, $className.Capacity) | Out-Null

    # 檢查視窗是否可見，並且類別名稱是否匹配
    if ($className.ToString() -eq $classNameToFind -and [WinAPI]::IsWindowVisible($hWnd)) {
        $script:foundWindowHandle = $hWnd
        return $false  # 找到後停止列舉
    }

    return $true  # 繼續列舉
}

# 呼叫 EnumWindows 列舉所有視窗
[WinAPI]::EnumWindows($enumProc, [IntPtr]::Zero)
# Read-Host 'Press Enter...'
# 檢查結果
if ($foundWindowHandle -ne [IntPtr]::Zero) {
    Write-Host "Window found, handle: $foundWindowHandle"

    # 取得目前的視窗樣式和擴展樣式
    $currentStyle = [WinAPI]::GetWindowLong($foundWindowHandle, [WinAPI]::GWL_STYLE)
    $currentExStyle = [WinAPI]::GetWindowLong($foundWindowHandle, [WinAPI]::GWL_EXSTYLE)

    # 修改視窗樣式，移除邊框、標題欄和厚邊框
    $newStyle = $currentStyle -band -bnot ([WinAPI]::WS_BORDER) -band -bnot ([WinAPI]::WS_CAPTION) -band -bnot ([WinAPI]::WS_THICKFRAME)
    [WinAPI]::SetWindowLong($foundWindowHandle, [WinAPI]::GWL_STYLE, $newStyle)

    # 修改擴展樣式，移除 WS_EX_CLIENTEDGE
    $newExStyle = $currentExStyle -band -bnot ([WinAPI]::WS_EX_CLIENTEDGE)
    [WinAPI]::SetWindowLong($foundWindowHandle, [WinAPI]::GWL_EXSTYLE, $newExStyle)

    # 將視窗設置為全螢幕
    $screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

    # 設定視窗到全螢幕 (0, 0 為左上角)
    [WinAPI]::SetWindowPos($foundWindowHandle, [IntPtr]::Zero, 0, 0, $screenWidth, $screenHeight, [WinAPI]::SWP_FRAMECHANGED -bor [WinAPI]::SWP_SHOWWINDOW)

    Write-Host "Window has been set to borderless fullscreen mode"
} else {
    Write-Host "Window with specified class not found"
}
# Read-Host 'Press Enter to exit...'