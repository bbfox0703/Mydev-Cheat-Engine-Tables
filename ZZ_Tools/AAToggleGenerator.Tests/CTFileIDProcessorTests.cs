using System;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using AAToggleGenerator;
using Xunit;

namespace AAToggleGenerator.Tests
{
    public class CTFileIDProcessorTests
    {
        [Fact]
        public void RenumberIDs_RewritesSequentiallyAndCreatesBackup()
        {
            Skip.If(!OperatingSystem.IsWindows(), "Windows-only test");

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
                Assert.Equal(new[] { "0", "1", "2" }, ids);

                string[] backups = Directory.GetFiles(tempDir, "test.CT.bak.*");
                Assert.Equal(1, backups.Length);
                Assert.True(File.Exists(backups[0]));
                Assert.True(CTFileIDProcessor.LastMessages.Any(m => m.StartsWith("Backup created:")));
            }
            finally
            {
                Directory.Delete(tempDir, true);
            }
        }

        [Fact]
        public void RenumberIDs_InvalidPath_ShowsAlert()
        {
            Skip.If(!OperatingSystem.IsWindows(), "Windows-only test");

            CTFileIDProcessor.TestMode = true;
            CTFileIDProcessor.LastMessages.Clear();
            string path = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName() + ".CT");
            CTFileIDProcessor.RenumberIDs(path);
            Assert.Equal($"File not found: {path}", CTFileIDProcessor.LastMessages.Single());
        }

        [Fact]
        public void RenumberIDs_InvalidExtension_ShowsAlert()
        {
            Skip.If(!OperatingSystem.IsWindows(), "Windows-only test");

            string tempFile = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName() + ".txt");
            File.WriteAllText(tempFile, "dummy");
            try
            {
                CTFileIDProcessor.TestMode = true;
                CTFileIDProcessor.LastMessages.Clear();
                CTFileIDProcessor.RenumberIDs(tempFile);
                Assert.Equal("Selected file must be a .CT file.", CTFileIDProcessor.LastMessages.Single());
            }
            finally
            {
                File.Delete(tempFile);
            }
        }
    }
}
