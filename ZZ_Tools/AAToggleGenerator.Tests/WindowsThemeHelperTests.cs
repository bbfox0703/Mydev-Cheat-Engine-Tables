using System;
using System.Runtime.Versioning;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace AAToggleGenerator.Tests
{
    [TestClass]
    [SupportedOSPlatform("windows6.1")]
    public class WindowsThemeHelperTests
    {
        [TestInitialize]
        public void Setup()
        {
            WindowsThemeHelper.RegistryGetValueFunc = Microsoft.Win32.Registry.GetValue;
            WindowsThemeHelper.BuildNumberProvider = null;
            WindowsThemeHelper.DwmSetWindowAttributeOverride = null;
        }

        [TestMethod]
        public void GetCurrentTheme_ReturnsLight_WhenRegistryValueIsLight()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            WindowsThemeHelper.RegistryGetValueFunc = (key, value, defaultVal) => 1;
            Assert.AreEqual(WindowsThemeHelper.WindowsTheme.Light, WindowsThemeHelper.GetCurrentTheme());
        }

        [TestMethod]
        public void GetCurrentTheme_ReturnsDark_WhenRegistryValueIsDark()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            WindowsThemeHelper.RegistryGetValueFunc = (key, value, defaultVal) => 0;
            Assert.AreEqual(WindowsThemeHelper.WindowsTheme.Dark, WindowsThemeHelper.GetCurrentTheme());
        }

        [TestMethod]
        public void IsThemeAwareSupported_ReflectsBuildNumber()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 1000;
            Assert.IsFalse(WindowsThemeHelper.IsThemeAwareSupported());
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            Assert.IsTrue(WindowsThemeHelper.IsThemeAwareSupported());
        }

        [TestMethod]
        public void TryApplyDarkTitleBar_ReturnsFalse_WithZeroHandle()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 0;
            Assert.IsFalse(WindowsThemeHelper.TryApplyDarkTitleBar(IntPtr.Zero));
        }

        [TestMethod]
        public void TryApplyDarkTitleBar_ReturnsTrue_WhenDwmSucceeds()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 0;
            WindowsThemeHelper.DwmSetWindowAttributeOverride = (IntPtr hwnd, int attr, ref int val, int size) => 0;
            Assert.IsTrue(WindowsThemeHelper.TryApplyDarkTitleBar(new IntPtr(1)));
        }

        [TestMethod]
        public void ApplyTitleBarTheme_ReturnsFalse_WhenUnsupported()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 1000;
            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 0;
            Assert.IsFalse(WindowsThemeHelper.ApplyTitleBarTheme(new IntPtr(1)));
        }

        [TestMethod]
        public void ApplyTitleBarTheme_ReturnsTrue_WhenDwmSucceeds()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 0;
            WindowsThemeHelper.DwmSetWindowAttributeOverride = (IntPtr hwnd, int attr, ref int val, int size) => 0;
            Assert.IsTrue(WindowsThemeHelper.ApplyTitleBarTheme(new IntPtr(1)));
        }
    }
}
