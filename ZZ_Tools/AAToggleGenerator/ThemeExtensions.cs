using System;
using System.Drawing;
using System.Runtime.Versioning;
using System.Windows.Forms;
using ScintillaNET;

namespace AAToggleGenerator
{
    /// <summary>
    /// Extension methods for applying Windows theme to various controls
    /// </summary>
    [SupportedOSPlatform("windows6.1")]
    public static class ThemeExtensions
    {
        /// <summary>
        /// Applies theme to a Form including title bar
        /// </summary>
        public static void ApplyTheme(this Form form)
        {
            if (!WindowsThemeHelper.IsThemeAwareSupported())
                return;

            form.BackColor = WindowsThemeHelper.GetBackgroundColor();
            form.ForeColor = WindowsThemeHelper.GetForegroundColor();

            // Apply dark title bar if supported and handle is available
            if (form.IsHandleCreated)
            {
                WindowsThemeHelper.ApplyTitleBarTheme(form.Handle);
            }
            else
            {
                // If handle is not yet created, apply theme when it becomes available
                form.HandleCreated += (sender, e) =>
                {
                    if (sender is Form f)
                    {
                        WindowsThemeHelper.ApplyTitleBarTheme(f.Handle);
                    }
                };
            }

            // Apply theme to all child controls recursively
            ApplyThemeToControls(form.Controls);
        }

        /// <summary>
        /// Applies theme to a TreeView
        /// </summary>
        public static void ApplyTheme(this TreeView treeView)
        {
            if (!WindowsThemeHelper.IsThemeAwareSupported())
                return;

            treeView.BackColor = WindowsThemeHelper.GetBackgroundColor();
            treeView.ForeColor = WindowsThemeHelper.GetForegroundColor();

            var currentTheme = WindowsThemeHelper.GetCurrentTheme();
            if (currentTheme == WindowsThemeHelper.WindowsTheme.Dark)
            {
                // Dark theme specific styling
                treeView.LineColor = Color.FromArgb(63, 63, 70);
                treeView.BorderStyle = BorderStyle.FixedSingle;
            }
        }

        /// <summary>
        /// Updates TreeView node colors for current theme
        /// </summary>
        public static void UpdateNodeTheme(this TreeNode node, bool isGroup = false)
        {
            if (!WindowsThemeHelper.IsThemeAwareSupported())
                return;

            var currentTheme = WindowsThemeHelper.GetCurrentTheme();
            
            if (isGroup)
            {
                // Group nodes styling
                node.ForeColor = currentTheme == WindowsThemeHelper.WindowsTheme.Dark 
                    ? Color.FromArgb(128, 128, 128)  // Gray for dark theme
                    : Color.Gray;                     // Gray for light theme
            }
            else
            {
                // Regular nodes use theme foreground color
                node.ForeColor = WindowsThemeHelper.GetForegroundColor();
            }
        }

        /// <summary>
        /// Applies theme to a Button
        /// </summary>
        public static void ApplyTheme(this Button button)
        {
            if (!WindowsThemeHelper.IsThemeAwareSupported())
                return;

            var backgroundColor = WindowsThemeHelper.GetButtonBackgroundColor();
            var foregroundColor = WindowsThemeHelper.GetForegroundColor();

            button.BackColor = backgroundColor;
            button.ForeColor = foregroundColor;
            button.FlatStyle = FlatStyle.Flat;
            button.FlatAppearance.BorderColor = WindowsThemeHelper.GetBorderColor();
            button.FlatAppearance.BorderSize = 1;

            // Add hover effects for dark theme
            if (WindowsThemeHelper.GetCurrentTheme() == WindowsThemeHelper.WindowsTheme.Dark)
            {
                button.FlatAppearance.MouseOverBackColor = Color.FromArgb(62, 62, 64);
                button.FlatAppearance.MouseDownBackColor = Color.FromArgb(75, 75, 75);
            }
        }

        /// <summary>
        /// Applies theme to a Label
        /// </summary>
        public static void ApplyTheme(this Label label)
        {
            if (!WindowsThemeHelper.IsThemeAwareSupported())
                return;

            label.BackColor = Color.Transparent;
            label.ForeColor = WindowsThemeHelper.GetForegroundColor();
        }

        /// <summary>
        /// Applies theme to a NumericUpDown control
        /// </summary>
        public static void ApplyTheme(this NumericUpDown numericUpDown)
        {
            if (!WindowsThemeHelper.IsThemeAwareSupported())
                return;

            numericUpDown.BackColor = WindowsThemeHelper.GetBackgroundColor();
            numericUpDown.ForeColor = WindowsThemeHelper.GetForegroundColor();

            var currentTheme = WindowsThemeHelper.GetCurrentTheme();
            if (currentTheme == WindowsThemeHelper.WindowsTheme.Dark)
            {
                numericUpDown.BorderStyle = BorderStyle.FixedSingle;
            }
        }

        /// <summary>
        /// Applies theme to Scintilla editor
        /// </summary>
        public static void ApplyTheme(this Scintilla scintilla)
        {
            if (!WindowsThemeHelper.IsThemeAwareSupported())
                return;

            var currentTheme = WindowsThemeHelper.GetCurrentTheme();

            if (currentTheme == WindowsThemeHelper.WindowsTheme.Dark)
            {
                ApplyDarkThemeToScintilla(scintilla);
            }
            else
            {
                ApplyLightThemeToScintilla(scintilla);
            }
        }

        /// <summary>
        /// Applies theme to ComboBox
        /// </summary>
        public static void ApplyTheme(this ComboBox comboBox)
        {
            if (!WindowsThemeHelper.IsThemeAwareSupported())
                return;

            var backgroundColor = WindowsThemeHelper.GetBackgroundColor();
            var foregroundColor = WindowsThemeHelper.GetForegroundColor();

            comboBox.BackColor = backgroundColor;
            comboBox.ForeColor = foregroundColor;
            comboBox.FlatStyle = FlatStyle.Flat;
        }

        private static void ApplyDarkThemeToScintilla(Scintilla scintilla)
        {
            // Dark theme colors for Scintilla (Lua syntax highlighting)
            scintilla.Styles[Style.Default].BackColor = Color.FromArgb(30, 30, 30);
            scintilla.Styles[Style.Default].ForeColor = Color.FromArgb(220, 220, 220);

            // Ensure all styles inherit the background color
            for (int i = 0; i < 256; i++)
            {
                scintilla.Styles[i].BackColor = Color.FromArgb(30, 30, 30);
            }
            
            // Lua-specific styles for dark theme
            scintilla.Styles[Style.Lua.Default].BackColor = Color.FromArgb(30, 30, 30);
            scintilla.Styles[Style.Lua.Default].ForeColor = Color.FromArgb(220, 220, 220);
            
            scintilla.Styles[Style.Lua.Comment].ForeColor = Color.FromArgb(106, 153, 85);        // Green comments
            scintilla.Styles[Style.Lua.CommentLine].ForeColor = Color.FromArgb(106, 153, 85);   // Green line comments
            scintilla.Styles[Style.Lua.CommentDoc].ForeColor = Color.FromArgb(106, 153, 85);    // Green doc comments
            
            scintilla.Styles[Style.Lua.Number].ForeColor = Color.FromArgb(181, 206, 168);       // Light green numbers
            scintilla.Styles[Style.Lua.Word].ForeColor = Color.FromArgb(86, 156, 214);          // Blue keywords
            scintilla.Styles[Style.Lua.String].ForeColor = Color.FromArgb(206, 145, 120);       // Orange strings
            scintilla.Styles[Style.Lua.Character].ForeColor = Color.FromArgb(206, 145, 120);    // Orange characters
            scintilla.Styles[Style.Lua.LiteralString].ForeColor = Color.FromArgb(206, 145, 120); // Orange literal strings
            
            scintilla.Styles[Style.Lua.Preprocessor].ForeColor = Color.FromArgb(155, 155, 155); // Gray preprocessor
            scintilla.Styles[Style.Lua.Operator].ForeColor = Color.FromArgb(220, 220, 220);     // White operators
            scintilla.Styles[Style.Lua.Identifier].ForeColor = Color.FromArgb(220, 220, 220);   // White identifiers
            
            // Additional UI colors
            scintilla.CaretForeColor = Color.FromArgb(220, 220, 220);
            scintilla.SetSelectionBackColor(true, Color.FromArgb(51, 153, 255));
        }

        private static void ApplyLightThemeToScintilla(Scintilla scintilla)
        {
            // Light theme (default) colors for Scintilla
            scintilla.Styles[Style.Default].BackColor = Color.White;
            scintilla.Styles[Style.Default].ForeColor = Color.Black;

            // Ensure all styles inherit the background color
            for (int i = 0; i < 256; i++)
            {
                scintilla.Styles[i].BackColor = Color.White;
            }
            
            // Lua-specific styles for light theme
            scintilla.Styles[Style.Lua.Comment].ForeColor = Color.FromArgb(0, 128, 0);        // Green comments
            scintilla.Styles[Style.Lua.CommentLine].ForeColor = Color.FromArgb(0, 128, 0);   // Green line comments
            scintilla.Styles[Style.Lua.CommentDoc].ForeColor = Color.FromArgb(0, 128, 0);    // Green doc comments
            
            scintilla.Styles[Style.Lua.Number].ForeColor = Color.Red;                        // Red numbers
            scintilla.Styles[Style.Lua.Word].ForeColor = Color.Blue;                         // Blue keywords
            scintilla.Styles[Style.Lua.String].ForeColor = Color.FromArgb(163, 21, 21);      // Dark red strings
            scintilla.Styles[Style.Lua.Character].ForeColor = Color.FromArgb(163, 21, 21);   // Dark red characters
            scintilla.Styles[Style.Lua.LiteralString].ForeColor = Color.FromArgb(163, 21, 21); // Dark red literal strings
            
            scintilla.Styles[Style.Lua.Preprocessor].ForeColor = Color.Purple;               // Purple preprocessor
            scintilla.Styles[Style.Lua.Operator].ForeColor = Color.Black;                    // Black operators
            scintilla.Styles[Style.Lua.Identifier].ForeColor = Color.Black;                  // Black identifiers
            
            // Default UI colors
            scintilla.CaretForeColor = Color.Black;
            scintilla.SetSelectionBackColor(true, Color.FromArgb(0, 120, 215));
        }

        private static void ApplyThemeToControls(Control.ControlCollection controls)
        {
            foreach (Control control in controls)
            {
                switch (control)
                {
                    case Button button:
                        button.ApplyTheme();
                        break;
                    case Label label:
                        label.ApplyTheme();
                        break;
                    case TreeView treeView:
                        treeView.ApplyTheme();
                        break;
                    case NumericUpDown numericUpDown:
                        numericUpDown.ApplyTheme();
                        break;
                    case ComboBox comboBox:
                        comboBox.ApplyTheme();
                        break;
                    case Scintilla scintilla:
                        scintilla.ApplyTheme();
                        break;
                    default:
                        control.BackColor = WindowsThemeHelper.GetBackgroundColor();
                        control.ForeColor = WindowsThemeHelper.GetForegroundColor();
                        break;
                }

                // Recursively apply to child controls
                if (control.HasChildren)
                {
                    ApplyThemeToControls(control.Controls);
                }
            }
        }
    }
}