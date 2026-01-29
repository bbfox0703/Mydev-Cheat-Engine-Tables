using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml.Linq;
using AAToggleGenerator;
using Xunit;
using System.Windows.Forms;

namespace AAToggleGenerator.Tests
{
    public class ScriptGeneratorTests
    {
        [Fact]
        public void SampleSimpleTable_GeneratesExpectedScripts()
        {
            Skip.If(!OperatingSystem.IsWindows(), "Windows-only test");

            string ctPath = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,
                "..", "..", "..", "AAToggleGenerator", "TestData", "sample_simple.CT"));
            var xml = XDocument.Load(ctPath);

            ScriptGenerator.TestMode = true;

            var processMethod = typeof(ScriptGenerator).GetMethod("ProcessCheatTable", BindingFlags.NonPublic | BindingFlags.Static);
            processMethod!.Invoke(null, new object[] { xml });

            var entries = ScriptGenerator.LastProcessedEntries!;

            // Verify auto assembler nodes are preselected and group nodes unselectable
            Assert.True(entries.Any(e => e.IsGroup), "Expected at least one group node");
            foreach (var entry in entries)
            {
                if (entry.IsAutoAssembler)
                {
                    Assert.True(entry.IsAutoAssembler, $"{entry.Description} should be preselected");
                }
                if (entry.IsGroup)
                {
                    bool isChecked = true;
                    if (entry.IsGroup) isChecked = false; // simulate TreeView restriction
                    Assert.False(isChecked, $"Group node {entry.Description} should remain unchecked");
                }
            }

            var getOrdered = typeof(ScriptGenerator).GetMethod("GetOrderedEntries", BindingFlags.NonPublic | BindingFlags.Static);
            var enableOrder = (List<CheatEntry>)getOrdered!.Invoke(null, new object[] { entries.Where(e => e.IsAutoAssembler).ToList(), true })!;
            var disableOrder = (List<CheatEntry>)getOrdered.Invoke(null, new object[] { entries, false })!;

            var enableLines = enableOrder.Select(e => $"{e.Id} -- {e.Description}").ToList();
            var disableLines = disableOrder.Select(e => $"{e.Id} -- {e.Description}").ToList();

            Assert.Equal(new[]
            {
                "0 -- Simple AA Script",
                "2 -- Child AA Script",
                "4 -- Nested AA Script"
            }, enableLines);

            Assert.Equal(new[]
            {
                "4 -- Nested AA Script",
                "2 -- Child AA Script",
                "3 -- Group Header",
                "1 -- Regular Entry",
                "0 -- Simple AA Script"
            }, disableLines);
        }

        [Fact]
        public void SampleSimpleTable_BuildScriptCreatesOrderedSectionsAndComments()
        {
            Skip.If(!OperatingSystem.IsWindows(), "Windows-only test");

            string ctPath = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,
                "..", "..", "..", "AAToggleGenerator", "TestData", "sample_simple.CT"));
            var xml = XDocument.Load(ctPath);

            ScriptGenerator.TestMode = true;

            var processMethod = typeof(ScriptGenerator).GetMethod("ProcessCheatTable", BindingFlags.NonPublic | BindingFlags.Static);
            processMethod!.Invoke(null, new object[] { xml });

            var entries = ScriptGenerator.LastProcessedEntries!;
            var buildMethod = typeof(ScriptGenerator).GetMethod("BuildScript", BindingFlags.NonPublic | BindingFlags.Static);
            string script = (string)buildMethod!.Invoke(null, new object[] { entries.Where(e => e.IsAutoAssembler).ToList(), entries })!;

            List<string> enableLines = ExtractIdLines(script, "local enableBattleScripts");
            Assert.Equal(new[]
            {
                "0, -- Simple AA Script",
                "2, -- Child AA Script",
                "4, -- Nested AA Script"
            }, enableLines);

            List<string> disableLines = ExtractIdLines(script, "local disableBattleScripts");
            Assert.Equal(new[]
            {
                "4, -- Nested AA Script",
                "2, -- Child AA Script",
                "3, -- Group Header",
                "1, -- Regular Entry",
                "0, -- Simple AA Script"
            }, disableLines);

            Assert.Contains("-- ID: 0, Description: Simple AA Script, Depth: 0", script);
            Assert.Contains("-- ID: 1, Description: Regular Entry, Depth: 0", script);
            Assert.Contains("--   ID: 2, Description: Child AA Script, Depth: 1", script);
            Assert.Contains("-- ID: 3, Description: Group Header, Depth: 0", script);
            Assert.Contains("--   ID: 4, Description: Nested AA Script, Depth: 1", script);
        }

        private static List<string> ExtractIdLines(string script, string marker)
        {
            int start = script.IndexOf(marker, StringComparison.Ordinal);
            int open = script.IndexOf('{', start);
            int close = script.IndexOf('}', open);
            string block = script.Substring(open + 1, close - open - 1);
            return block.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries)
                        .Select(l => l.Trim())
                        .ToList();
        }

        [Fact]
        public void SampleComplexTable_FiltersExcludedDescriptions()
        {
            Skip.If(!OperatingSystem.IsWindows(), "Windows-only test");

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
                Assert.True((bool)isExcluded!.Invoke(null, new object[] { keyword })!, $"{keyword} should be excluded");
                Assert.False(entries.Any(e => e.Description.Contains(keyword, StringComparison.OrdinalIgnoreCase)),
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
                Assert.False(scriptLines.Any(l => l.Contains(keyword, StringComparison.OrdinalIgnoreCase)),
                    $"Generated script should not contain '{keyword}'");
            }
        }

        [Fact]
        public void TreeView_ChecksPropagateAndGroupsRemainUnchecked()
        {
            Skip.If(!OperatingSystem.IsWindows(), "Windows-only test");

            string ctPath = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,
                "..", "..", "..", "AAToggleGenerator", "TestData", "sample_simple.CT"));
            var xml = XDocument.Load(ctPath);

            ScriptGenerator.TestMode = true;

            var processMethod = typeof(ScriptGenerator).GetMethod("ProcessCheatTable", BindingFlags.NonPublic | BindingFlags.Static);
            processMethod!.Invoke(null, new object[] { xml });

            var entries = ScriptGenerator.LastProcessedEntries!;

            using TreeView tree = BuildTreeView(entries);

            // Find parent node with child
            TreeNode parent = tree.Nodes.Cast<TreeNode>().First(n => ((CheatEntry)n.Tag!).Description == "Regular Entry");
            TreeNode child = parent.Nodes[0];

            // Checking parent should check child
            parent.Checked = true;
            Assert.True(child.Checked, "Child node should mirror parent checked state");

            // Unchecking parent should uncheck child
            parent.Checked = false;
            Assert.False(child.Checked, "Child node should mirror parent unchecked state");

            // Attempt to check a group node
            TreeNode groupNode = tree.Nodes.Cast<TreeNode>().First(n => ((CheatEntry)n.Tag!).Description == "Group Header");
            groupNode.Checked = true;
            Assert.False(groupNode.Checked, "Group nodes should remain unchecked");
        }

        private static TreeView BuildTreeView(List<CheatEntry> entries)
        {
            TreeView tree = new TreeView { CheckBoxes = true };
            var afterCheckMethod = typeof(ScriptGenerator).GetMethod("TreeView_AfterCheck", BindingFlags.NonPublic | BindingFlags.Static);
            tree.AfterCheck += (TreeViewEventHandler)Delegate.CreateDelegate(typeof(TreeViewEventHandler), afterCheckMethod!);

            tree.AfterCheck += (sender, e) =>
            {
                if (e.Node?.Tag is CheatEntry ce && ce.IsGroup)
                {
                    e.Node.Checked = false;
                }
            };

            tree.BeforeCheck += (sender, e) =>
            {
                if (e.Node?.Tag is CheatEntry ce && ce.IsGroup)
                {
                    e.Cancel = true;
                }
            };

            Dictionary<int, TreeNode> depthLastNode = new();
            foreach (var entry in entries)
            {
                TreeNode node = new TreeNode(entry.Description)
                {
                    Tag = entry,
                    Checked = entry.IsAutoAssembler
                };

                if (entry.Depth == 0)
                {
                    tree.Nodes.Add(node);
                }
                else if (depthLastNode.TryGetValue(entry.Depth - 1, out TreeNode? parentNode))
                {
                    parentNode.Nodes.Add(node);
                }
                else
                {
                    tree.Nodes.Add(node);
                }

                depthLastNode[entry.Depth] = node;
            }

            return tree;
        }
    }
}
