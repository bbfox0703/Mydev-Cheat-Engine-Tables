using System;
using System.Drawing;
using System.Runtime.InteropServices;
using Microsoft.Win32;

namespace AAToggleGenerator
{
    /// <summary>
    /// Helper class for Windows theme detection and management
    /// Supports Windows 10 version 1903+ (Build 18362+)
    /// </summary>
    public static class WindowsThemeHelper
    {
        private const int MinSupportedBuild = 18362; // Windows 10 1903

        // Delegates for testing/mocking
        internal static Func<string, string, object?, object?> RegistryGetValueFunc = Registry.GetValue;
        internal static Func<int>? BuildNumberProvider;
        internal delegate int DwmSetWindowAttributeDelegate(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
        internal static DwmSetWindowAttributeDelegate? DwmSetWindowAttributeOverride;

        /// <summary>
        /// Windows version information structure
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        private struct OSVERSIONINFOEX
        {
            public int dwOSVersionInfoSize;
            public int dwMajorVersion;
            public int dwMinorVersion;
            public int dwBuildNumber;
            public int dwPlatformId;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
            public string szCSDVersion;
            public short wServicePackMajor;
            public short wServicePackMinor;
            public short wSuiteMask;
            public byte wProductType;
            public byte wReserved;
        }

        [DllImport("ntdll.dll", SetLastError = true)]
        private static extern int RtlGetVersion(ref OSVERSIONINFOEX versionInfo);

        [DllImport("dwmapi.dll")]
        private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

        // Constants for dark title bar
        private const int DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1 = 19;
        private const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;

        /// <summary>
        /// Theme enumeration
        /// </summary>
        public enum WindowsTheme
        {
            Light,
            Dark,
            Unknown
        }

        /// <summary>
        /// Gets the current Windows theme
        /// </summary>
        public static WindowsTheme GetCurrentTheme()
        {
            if (!IsThemeAwareSupported())
            {
                return WindowsTheme.Light; // Fallback to light theme for older versions
            }

            try
            {
                // Check the registry for app theme preference
                var registryValue = RegistryGetValueFunc(
                    @"HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize",
                    "AppsUseLightTheme",
                    1); // Default to light theme

                if (registryValue != null)
                {
                    return (int)registryValue == 1 ? WindowsTheme.Light : WindowsTheme.Dark;
                }
            }
            catch (Exception)
            {
                // If registry access fails, fall back to light theme
            }

            return WindowsTheme.Light;
        }

        /// <summary>
        /// Checks if the current Windows version supports theme awareness
        /// </summary>
        public static bool IsThemeAwareSupported()
        {
            return GetWindowsBuildNumber() >= MinSupportedBuild;
        }

        /// <summary>
        /// Gets the current Windows build number
        /// </summary>
        public static int GetWindowsBuildNumber()
        {
            if (BuildNumberProvider != null)
            {
                return BuildNumberProvider();
            }

            try
            {
                // Try using .NET 8's Environment.OSVersion first (more reliable in .NET 5+)
                var version = Environment.OSVersion;
                if (version.Platform == PlatformID.Win32NT && version.Version.Major >= 10)
                {
                    return version.Version.Build;
                }

                // Fallback to RtlGetVersion API for more accurate version info
                OSVERSIONINFOEX osVersionInfo = new OSVERSIONINFOEX();
                osVersionInfo.dwOSVersionInfoSize = Marshal.SizeOf(typeof(OSVERSIONINFOEX));

                if (RtlGetVersion(ref osVersionInfo) == 0)
                {
                    return osVersionInfo.dwBuildNumber;
                }
            }
            catch (Exception)
            {
                // If all fails, return 0
            }

            return 0;
        }

        /// <summary>
        /// Gets Windows version information string
        /// </summary>
        public static string GetWindowsVersionInfo()
        {
            var buildNumber = GetWindowsBuildNumber();
            var themeSupported = IsThemeAwareSupported();
            var currentTheme = GetCurrentTheme();

            return $"Build: {buildNumber}, Theme Support: {themeSupported}, Current Theme: {currentTheme}";
        }

        /// <summary>
        /// Gets the appropriate background color for the current theme
        /// </summary>
        public static Color GetBackgroundColor()
        {
            return GetCurrentTheme() == WindowsTheme.Dark 
                ? Color.FromArgb(32, 32, 32)   // Dark background
                : SystemColors.Control;        // System default (light)
        }

        /// <summary>
        /// Gets the appropriate foreground color for the current theme
        /// </summary>
        public static Color GetForegroundColor()
        {
            return GetCurrentTheme() == WindowsTheme.Dark 
                ? Color.FromArgb(255, 255, 255)  // White text for dark theme
                : SystemColors.ControlText;      // System default text color
        }

        /// <summary>
        /// Gets the appropriate button background color for the current theme
        /// </summary>
        public static Color GetButtonBackgroundColor()
        {
            return GetCurrentTheme() == WindowsTheme.Dark 
                ? Color.FromArgb(45, 45, 48)    // Dark button background
                : SystemColors.ButtonFace;      // System default button color
        }

        /// <summary>
        /// Gets the appropriate border color for the current theme
        /// </summary>
        public static Color GetBorderColor()
        {
            return GetCurrentTheme() == WindowsTheme.Dark 
                ? Color.FromArgb(63, 63, 70)    // Dark border
                : SystemColors.ControlDark;     // System default border
        }

        /// <summary>
        /// Creates a themed brush for the current theme
        /// </summary>
        public static SolidBrush CreateThemedBrush(bool isBackground = true)
        {
            return new SolidBrush(isBackground ? GetBackgroundColor() : GetForegroundColor());
        }

        /// <summary>
        /// Applies dark title bar to the specified window handle if theme aware and dark theme is active
        /// </summary>
        public static bool TryApplyDarkTitleBar(IntPtr handle)
        {
            if (!IsThemeAwareSupported() || GetCurrentTheme() != WindowsTheme.Dark || handle == IntPtr.Zero)
            {
                return false;
            }

            try
            {
                int darkModeEnabled = 1;
                
                // Try the newer attribute first (Windows 10 2004+)
                var dwm = DwmSetWindowAttributeOverride ?? DwmSetWindowAttribute;
                int result = dwm(handle, DWMWA_USE_IMMERSIVE_DARK_MODE, ref darkModeEnabled, sizeof(int));

                // If that fails, try the older attribute (Windows 10 1903-1909)
                if (result != 0)
                {
                    result = dwm(handle, DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1, ref darkModeEnabled, sizeof(int));
                }
                
                return result == 0;
            }
            catch (Exception)
            {
                // If DWM API call fails, return false but don't crash
                return false;
            }
        }

        /// <summary>
        /// Applies light title bar to the specified window handle
        /// </summary>
        public static bool TryApplyLightTitleBar(IntPtr handle)
        {
            if (!IsThemeAwareSupported() || handle == IntPtr.Zero)
            {
                return false;
            }

            try
            {
                int darkModeEnabled = 0;
                
                // Try the newer attribute first (Windows 10 2004+)
                var dwm = DwmSetWindowAttributeOverride ?? DwmSetWindowAttribute;
                int result = dwm(handle, DWMWA_USE_IMMERSIVE_DARK_MODE, ref darkModeEnabled, sizeof(int));

                // If that fails, try the older attribute (Windows 10 1903-1909)
                if (result != 0)
                {
                    result = dwm(handle, DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1, ref darkModeEnabled, sizeof(int));
                }
                
                return result == 0;
            }
            catch (Exception)
            {
                // If DWM API call fails, return false but don't crash
                return false;
            }
        }

        /// <summary>
        /// Applies appropriate title bar theme based on current Windows theme
        /// </summary>
        public static bool ApplyTitleBarTheme(IntPtr handle)
        {
            if (GetCurrentTheme() == WindowsTheme.Dark)
            {
                return TryApplyDarkTitleBar(handle);
            }
            else
            {
                return TryApplyLightTitleBar(handle);
            }
        }
    }
}