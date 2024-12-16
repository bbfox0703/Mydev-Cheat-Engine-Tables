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
            try
            {
                // Read the original file content
                string originalContent = File.ReadAllText(filePath);

                // Create a backup of the original file
                string backupFilePath = $"{filePath}.bak.{DateTime.Now:yyyyMMddHHmmss}";
                File.WriteAllText(backupFilePath, originalContent);
                MessageBox.Show($"Backup created: {backupFilePath}", "Backup Success", MessageBoxButtons.OK, MessageBoxIcon.Information);

                // Perform regex replacement to renumber <ID> nodes
                int idCounter = 0;
                string modifiedContent = Regex.Replace(originalContent, @"<ID>\d+</ID>", match =>
                {
                    return $"<ID>{idCounter++}</ID>";
                });

                // Write the modified content back to the original file
                File.WriteAllText(filePath, modifiedContent);
                MessageBox.Show($"IDs successfully renumbered and saved!\nTotal IDs: {idCounter}", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                // Handle exceptions and display an error message
                MessageBox.Show($"An error occurred: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
