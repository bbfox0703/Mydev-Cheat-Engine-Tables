using System;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;

namespace AAToggleGenerator
{
    public partial class LanguageSelectionDialog : Form
    {
        private ComboBox comboBoxLanguages = null!;
        private Button buttonOK = null!;
        private Button buttonCancel = null!;
        private Label labelCurrent = null!;

        public SupportedLanguage SelectedLanguage { get; private set; }

        public LanguageSelectionDialog()
        {
            InitializeComponent();
            LoadLanguages();
            UpdateText();
            ApplyTheme();

            // Subscribe to language changes
            LocalizationManager.LanguageChanged += OnLanguageChanged;
        }

        protected override void Dispose(bool disposing)
        {
            // Unsubscribe from language changes
            LocalizationManager.LanguageChanged -= OnLanguageChanged;
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            this.comboBoxLanguages = new ComboBox();
            this.buttonOK = new Button();
            this.buttonCancel = new Button();
            this.labelCurrent = new Label();

            this.SuspendLayout();

            // labelCurrent
            this.labelCurrent.AutoSize = true;
            this.labelCurrent.Location = new Point(12, 15);
            this.labelCurrent.Size = new Size(200, 15);
            this.labelCurrent.TabIndex = 0;

            // comboBoxLanguages
            this.comboBoxLanguages.DropDownStyle = ComboBoxStyle.DropDownList;
            this.comboBoxLanguages.FormattingEnabled = true;
            this.comboBoxLanguages.Location = new Point(12, 40);
            this.comboBoxLanguages.Size = new Size(200, 23);
            this.comboBoxLanguages.TabIndex = 1;

            // buttonOK
            this.buttonOK.DialogResult = DialogResult.OK;
            this.buttonOK.Location = new Point(56, 75);
            this.buttonOK.Size = new Size(75, 23);
            this.buttonOK.TabIndex = 2;
            this.buttonOK.UseVisualStyleBackColor = true;
            this.buttonOK.Click += ButtonOK_Click;

            // buttonCancel
            this.buttonCancel.DialogResult = DialogResult.Cancel;
            this.buttonCancel.Location = new Point(137, 75);
            this.buttonCancel.Size = new Size(75, 23);
            this.buttonCancel.TabIndex = 3;
            this.buttonCancel.UseVisualStyleBackColor = true;

            // LanguageSelectionDialog
            this.AutoScaleDimensions = new SizeF(96F, 96F);
            this.AutoScaleMode = AutoScaleMode.Dpi;
            this.ClientSize = new Size(224, 111);
            this.Controls.Add(this.buttonCancel);
            this.Controls.Add(this.buttonOK);
            this.Controls.Add(this.comboBoxLanguages);
            this.Controls.Add(this.labelCurrent);
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.StartPosition = FormStartPosition.CenterParent;

            this.ResumeLayout(false);
            this.PerformLayout();
        }

        private void LoadLanguages()
        {
            comboBoxLanguages.Items.Clear();

            foreach (var language in LocalizationManager.SupportedLanguages)
            {
                var displayName = LocalizationManager.GetLanguageDisplayName(language);
                comboBoxLanguages.Items.Add(new LanguageItem(language, displayName));
            }

            // Select current language
            var currentLanguage = LocalizationManager.CurrentLanguage;
            for (int i = 0; i < comboBoxLanguages.Items.Count; i++)
            {
                if (comboBoxLanguages.Items[i] is LanguageItem item && item.Language == currentLanguage)
                {
                    comboBoxLanguages.SelectedIndex = i;
                    break;
                }
            }

            SelectedLanguage = currentLanguage;
        }

        private void UpdateText()
        {
            this.Text = LocalizationManager.GetString("Language.SelectLanguage");
            this.labelCurrent.Text = LocalizationManager.GetString("Language.Current",
                LocalizationManager.GetLanguageDisplayName(LocalizationManager.CurrentLanguage));
            this.buttonOK.Text = LocalizationManager.GetString("Language.OK");
            this.buttonCancel.Text = LocalizationManager.GetString("Language.Cancel");
        }

        private void ApplyTheme()
        {
            if (WindowsThemeHelper.IsThemeAwareSupported())
            {
                // Apply theme to form itself using extension method
                ((Form)this).ApplyTheme();
                labelCurrent.ApplyTheme();
                comboBoxLanguages.ApplyTheme();
                buttonOK.ApplyTheme();
                buttonCancel.ApplyTheme();
            }
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);

            // Ensure title bar theme is applied after handle is created
            WindowsThemeHelper.ApplyTitleBarTheme(this.Handle);
        }

        private void OnLanguageChanged(object? sender, SupportedLanguage newLanguage)
        {
            UpdateText();
        }

        private void ButtonOK_Click(object? sender, EventArgs e)
        {
            if (comboBoxLanguages.SelectedItem is LanguageItem selectedItem)
            {
                SelectedLanguage = selectedItem.Language;
            }
        }

        private class LanguageItem
        {
            public SupportedLanguage Language { get; }
            public string DisplayName { get; }

            public LanguageItem(SupportedLanguage language, string displayName)
            {
                Language = language;
                DisplayName = displayName;
            }

            public override string ToString() => DisplayName;
        }
    }
}