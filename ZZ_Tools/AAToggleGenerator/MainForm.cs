using System;
using System.Drawing;
using System.Windows.Forms;

namespace AAToggleGenerator
{
    public partial class MainForm : Form
    {
        public MainForm()
        {
            InitializeComponent();
            ApplyTheme();
            UpdateLocalization();

            // Subscribe to language changes
            LocalizationManager.LanguageChanged += OnLanguageChanged;

            // Add theme info to title if theme aware is supported
            if (WindowsThemeHelper.IsThemeAwareSupported())
            {
                var currentTheme = WindowsThemeHelper.GetCurrentTheme();
                this.Text += $" - {currentTheme} Theme";
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }

            // Unsubscribe from language changes
            LocalizationManager.LanguageChanged -= OnLanguageChanged;
            base.Dispose(disposing);
        }

        private void OnLanguageChanged(object? sender, SupportedLanguage newLanguage)
        {
            UpdateLocalization();
        }

        private void UpdateLocalization()
        {
            // Update form title
            this.Text = LocalizationManager.GetString("MainForm.Title");

            // Update button texts
            btnAAToggleGen.Text = LocalizationManager.GetString("MainForm.GenerateScript");
            btnIDRenumber.Text = LocalizationManager.GetString("MainForm.RenumberIDs");
            btnReplaceProcName.Text = LocalizationManager.GetString("MainForm.ReplaceProcessName");
            btnLanguage.Text = LocalizationManager.GetString("MainForm.ChangeLanguage");

            // Re-add theme info to title if theme aware is supported
            if (WindowsThemeHelper.IsThemeAwareSupported())
            {
                var currentTheme = WindowsThemeHelper.GetCurrentTheme();
                this.Text += $" - {currentTheme} Theme";
            }
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            
            // Ensure title bar theme is applied after handle is created
            WindowsThemeHelper.ApplyTitleBarTheme(this.Handle);
        }

        private void ApplyTheme()
        {
            if (!WindowsThemeHelper.IsThemeAwareSupported())
            {
                // For Windows versions before 1903, use default system colors
                return;
            }

            var backgroundColor = WindowsThemeHelper.GetBackgroundColor();
            var foregroundColor = WindowsThemeHelper.GetForegroundColor();
            var buttonBackgroundColor = WindowsThemeHelper.GetButtonBackgroundColor();

            // Apply theme to main form
            this.BackColor = backgroundColor;
            this.ForeColor = foregroundColor;

            // Apply theme to all buttons
            ApplyButtonTheme(btnAAToggleGen, buttonBackgroundColor, foregroundColor);
            ApplyButtonTheme(btnIDRenumber, buttonBackgroundColor, foregroundColor);
            ApplyButtonTheme(btnReplaceProcName, buttonBackgroundColor, foregroundColor);
            ApplyButtonTheme(btnLanguage, buttonBackgroundColor, foregroundColor);
        }

        private void ApplyButtonTheme(Button button, Color backgroundColor, Color foregroundColor)
        {
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

        private void btnAAToggleGen_Click(object sender, EventArgs e)
        {
            try
            {
                ScriptGenerator.StartScriptGeneration();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An error occurred: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void btnIDRenumber_Click(object sender, EventArgs e)
        {
            try
            {
                OpenFileDialog openFileDialog = new OpenFileDialog
                {
                    Filter = "Cheat Engine Table (*.CT)|*.CT",
                    Title = "Select a Cheat Engine Table for re-number"
                };

                if (openFileDialog.ShowDialog() == DialogResult.OK)
                {
                    CTFileIDProcessor.RenumberIDs(openFileDialog.FileName);

                    MessageBox.Show("ID reassign completed successfully.", "Success",
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An unexpected error occurred: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void btnReplaceProcName_Click(object sender, EventArgs e)
        {
            try
            {
                OpenFileDialog openFileDialog = new OpenFileDialog
                {
                    Filter = "Cheat Engine Table (*.CT)|*.CT",
                    Title = "Select a Cheat Engine Table"
                };

                if (openFileDialog.ShowDialog() == DialogResult.OK)
                {
                    CTRenameEXE2Process.ReplaceProcessName(openFileDialog.FileName);

                    MessageBox.Show("Process name replacement completed successfully.", "Success",
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An unexpected error occurred: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void btnLanguage_Click(object sender, EventArgs e)
        {
            try
            {
                using (var languageDialog = new LanguageSelectionDialog())
                {
                    if (languageDialog.ShowDialog(this) == DialogResult.OK)
                    {
                        if (languageDialog.SelectedLanguage != LocalizationManager.CurrentLanguage)
                        {
                            LocalizationManager.ChangeLanguage(languageDialog.SelectedLanguage);

                            var languageName = LocalizationManager.GetLanguageDisplayName(languageDialog.SelectedLanguage);
                            var message = LocalizationManager.GetString("Message.LanguageChanged", languageName);
                            var title = LocalizationManager.GetString("Message.Information");

                            MessageBox.Show(message, title, MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                var title = LocalizationManager.GetString("Message.Error");
                MessageBox.Show($"An error occurred: {ex.Message}", title, MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

    }
}
