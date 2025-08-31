using System;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Windows.Forms;
#if EXCLUDE_WINFORMS
// Minimal stubs for cross-platform testing
namespace System.Windows.Forms
{
    public enum MessageBoxButtons { OK }
    public enum MessageBoxIcon { None, Warning, Error, Information }
}
#endif

namespace AAToggleGenerator
{
    public interface IMessageService
    {
        void Show(string message, string caption, MessageBoxButtons buttons, MessageBoxIcon icon);
    }

#if !EXCLUDE_WINFORMS
    public class WinFormsMessageService : IMessageService
    {
        public void Show(string message, string caption, MessageBoxButtons buttons, MessageBoxIcon icon)
            => MessageBox.Show(message, caption, buttons, icon);
    }
#endif

    public class CTRenameEXE2Process
    {
#if !EXCLUDE_WINFORMS
        public static void ReplaceProcessName(string filePath) =>
            ReplaceProcessName(filePath, new WinFormsMessageService());
#endif

        /// <summary>
        /// Replace occurrences of exe_name in aobscanmodule and aobscanregion with $process.
        /// </summary>
        /// <param name="filePath">The path to the .CT file to process.</param>
        /// <param name="messageService">Service used to display feedback messages.</param>
        public static void ReplaceProcessName(string filePath, IMessageService messageService)
        {
            if (messageService == null) throw new ArgumentNullException(nameof(messageService));

            // Input validation
            if (string.IsNullOrWhiteSpace(filePath))
            {
                messageService.Show("File path cannot be null or empty.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (!File.Exists(filePath))
            {
                messageService.Show($"File not found: {filePath}", "File Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (!filePath.EndsWith(".CT", StringComparison.OrdinalIgnoreCase))
            {
                messageService.Show("Selected file must be a .CT file.", "File Type Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                // Check file access permissions
                using (var fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read))
                {
                    // File is accessible for reading
                }

                // Read the content of the .CT file
                string fileContent;
                try
                {
                    fileContent = File.ReadAllText(filePath);
                }
                catch (UnauthorizedAccessException)
                {
                    messageService.Show("Access denied. Please check file permissions.", "Access Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                if (string.IsNullOrEmpty(fileContent))
                {
                    messageService.Show("The selected file is empty.", "File Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                string originalContent = fileContent;

                // Define regex patterns for aobscanmodule and aobscanregion with timeout
                var regexOptions = RegexOptions.IgnoreCase | RegexOptions.Compiled;
                var timeout = TimeSpan.FromSeconds(5);

                try
                {
                    string patternModule = @"aobscanmodule\(([^,]+),([^\),]+),([^)]+)\)";
                    string patternRegion = @"aobscanregion\(([^,]+),([^\+]+)\+([^,]+),([^\+]+)\+([^,]+),([^)]+)\)";

                    // Replace exe_name with $process
                    fileContent = Regex.Replace(fileContent, patternModule, match =>
                    {
                        string label = match.Groups[1].Value;
                        string exeName = match.Groups[2].Value.Trim();
                        string aob = match.Groups[3].Value.Trim();
                        return $"aobscanmodule({label},$process,{aob})";
                    }, regexOptions, timeout);

                    fileContent = Regex.Replace(fileContent, patternRegion, match =>
                    {
                        string label = match.Groups[1].Value;
                        string exeNameStart = match.Groups[2].Value.Trim();
                        string offset1 = match.Groups[3].Value.Trim();
                        string exeNameEnd = match.Groups[4].Value.Trim();
                        string offset2 = match.Groups[5].Value.Trim();
                        string aob = match.Groups[6].Value.Trim();
                        return $"aobscanregion({label},$process+{offset1},$process+{offset2},{aob})";
                    }, regexOptions, timeout);
                }
                catch (RegexMatchTimeoutException)
                {
                    messageService.Show("Operation timed out. The file may be too large or contain complex patterns.", "Timeout Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                // Check if any changes were made
                if (fileContent == originalContent)
                {
                    messageService.Show("No aobscanmodule or aobscanregion patterns found to replace.", "No Changes", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }

                // Create a backup with better collision handling
                string backupFilePath = GenerateBackupPath(filePath);
                File.Copy(filePath, backupFilePath, overwrite: false);

                // Write the modified content back to the .CT file
                File.WriteAllText(filePath, fileContent);

                // Display success message
                messageService.Show($"Process name replaced successfully.\nBackup created: {backupFilePath}",
                    "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (IOException ex)
            {
                messageService.Show($"File I/O error: {ex.Message}", "I/O Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            catch (Exception ex)
            {
                messageService.Show($"An unexpected error occurred while replacing process names: {ex.Message}",
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private static string GenerateBackupPath(string originalPath)
        {
            string timestamp = DateTime.Now.ToString("yyyyMMddHHmmss");
            string basePath = $"{originalPath}.bak.{timestamp}";
            
            // Handle potential collisions
            int counter = 0;
            string backupPath = basePath;
            
            while (File.Exists(backupPath))
            {
                backupPath = $"{basePath}.{++counter}";
            }
            
            return backupPath;
        }
    }
}
