using System.Drawing;
using System.Runtime.Versioning;
using Xunit;

namespace AAToggleGenerator.Tests
{
    [Collection("ThemeTests")]
    [SupportedOSPlatform("windows6.1")]
    public class ThemeExtensionsTests
    {
        public ThemeExtensionsTests()
        {
            WindowsThemeHelper.RegistryGetValueFunc = Microsoft.Win32.Registry.GetValue;
            WindowsThemeHelper.BuildNumberProvider = null;
            WindowsThemeHelper.DwmSetWindowAttributeOverride = null;
        }

        [Fact]
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

            Assert.Equal(bg, form.BackColor);
            Assert.Equal(fg, form.ForeColor);
            Assert.Equal(btnBg, button.BackColor);
            Assert.Equal(fg, button.ForeColor);
            Assert.Equal(bg, treeView.BackColor);
            Assert.Equal(fg, treeView.ForeColor);
        }

        [Fact]
        public void UpdateNodeTheme_GroupNode_ChangesWithTheme()
        {
            WindowsThemeHelper.BuildNumberProvider = () => 19045;
            var node = new System.Windows.Forms.TreeNode("Group");

            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 0; // Dark
            node.UpdateNodeTheme(isGroup: true);
            Assert.Equal(Color.FromArgb(128, 128, 128), node.ForeColor);

            WindowsThemeHelper.RegistryGetValueFunc = (k, v, d) => 1; // Light
            node.UpdateNodeTheme(isGroup: true);
            Assert.Equal(Color.Gray, node.ForeColor);
        }
    }
}
