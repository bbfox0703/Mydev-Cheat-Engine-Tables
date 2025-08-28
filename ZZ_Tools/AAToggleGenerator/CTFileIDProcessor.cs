using System;
using System.IO;
using System.Text.RegularExpressions;
using System.Windows.Forms;

namespace AAToggleGenerator
{
    public class CTFileIDProcessor
    {
        /// <summary>
        /// Renumber <ID> nodes in the .CT file using regex for efficiency.
        /// </summary>
        /// <param name="filePath">The path to the .CT file to process.</param>
        public static void RenumberIDs(string filePath)
        {
            // Input validation
            if (string.IsNullOrWhiteSpace(filePath))
            {
                MessageBox.Show("File path cannot be null or empty.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (!File.Exists(filePath))
            {
                MessageBox.Show($"File not found: {filePath}", "File Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (!filePath.EndsWith(".CT", StringComparison.OrdinalIgnoreCase))
            {
                MessageBox.Show("Selected file must be a .CT file.", "File Type Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                // Check file access permissions
                using (var fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read))
                {
                    // File is accessible for reading
                }

                // Read the original file content
                string originalContent;
                try
                {
                    originalContent = File.ReadAllText(filePath);
                }
                catch (UnauthorizedAccessException)
                {
                    MessageBox.Show("Access denied. Please check file permissions.", "Access Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                if (string.IsNullOrEmpty(originalContent))
                {
                    MessageBox.Show("The selected file is empty.", "File Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                // Create a backup with better collision handling
                string backupFilePath = GenerateBackupPath(filePath);
                File.WriteAllText(backupFilePath, originalContent);
                MessageBox.Show($"Backup created: {backupFilePath}", "Backup Success", MessageBoxButtons.OK, MessageBoxIcon.Information);

                // Perform regex replacement to renumber <ID> nodes
                int idCounter = 0;
                string modifiedContent = Regex.Replace(originalContent, @"<ID>\d+</ID>", match =>
                {
                    return $"<ID>{idCounter++}</ID>";
                });

                // Verify changes were made
                if (modifiedContent == originalContent)
                {
                    MessageBox.Show("No ID tags found to renumber.", "No Changes", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }

                // Write the modified content back to the original file
                File.WriteAllText(filePath, modifiedContent);
                MessageBox.Show($"IDs successfully renumbered and saved!\nTotal IDs: {idCounter}", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (IOException ex)
            {
                MessageBox.Show($"File I/O error: {ex.Message}", "I/O Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            catch (RegexMatchTimeoutException)
            {
                MessageBox.Show("Operation timed out. The file may be too large.", "Timeout Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An unexpected error occurred: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
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
