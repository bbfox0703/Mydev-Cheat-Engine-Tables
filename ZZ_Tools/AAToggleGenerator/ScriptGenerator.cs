using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Xml.Linq;
using ScintillaNET;

namespace AAToggleGenerator
{
    public class ScriptGenerator
    {
        public static void StartScriptGeneration()
        {
            // Show file dialog to select .CT file
            OpenFileDialog openFileDialog = new OpenFileDialog
            {
                Filter = "Cheat Engine Table (*.CT)|*.CT",
                Title = "Select a Cheat Engine Table"
            };

            if (openFileDialog.ShowDialog() != DialogResult.OK)
                return;

            string ctFilePath = openFileDialog.FileName;
            var xml = XDocument.Load(ctFilePath);

            // Extract Auto Assembler Script IDs and Descriptions
            var entries = xml.Descendants("CheatEntry")
                .Select(e => new CheatEntry
                {
                    Id = e.Element("ID")?.Value,
                    Description = e.Element("Description")?.Value,
                    Depth = e.Ancestors("CheatEntry").Count(),
                    IsAutoAssembler = e.Element("VariableType")?.Value == "Auto Assembler Script",
                    HasOptionsWithMoHideChildren = e.Element("Options")?.Attributes()
                        .Any(attr => attr.Name == "moHideChildren" && attr.Value == "1") == true
                })
                .Where(e => (e.IsAutoAssembler || e.HasOptionsWithMoHideChildren) && e.Id != null)
                .ToList();

            // Create TreeView for user selection
            TreeView treeView = new TreeView { Dock = DockStyle.Fill, CheckBoxes = true };
            treeView.Font = new System.Drawing.Font(treeView.Font.FontFamily, 12);

            treeView.AfterCheck += TreeView_AfterCheck;
            treeView.NodeMouseDoubleClick += (sender, e) => e.Node.Checked = !e.Node.Checked;

            // Build TreeView nodes
            foreach (var entry in entries)
            {
                TreeNode currentNode = new TreeNode(entry.Description ?? "Unnamed")
                {
                    Tag = entry,
                    Checked = true
                };

                TreeNode parent = null;
                TreeNodeCollection collection = treeView.Nodes;
                for (int i = 0; i < entry.Depth; i++)
                {
                    if (collection.Count > 0)
                        parent = collection[collection.Count - 1];
                    collection = parent?.Nodes ?? treeView.Nodes;
                }
                collection.Add(currentNode);
            }

            ExpandTreeView(treeView, 2);

            // Create selection form
            Form treeForm = new Form
            {
                Text = "Select Cheat Entries",
                Width = 400,
                Height = 600,
                StartPosition = FormStartPosition.CenterScreen
            };

            Label depthLabel = new Label
            {
                Text = "Expand Depth:",
                Dock = DockStyle.Top,
                TextAlign = System.Drawing.ContentAlignment.MiddleLeft
            };

            NumericUpDown depthSelector = new NumericUpDown
            {
                Minimum = 0,
                Maximum = 10,
                Value = 2,
                Dock = DockStyle.Top
            };

            depthSelector.ValueChanged += (sender, e) =>
            {
                int depth = (int)depthSelector.Value;
                ExpandTreeView(treeView, depth);
            };

            Button confirmButton = new Button
            {
                Text = "Confirm",
                Dock = DockStyle.Bottom,
                DialogResult = DialogResult.OK
            };

            treeForm.Controls.Add(treeView);
            treeForm.Controls.Add(depthSelector);
            treeForm.Controls.Add(depthLabel);
            treeForm.Controls.Add(confirmButton);


            if (treeForm.ShowDialog() != DialogResult.OK)
                return;

            // Filter selected entries
            var selectedEntries = GetCheckedNodes(treeView.Nodes)
                .Select(node => (CheatEntry)node.Tag)
                .ToList();

            // Ensure correct order
            var enableOrder = GetOrderedEntries(selectedEntries, true);
            var disableOrder = GetOrderedEntries(entries, false);

            // Generate script
            StringBuilder scriptBuilder = new StringBuilder();

            scriptBuilder.AppendLine("[ENABLE]");
            scriptBuilder.AppendLine("{$lua}");
            scriptBuilder.AppendLine("if (syntaxcheck) then return end");
            scriptBuilder.AppendLine("synchronize(function() getLuaEngine().menuItem5.doClick() end)");
            scriptBuilder.AppendLine("synchronize(function() getLuaEngine().Close() end)");
            scriptBuilder.AppendLine("\nlocal enableBattleScripts = {");

            foreach (var entry in enableOrder)
            {
                scriptBuilder.AppendLine($"  {entry.Id}, -- {entry.Description}");
            }
            scriptBuilder.AppendLine("}");
            scriptBuilder.AppendLine("local addressList = getAddressList()");
            scriptBuilder.AppendLine("for _, id in ipairs(enableBattleScripts) do");
            scriptBuilder.AppendLine("  synchronize(function() addressList.getMemoryRecordByID(id).Active = true end)");
            scriptBuilder.AppendLine("end");
            scriptBuilder.AppendLine("synchronize(function() getLuaEngine().Close() end)");

            scriptBuilder.AppendLine("[DISABLE]");
            scriptBuilder.AppendLine("{$lua}");
            scriptBuilder.AppendLine("if (syntaxcheck) then return end");
            scriptBuilder.AppendLine("synchronize(function() getLuaEngine().menuItem5.doClick() end)");
            scriptBuilder.AppendLine("synchronize(function() getLuaEngine().Close() end)");
            scriptBuilder.AppendLine("\nlocal disableBattleScripts = {");

            foreach (var entry in disableOrder)
            {
                scriptBuilder.AppendLine($"  {entry.Id}, -- {entry.Description}");
            }
            scriptBuilder.AppendLine("}");
            scriptBuilder.AppendLine("local addressList = getAddressList()");
            scriptBuilder.AppendLine("for _, id in ipairs(disableBattleScripts) do");
            scriptBuilder.AppendLine("  synchronize(function() addressList.getMemoryRecordByID(id).Active = false end)");
            scriptBuilder.AppendLine("end");
            scriptBuilder.AppendLine("synchronize(function() getLuaEngine().Close() end)");

            // Add comments
            scriptBuilder.AppendLine("-- Comments:");
            foreach (var entry in entries)
            {
                string indent = new string(' ', entry.Depth * 2);
                scriptBuilder.AppendLine($"-- {indent}ID: {entry.Id}, Description: {entry.Description}, Depth: {entry.Depth}");
            }

            // Add syntax highlighting using Scintilla
            ShowScriptWithHighlighting(scriptBuilder.ToString());
        }
        private static void ShowScriptWithHighlighting(string script)
        {
            Form scriptForm = new Form { Width = 800, Height = 600, Text = "Generated Lua Script" };
            Scintilla scintilla = new Scintilla
            {
                Dock = DockStyle.Fill,
                Text = script,
                Lexer = Lexer.Lua
            };

            // Set Lua syntax highlighting
            scintilla.Styles[Style.Default].Font = "Consolas";
            scintilla.Styles[Style.Default].Size = 12;
            scintilla.Styles[Style.Default].ForeColor = System.Drawing.Color.Black;
            scintilla.Styles[Style.Lua.Comment].ForeColor = System.Drawing.Color.Gray;
            scintilla.Styles[Style.Lua.CommentLine].ForeColor = System.Drawing.Color.Gray;
            scintilla.Styles[Style.Lua.String].ForeColor = System.Drawing.Color.Brown;
            scintilla.Styles[Style.Lua.Number].ForeColor = System.Drawing.Color.Purple;
            scintilla.Styles[Style.Lua.Operator].ForeColor = System.Drawing.Color.DarkOrange;
            scintilla.Styles[Style.Lua.Word].ForeColor = System.Drawing.Color.Blue;
            scintilla.Styles[Style.Lua.Word].Bold = true;

            scintilla.SetKeywords(0, "if then else end function local return for while do in break repeat until and or not");

            scriptForm.Controls.Add(scintilla);
            scriptForm.ShowDialog();
        }
        private static void TreeView_AfterCheck(object sender, TreeViewEventArgs e)
        {
            TreeView treeView = sender as TreeView;
            if (treeView == null) return;

            treeView.BeginUpdate();

            try
            {
                foreach (TreeNode child in e.Node.Nodes)
                {
                    child.Checked = e.Node.Checked;
                }
            }
            finally
            {
                treeView.EndUpdate();
            }
        }

        private static void ExpandTreeView(TreeView treeView, int depth)
        {
            foreach (TreeNode node in treeView.Nodes)
            {
                ExpandNode(node, depth, 0);
            }
        }

        private static void ExpandNode(TreeNode node, int maxDepth, int currentDepth)
        {
            if (currentDepth < maxDepth)
            {
                node.Expand();
                foreach (TreeNode child in node.Nodes)
                {
                    ExpandNode(child, maxDepth, currentDepth + 1);
                }
            }
            else
            {
                node.Collapse();
            }
        }
        private static IEnumerable<TreeNode> GetCheckedNodes(TreeNodeCollection nodes)
        {
            foreach (TreeNode node in nodes)
            {
                if (node.Checked)
                    yield return node;

                foreach (var child in GetCheckedNodes(node.Nodes))
                    yield return child;
            }
        }

        private static List<CheatEntry> GetOrderedEntries(List<CheatEntry> entries, bool ascending)
        {
            return ascending
                ? entries.OrderBy(e => e.Depth).ThenBy(e => e.Id).ToList()
                : entries.OrderByDescending(e => e.Depth).ThenByDescending(e => e.Id).ToList();
        }
    }

    public class CheatEntry
    {
        public string Id { get; set; }
        public string Description { get; set; }
        public int Depth { get; set; }
        public bool IsAutoAssembler { get; set; }
        public bool HasOptionsWithMoHideChildren { get; set; }
    }
}
