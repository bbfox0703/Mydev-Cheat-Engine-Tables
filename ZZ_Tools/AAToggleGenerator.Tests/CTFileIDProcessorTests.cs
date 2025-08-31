using System;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using AAToggleGenerator;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace AAToggleGenerator.Tests
{
    [TestClass]
    public class CTFileIDProcessorTests
    {
        [TestMethod]
        public void RenumberIDs_RewritesSequentiallyAndCreatesBackup()
        {
            if (!OperatingSystem.IsWindows())
            {
                Assert.Inconclusive("Windows-only test");
            }

            string tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
            Directory.CreateDirectory(tempDir);
            try
            {
                string filePath = Path.Combine(tempDir, "test.CT");
                string content = @"<CheatTable><CheatEntries>
  <CheatEntry><ID>5</ID></CheatEntry>
  <CheatEntry><ID>8</ID></CheatEntry>
  <CheatEntry><ID>10</ID></CheatEntry>
</CheatEntries></CheatTable>";
                File.WriteAllText(filePath, content);

                CTFileIDProcessor.TestMode = true;
                CTFileIDProcessor.LastMessages.Clear();
                CTFileIDProcessor.RenumberIDs(filePath);

                string updated = File.ReadAllText(filePath);
                var ids = Regex.Matches(updated, @"<ID>(\d+)</ID>")
                               .Select(m => m.Groups[1].Value)
                               .ToArray();
                CollectionAssert.AreEqual(new[] { "0", "1", "2" }, ids);

                string[] backups = Directory.GetFiles(tempDir, "test.CT.bak.*");
                Assert.AreEqual(1, backups.Length);
                Assert.IsTrue(File.Exists(backups[0]));
                Assert.IsTrue(CTFileIDProcessor.LastMessages.Any(m => m.StartsWith("Backup created:")));
            }
            finally
            {
                Directory.Delete(tempDir, true);
            }
        }

        [TestMethod]
        public void RenumberIDs_InvalidPath_ShowsAlert()
        {
            if (!OperatingSystem.IsWindows())
            {
                Assert.Inconclusive("Windows-only test");
            }

            CTFileIDProcessor.TestMode = true;
            CTFileIDProcessor.LastMessages.Clear();
            string path = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName() + ".CT");
            CTFileIDProcessor.RenumberIDs(path);
            Assert.AreEqual($"File not found: {path}", CTFileIDProcessor.LastMessages.Single());
        }

        [TestMethod]
        public void RenumberIDs_InvalidExtension_ShowsAlert()
        {
            if (!OperatingSystem.IsWindows())
            {
                Assert.Inconclusive("Windows-only test");
            }

            string tempFile = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName() + ".txt");
            File.WriteAllText(tempFile, "dummy");
            try
            {
                CTFileIDProcessor.TestMode = true;
                CTFileIDProcessor.LastMessages.Clear();
                CTFileIDProcessor.RenumberIDs(tempFile);
                Assert.AreEqual("Selected file must be a .CT file.", CTFileIDProcessor.LastMessages.Single());
            }
            finally
            {
                File.Delete(tempFile);
            }
        }
    }
}

