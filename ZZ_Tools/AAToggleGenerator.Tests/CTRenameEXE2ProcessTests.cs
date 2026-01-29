using System;
using System.IO;
using Xunit;
using AAToggleGenerator;
using System.Windows.Forms;

namespace AAToggleGenerator.Tests
{
    public class TestMessageService : IMessageService
    {
        public string? LastMessage { get; private set; }
        public string? LastCaption { get; private set; }
        public MessageBoxIcon LastIcon { get; private set; }

        public void Show(string message, string caption, MessageBoxButtons buttons, MessageBoxIcon icon)
        {
            LastMessage = message;
            LastCaption = caption;
            LastIcon = icon;
        }
    }

    public class CTRenameEXE2ProcessTests
    {
        private static string CopyTestFile(string fileName)
        {
            string source = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "TestData", fileName);
            string dest = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString() + ".CT");
            File.Copy(source, dest);
            return dest;
        }

        [Fact]
        public void ReplaceProcessName_SingleDirective_ReplacesModuleName()
        {
            var svc = new TestMessageService();
            string path = CopyTestFile("test_single.CT");
            try
            {
                CTRenameEXE2Process.ReplaceProcessName(path, svc);
                string content = File.ReadAllText(path);
                Assert.Contains("aobscanmodule(testLabel,$process,11 22 33 44)", content);
            }
            finally
            {
                File.Delete(path);
            }
        }

        [Fact]
        public void ReplaceProcessName_MultipleDirectives_ReplacesAll()
        {
            var svc = new TestMessageService();
            string path = CopyTestFile("test_multi.CT");
            try
            {
                CTRenameEXE2Process.ReplaceProcessName(path, svc);
                string content = File.ReadAllText(path);
                Assert.DoesNotContain("GameA.exe", content);
                Assert.DoesNotContain("GameB.exe", content);
                Assert.Contains("aobscanmodule(mod1,$process,AA BB CC)", content);
                Assert.Contains("aobscanregion(reg1,$process+1000,$process+2000,DD EE FF)", content);
                Assert.Contains("aobscanmodule(mod2,$process,11 22 33)", content);
            }
            finally
            {
                File.Delete(path);
            }
        }

        [Fact]
        public void ReplaceProcessName_NoPatterns_ShowsNoChangesMessage()
        {
            var svc = new TestMessageService();
            string path = CopyTestFile("sample_empty.CT");
            try
            {
                CTRenameEXE2Process.ReplaceProcessName(path, svc);
                Assert.Equal("No aobscanmodule or aobscanregion patterns found to replace.", svc.LastMessage);
            }
            finally
            {
                File.Delete(path);
            }
        }

        [Fact]
        public void ReplaceProcessName_InvalidPath_ShowsWarning()
        {
            var svc = new TestMessageService();
            string path = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString(), "missing.CT");
            CTRenameEXE2Process.ReplaceProcessName(path, svc);
            Assert.Equal($"File not found: {path}", svc.LastMessage);
        }

        [Fact]
        public void ReplaceProcessName_InvalidExtension_ShowsWarning()
        {
            var svc = new TestMessageService();
            string tempFile = Path.GetTempFileName();
            try
            {
                CTRenameEXE2Process.ReplaceProcessName(tempFile, svc);
                Assert.Equal("Selected file must be a .CT file.", svc.LastMessage);
            }
            finally
            {
                File.Delete(tempFile);
            }
        }
    }
}
