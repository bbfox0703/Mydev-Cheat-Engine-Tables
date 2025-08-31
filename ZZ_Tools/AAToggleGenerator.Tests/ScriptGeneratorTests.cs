using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml.Linq;
using AAToggleGenerator;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace AAToggleGenerator.Tests
{
    [TestClass]
    public class ScriptGeneratorTests
    {
        [TestMethod]
        public void SampleSimpleTable_GeneratesExpectedScripts()
        {
            if (!OperatingSystem.IsWindows())
            {
                Assert.Inconclusive("Windows-only test");
            }

            string ctPath = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,
                "..", "..", "..", "AAToggleGenerator", "TestData", "sample_simple.CT"));
            var xml = XDocument.Load(ctPath);

            ScriptGenerator.TestMode = true;

            var processMethod = typeof(ScriptGenerator).GetMethod("ProcessCheatTable", BindingFlags.NonPublic | BindingFlags.Static);
            processMethod!.Invoke(null, new object[] { xml });

            var entries = ScriptGenerator.LastProcessedEntries!;

            // Verify auto assembler nodes are preselected and group nodes unselectable
            Assert.IsTrue(entries.Any(e => e.IsGroup), "Expected at least one group node");
            foreach (var entry in entries)
            {
                if (entry.IsAutoAssembler)
                {
                    Assert.IsTrue(entry.IsAutoAssembler, $"{entry.Description} should be preselected");
                }
                if (entry.IsGroup)
                {
                    bool isChecked = true;
                    if (entry.IsGroup) isChecked = false; // simulate TreeView restriction
                    Assert.IsFalse(isChecked, $"Group node {entry.Description} should remain unchecked");
                }
            }

            var getOrdered = typeof(ScriptGenerator).GetMethod("GetOrderedEntries", BindingFlags.NonPublic | BindingFlags.Static);
            var enableOrder = (List<CheatEntry>)getOrdered!.Invoke(null, new object[] { entries.Where(e => e.IsAutoAssembler).ToList(), true })!;
            var disableOrder = (List<CheatEntry>)getOrdered.Invoke(null, new object[] { entries, false })!;

            var enableLines = enableOrder.Select(e => $"{e.Id} -- {e.Description}").ToList();
            var disableLines = disableOrder.Select(e => $"{e.Id} -- {e.Description}").ToList();

            CollectionAssert.AreEqual(new[]
            {
                "0 -- Simple AA Script",
                "2 -- Child AA Script",
                "4 -- Nested AA Script"
            }, enableLines);

            CollectionAssert.AreEqual(new[]
            {
                "4 -- Nested AA Script",
                "2 -- Child AA Script",
                "3 -- Group Header",
                "1 -- Regular Entry",
                "0 -- Simple AA Script"
            }, disableLines);
        }

        [TestMethod]
        public void SampleComplexTable_FiltersExcludedDescriptions()
        {
            if (!OperatingSystem.IsWindows())
            {
                Assert.Inconclusive("Windows-only test");
            }

            string ctPath = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,
                "..", "..", "..", "AAToggleGenerator", "TestData", "sample_complex.CT"));
            var xml = XDocument.Load(ctPath);

            ScriptGenerator.TestMode = true;

            var processMethod = typeof(ScriptGenerator).GetMethod("ProcessCheatTable", BindingFlags.NonPublic | BindingFlags.Static);
            processMethod!.Invoke(null, new object[] { xml });

            var entries = ScriptGenerator.LastProcessedEntries!;

            var isExcluded = typeof(ScriptGenerator).GetMethod("IsDescriptionExcluded", BindingFlags.NonPublic | BindingFlags.Static);
            string[] keywords = { "一鍵開啟", "Toggle Scripts" };
            foreach (var keyword in keywords)
            {
                Assert.IsTrue((bool)isExcluded!.Invoke(null, new object[] { keyword })!, $"{keyword} should be excluded");
                Assert.IsFalse(entries.Any(e => e.Description.Contains(keyword, StringComparison.OrdinalIgnoreCase)),
                    $"Entry '{keyword}' should not appear");
            }

            var getOrdered = typeof(ScriptGenerator).GetMethod("GetOrderedEntries", BindingFlags.NonPublic | BindingFlags.Static);
            var enableOrder = (List<CheatEntry>)getOrdered!.Invoke(null, new object[] { entries.Where(e => e.IsAutoAssembler).ToList(), true })!;
            var disableOrder = (List<CheatEntry>)getOrdered.Invoke(null, new object[] { entries, false })!;

            var scriptLines = enableOrder.Concat(disableOrder)
                                         .Select(e => $"{e.Id} -- {e.Description}")
                                         .ToList();
            foreach (var keyword in keywords)
            {
                Assert.IsFalse(scriptLines.Any(l => l.Contains(keyword, StringComparison.OrdinalIgnoreCase)),
                    $"Generated script should not contain '{keyword}'");
            }
        }
    }
}
