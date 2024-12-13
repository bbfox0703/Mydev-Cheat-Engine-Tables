using System;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using System.Xml.Linq;

namespace AAToggleGenerator
{
    public class CTFileIDProcessor
    {
        /// <summary>
        /// Renumber <ID> nodes in the .CT file starting from zero.
        /// </summary>
        /// <param name="filePath">The path to the .CT file to process.</param>
        public static void RenumberIDs(string filePath)
        {
            try
            {
                // Load the XML file
                var xml = XDocument.Load(filePath);

                // Iterate through all <ID> nodes and renumber them
                int idCounter = 0;
                var idElements = xml.Descendants("ID");
                foreach (var idElement in idElements)
                {
                    idElement.Value = idCounter.ToString();
                    idCounter++;
                }

                // Create backup file name
                string backupFilePath = $"{filePath}.bak.{DateTime.Now:yyyyMMddHHmmss}";

                // Save the backup
                File.Copy(filePath, backupFilePath, overwrite: true);

                // Save the modified file
                xml.Save(filePath);

                // Display success message
                MessageBox.Show($"File renumbered and saved successfully.\nBackup created: {backupFilePath}",
                    "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                // Handle any exceptions and display an error message
                MessageBox.Show($"An error occurred while renumbering IDs: {ex.Message}",
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
