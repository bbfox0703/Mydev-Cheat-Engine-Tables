using System;
using System.Runtime.Versioning;
using Xunit;

namespace AAToggleGenerator.Tests
{
    [Collection("ThemeTests")]
    [SupportedOSPlatform("windows6.1")]
    public class WindowsThemeHelperTests
    {
        public WindowsThemeHelperTests()
        {
            WindowsThemeHelper.RegistryGetValueFunc = Microsoft.Win32.Registry.GetValue;
            WindowsThemeHelper.BuildNumberProvider = null;
            WindowsThemeHelper.DwmSetWindowAttributeOverride = null;
        }

        [Fact]
        public void GetCurrentTheme_ReturnsLight_WhenRegistryValueIsLight()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            WindowsThemeHelper.RegistryGetValueFunc = (key, value, defaultVal) => 1;
            Assert.Equal(WindowsThemeHelper.WindowsTheme.Light, WindowsThemeHelper.GetCurrentTheme());
        }

        [Fact]
        public void GetCurrentTheme_ReturnsDark_WhenRegistryValueIsDark()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            WindowsThemeHelper.RegistryGetValueFunc = (key, value, defaultVal) => 0;
            Assert.Equal(WindowsThemeHelper.WindowsTheme.Dark, WindowsThemeHelper.GetCurrentTheme());
        }

        [Fact]
        public void IsThemeAwareSupported_ReflectsBuildNumber()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 1000;
            Assert.False(WindowsThemeHelper.IsThemeAwareSupported());
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            Assert.True(WindowsThemeHelper.IsThemeAwareSupported());
        }

        [Fact]
        public void TryApplyDarkTitleBar_ReturnsFalse_WithZeroHandle()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 0;
            Assert.False(WindowsThemeHelper.TryApplyDarkTitleBar(IntPtr.Zero));
        }

        [Fact]
        public void TryApplyDarkTitleBar_ReturnsTrue_WhenDwmSucceeds()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 0;
            WindowsThemeHelper.DwmSetWindowAttributeOverride = (IntPtr hwnd, int attr, ref int val, int size) => 0;
            Assert.True(WindowsThemeHelper.TryApplyDarkTitleBar(new IntPtr(1)));
        }

        [Fact]
        public void ApplyTitleBarTheme_ReturnsFalse_WhenUnsupported()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 1000;
            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 0;
            Assert.False(WindowsThemeHelper.ApplyTitleBarTheme(new IntPtr(1)));
        }

        [Fact]
        public void ApplyTitleBarTheme_ReturnsTrue_WhenDwmSucceeds()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 0;
            WindowsThemeHelper.DwmSetWindowAttributeOverride = (IntPtr hwnd, int attr, ref int val, int size) => 0;
            Assert.True(WindowsThemeHelper.ApplyTitleBarTheme(new IntPtr(1)));
        }
    }
}
