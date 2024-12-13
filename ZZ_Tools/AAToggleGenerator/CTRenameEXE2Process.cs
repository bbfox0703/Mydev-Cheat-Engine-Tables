using System;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Windows.Forms;

namespace AAToggleGenerator
{
    public class CTRenameEXE2Process
    {
        /// <summary>
        /// Replace occurrences of exe_name in aobscanmodule and aobscanregion with $process.
        /// </summary>
        /// <param name="filePath">The path to the .CT file to process.</param>
        public static void ReplaceProcessName(string filePath)
        {
            try
            {
                // Read the content of the .CT file
                string fileContent = File.ReadAllText(filePath);

                // Define regex patterns for aobscanmodule and aobscanregion
                string patternModule = @"aobscanmodule\(([^,]+),([^\),]+),([^)]+)\)";
                string patternRegion = @"aobscanregion\(([^,]+),([^\+]+)\+([^,]+),([^\+]+)\+([^,]+),([^)]+)\)";

                // Replace exe_name with $process
                fileContent = Regex.Replace(fileContent, patternModule, match =>
                {
                    string label = match.Groups[1].Value;
                    string exeName = match.Groups[2].Value.Trim();
                    string aob = match.Groups[3].Value.Trim();
                    return $"aobscanmodule({label},$process,{aob})";
                });

                fileContent = Regex.Replace(fileContent, patternRegion, match =>
                {
                    string label = match.Groups[1].Value;
                    string exeNameStart = match.Groups[2].Value.Trim();
                    string offset1 = match.Groups[3].Value.Trim();
                    string exeNameEnd = match.Groups[4].Value.Trim();
                    string offset2 = match.Groups[5].Value.Trim();
                    string aob = match.Groups[6].Value.Trim();
                    return $"aobscanregion({label},$process+{offset1},$process+{offset2},{aob})";
                });

                // Create a backup of the original file
                string backupFilePath = $"{filePath}.bak.{DateTime.Now:yyyyMMddHHmmss}";
                File.Copy(filePath, backupFilePath, overwrite: true);

                // Write the modified content back to the .CT file
                File.WriteAllText(filePath, fileContent);

                // Display success message
                MessageBox.Show($"Process name replaced successfully.\nBackup created: {backupFilePath}",
                    "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                // Handle any exceptions and display an error message
                MessageBox.Show($"An error occurred while replacing process names: {ex.Message}",
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
