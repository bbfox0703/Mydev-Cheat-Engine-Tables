using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using Microsoft.Win32;

namespace AAToggleGenerator
{
    /// <summary>
    /// Supported languages for the application
    /// </summary>
    public enum SupportedLanguage
    {
        English,
        TraditionalChinese,
        Japanese
    }

    /// <summary>
    /// Manages application localization and language switching
    /// </summary>
    public static class LocalizationManager
    {
        private static SupportedLanguage _currentLanguage = SupportedLanguage.English;
        private static readonly string SettingsFilePath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "AAToggleGenerator",
            "language.setting");

        // Language code mapping
        private static readonly Dictionary<SupportedLanguage, string> LanguageCodes = new()
        {
            { SupportedLanguage.English, "en" },
            { SupportedLanguage.TraditionalChinese, "zh-TW" },
            { SupportedLanguage.Japanese, "ja" }
        };

        // Language display names
        private static readonly Dictionary<SupportedLanguage, string> LanguageDisplayNames = new()
        {
            { SupportedLanguage.English, "English" },
            { SupportedLanguage.TraditionalChinese, "繁體中文" },
            { SupportedLanguage.Japanese, "日本語" }
        };

        // Localized strings
        private static readonly Dictionary<SupportedLanguage, Dictionary<string, string>> LocalizedStrings = new()
        {
            {
                SupportedLanguage.English, new Dictionary<string, string>
                {
                    // Main Form
                    { "MainForm.Title", "AA Toggle Generator" },
                    { "MainForm.GenerateScript", "Generate AA bulk toggle script" },
                    { "MainForm.RenumberIDs", "Reassign .CT <ID> tag" },
                    { "MainForm.ReplaceProcessName", "Replace exe name to $process" },
                    { "MainForm.ChangeLanguage", "A⇆文" },

                    // Script Generator Dialog
                    { "ScriptGenerator.SelectEntries", "Select Cheat Entries" },
                    { "ScriptGenerator.ExpandDepth", "Expand Depth:" },
                    { "ScriptGenerator.Confirm", "Confirm" },
                    { "ScriptGenerator.GeneratedScript", "Generated Lua Script" },
                    { "ScriptGenerator.FileDialogFilter", "Cheat Engine Table (*.CT)|*.CT" },
                    { "ScriptGenerator.FileDialogTitle", "Select a Cheat Engine Table" },
                    { "ScriptGenerator.Error.FileNotExist", "Selected file does not exist." },
                    { "ScriptGenerator.Error.InvalidXML", "Invalid XML file: {0}" },
                    { "ScriptGenerator.Error.ReadingFile", "Error reading file: {0}" },

                    // Language Selection
                    { "Language.SelectLanguage", "Select Language" },
                    { "Language.Current", "Current: {0}" },
                    { "Language.English", "English" },
                    { "Language.TraditionalChinese", "繁體中文" },
                    { "Language.Japanese", "日本語" },
                    { "Language.OK", "OK" },
                    { "Language.Cancel", "Cancel" },

                    // Messages
                    { "Message.LanguageChanged", "Language changed to {0}. Some changes may require restarting the application." },
                    { "Message.Error", "Error" },
                    { "Message.Success", "Success" },
                    { "Message.Warning", "Warning" },
                    { "Message.Information", "Information" }
                }
            },
            {
                SupportedLanguage.TraditionalChinese, new Dictionary<string, string>
                {
                    // Main Form
                    { "MainForm.Title", "AA 開關產生器" },
                    { "MainForm.GenerateScript", "產生 AA 批量開關腳本" },
                    { "MainForm.RenumberIDs", "重新分配 .CT <ID> 標籤" },
                    { "MainForm.ReplaceProcessName", "將執行檔名稱替換為 $process" },
                    { "MainForm.ChangeLanguage", "A⇆文" },

                    // Script Generator Dialog
                    { "ScriptGenerator.SelectEntries", "選擇作弊項目" },
                    { "ScriptGenerator.ExpandDepth", "展開深度：" },
                    { "ScriptGenerator.Confirm", "確認" },
                    { "ScriptGenerator.GeneratedScript", "產生的 Lua 腳本" },
                    { "ScriptGenerator.FileDialogFilter", "Cheat Engine 表格 (*.CT)|*.CT" },
                    { "ScriptGenerator.FileDialogTitle", "選擇 Cheat Engine 表格" },
                    { "ScriptGenerator.Error.FileNotExist", "選擇的檔案不存在。" },
                    { "ScriptGenerator.Error.InvalidXML", "無效的 XML 檔案：{0}" },
                    { "ScriptGenerator.Error.ReadingFile", "讀取檔案時發生錯誤：{0}" },

                    // Language Selection
                    { "Language.SelectLanguage", "選擇語言" },
                    { "Language.Current", "目前：{0}" },
                    { "Language.English", "English" },
                    { "Language.TraditionalChinese", "繁體中文" },
                    { "Language.Japanese", "日本語" },
                    { "Language.OK", "確定" },
                    { "Language.Cancel", "取消" },

                    // Messages
                    { "Message.LanguageChanged", "語言已變更為 {0}。某些變更可能需要重新啟動應用程式。" },
                    { "Message.Error", "錯誤" },
                    { "Message.Success", "成功" },
                    { "Message.Warning", "警告" },
                    { "Message.Information", "資訊" }
                }
            },
            {
                SupportedLanguage.Japanese, new Dictionary<string, string>
                {
                    // Main Form
                    { "MainForm.Title", "AA トグルジェネレーター" },
                    { "MainForm.GenerateScript", "AA バルクトグルスクリプトを生成" },
                    { "MainForm.RenumberIDs", ".CT <ID> タグを再割り当て" },
                    { "MainForm.ReplaceProcessName", "実行ファイル名を $process に置換" },
                    { "MainForm.ChangeLanguage", "A⇆文" },

                    // Script Generator Dialog
                    { "ScriptGenerator.SelectEntries", "チートエントリを選択" },
                    { "ScriptGenerator.ExpandDepth", "展開深度：" },
                    { "ScriptGenerator.Confirm", "確認" },
                    { "ScriptGenerator.GeneratedScript", "生成された Lua スクリプト" },
                    { "ScriptGenerator.FileDialogFilter", "Cheat Engine テーブル (*.CT)|*.CT" },
                    { "ScriptGenerator.FileDialogTitle", "Cheat Engine テーブルを選択" },
                    { "ScriptGenerator.Error.FileNotExist", "選択されたファイルが存在しません。" },
                    { "ScriptGenerator.Error.InvalidXML", "無効な XML ファイル：{0}" },
                    { "ScriptGenerator.Error.ReadingFile", "ファイル読み取りエラー：{0}" },

                    // Language Selection
                    { "Language.SelectLanguage", "言語を選択" },
                    { "Language.Current", "現在：{0}" },
                    { "Language.English", "English" },
                    { "Language.TraditionalChinese", "繁體中文" },
                    { "Language.Japanese", "日本語" },
                    { "Language.OK", "OK" },
                    { "Language.Cancel", "キャンセル" },

                    // Messages
                    { "Message.LanguageChanged", "言語が {0} に変更されました。一部の変更にはアプリケーションの再起動が必要な場合があります。" },
                    { "Message.Error", "エラー" },
                    { "Message.Success", "成功" },
                    { "Message.Warning", "警告" },
                    { "Message.Information", "情報" }
                }
            }
        };

        /// <summary>
        /// Gets the current language
        /// </summary>
        public static SupportedLanguage CurrentLanguage => _currentLanguage;

        /// <summary>
        /// Gets all supported languages
        /// </summary>
        public static SupportedLanguage[] SupportedLanguages => Enum.GetValues<SupportedLanguage>();

        /// <summary>
        /// Event fired when language changes
        /// </summary>
        public static event EventHandler<SupportedLanguage>? LanguageChanged;

        /// <summary>
        /// Initialize localization system
        /// </summary>
        public static void Initialize()
        {
            // Try to load saved language preference
            var savedLanguage = LoadLanguageSetting();
            if (savedLanguage.HasValue)
            {
                _currentLanguage = savedLanguage.Value;
            }
            else
            {
                // Auto-detect from OS culture
                _currentLanguage = DetectSystemLanguage();
                SaveLanguageSetting(_currentLanguage);
            }
        }

        /// <summary>
        /// Change the current language
        /// </summary>
        public static void ChangeLanguage(SupportedLanguage language)
        {
            if (_currentLanguage != language)
            {
                _currentLanguage = language;
                SaveLanguageSetting(language);
                LanguageChanged?.Invoke(null, language);
            }
        }

        /// <summary>
        /// Get localized string by key
        /// </summary>
        public static string GetString(string key, params object[] args)
        {
            if (LocalizedStrings.TryGetValue(_currentLanguage, out var strings) &&
                strings.TryGetValue(key, out var localizedString))
            {
                return args.Length > 0 ? string.Format(localizedString, args) : localizedString;
            }

            // Fallback to English
            if (_currentLanguage != SupportedLanguage.English &&
                LocalizedStrings.TryGetValue(SupportedLanguage.English, out var englishStrings) &&
                englishStrings.TryGetValue(key, out var englishString))
            {
                return args.Length > 0 ? string.Format(englishString, args) : englishString;
            }

            // Last resort: return the key itself
            return key;
        }

        /// <summary>
        /// Get display name for a language
        /// </summary>
        public static string GetLanguageDisplayName(SupportedLanguage language)
        {
            return LanguageDisplayNames.TryGetValue(language, out var displayName) ? displayName : language.ToString();
        }

        /// <summary>
        /// Detect system language from OS culture
        /// </summary>
        private static SupportedLanguage DetectSystemLanguage()
        {
            var currentCulture = CultureInfo.CurrentUICulture;
            var languageName = currentCulture.Name;

            return languageName switch
            {
                "zh-TW" or "zh-HK" or "zh-MO" => SupportedLanguage.TraditionalChinese,
                "ja" or "ja-JP" => SupportedLanguage.Japanese,
                _ => SupportedLanguage.English
            };
        }

        /// <summary>
        /// Save language setting to file
        /// </summary>
        private static void SaveLanguageSetting(SupportedLanguage language)
        {
            try
            {
                var directory = Path.GetDirectoryName(SettingsFilePath);
                if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                }

                File.WriteAllText(SettingsFilePath, language.ToString());
            }
            catch
            {
                // Ignore save errors - not critical
            }
        }

        /// <summary>
        /// Load language setting from file
        /// </summary>
        private static SupportedLanguage? LoadLanguageSetting()
        {
            try
            {
                if (File.Exists(SettingsFilePath))
                {
                    var content = File.ReadAllText(SettingsFilePath);
                    if (Enum.TryParse<SupportedLanguage>(content, out var language))
                    {
                        return language;
                    }
                }
            }
            catch
            {
                // Ignore load errors - will fall back to auto-detection
            }

            return null;
        }
    }
}