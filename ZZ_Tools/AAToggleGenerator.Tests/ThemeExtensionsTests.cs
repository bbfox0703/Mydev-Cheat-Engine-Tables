using System.Drawing;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace AAToggleGenerator.Tests
{
    [TestClass]
    public class ThemeExtensionsTests
    {
        [TestInitialize]
        public void Setup()
        {
            WindowsThemeHelper.RegistryGetValueFunc = Microsoft.Win32.Registry.GetValue;
            WindowsThemeHelper.BuildNumberProvider = null;
            WindowsThemeHelper.DwmSetWindowAttributeOverride = null;
        }

        [TestMethod]
        public void ApplyTheme_SetsColorsForFormAndChildren()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 0; // Dark theme

            var form = new System.Windows.Forms.Form();
            var button = new System.Windows.Forms.Button();
            var treeView = new System.Windows.Forms.TreeView();

            form.Controls.Add(button);
            form.Controls.Add(treeView);

            form.ApplyTheme();

            var bg = WindowsThemeHelper.GetBackgroundColor();
            var fg = WindowsThemeHelper.GetForegroundColor();
            var btnBg = WindowsThemeHelper.GetButtonBackgroundColor();

            Assert.AreEqual(bg, form.BackColor);
            Assert.AreEqual(fg, form.ForeColor);
            Assert.AreEqual(btnBg, button.BackColor);
            Assert.AreEqual(fg, button.ForeColor);
            Assert.AreEqual(bg, treeView.BackColor);
            Assert.AreEqual(fg, treeView.ForeColor);
        }

        [TestMethod]
        public void UpdateNodeTheme_GroupNode_ChangesWithTheme()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            var node = new System.Windows.Forms.TreeNode("Group");

            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 0; // Dark
            node.UpdateNodeTheme(isGroup: true);
            Assert.AreEqual(Color.FromArgb(128, 128, 128), node.ForeColor);

            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 1; // Light
            node.UpdateNodeTheme(isGroup: true);
            Assert.AreEqual(Color.Gray, node.ForeColor);
        }
    }
}

