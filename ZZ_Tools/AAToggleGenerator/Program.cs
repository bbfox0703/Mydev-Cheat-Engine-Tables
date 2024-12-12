using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Xml.Linq;
using System.Runtime.InteropServices;
using ScintillaNET;
using System.Collections.Generic;

namespace AAToggleGenerator
{
    class Program
    {
        [DllImport("user32.dll")]
        private static extern bool SetForegroundWindow(IntPtr hWnd);

        public class CheatEntry
        {
            public string Id { get; set; }
            public string Description { get; set; }
            public int Depth { get; set; }
            public bool IsAutoAssembler { get; set; }
            public bool HasOptionsWithMoHideChildren { get; set; }
        }

        [STAThread]
        static void Main()
        {
            // Enable DPI awareness
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

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
                    HasOptionsWithMoHideChildren = e.Element("Options")?.Attributes().Any(attr => attr.Name == "moHideChildren" && attr.Value == "1") == true
                })
                .Where(e => (e.IsAutoAssembler || e.HasOptionsWithMoHideChildren) && e.Id != null)
                .ToList();

            // Create TreeView for user selection
            TreeView treeView = new TreeView { Dock = DockStyle.Fill, CheckBoxes = true }; // Ensure all nodes are initially checked

            // Set TreeView font size to 12 or system font
            treeView.Font = new System.Drawing.Font(treeView.Font.FontFamily, 12);

            // Add event to handle checking/unchecking logic
            treeView.AfterCheck += TreeView_AfterCheck;

            // Build hierarchical TreeView nodes
            foreach (var entry in entries)
            {
                TreeNode currentNode = new TreeNode(entry.Description ?? "Unnamed")
                {
                    Tag = entry,
                    Checked = true // Set initial state to checked
                };

                // Add node to its parent based on depth
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

            // Expand first two levels of TreeView by default
            ExpandTreeView(treeView, 2);

            // Create TreeView selection form
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
                Dock = DockStyle.Top,
                Increment = 1
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

            treeForm.Shown += (sender, e) => SetForegroundWindow(treeForm.Handle); // Ensure the form is brought to foreground

            if (treeForm.ShowDialog() != DialogResult.OK)
                return;

            // Filter selected entries for EnableBattleScripts
            var selectedEntries = GetCheckedNodes(treeView.Nodes)
                .Select(node => (CheatEntry)node.Tag)
                .ToList();

            // Ensure correct order based on hierarchy for Enable and Disable
            var enableOrder = GetOrderedEntries(selectedEntries, ascending: true);
            var disableOrder = GetOrderedEntries(entries, ascending: false);

            // Generate Script
            StringBuilder scriptBuilder = new StringBuilder();

            scriptBuilder.AppendLine("[ENABLE]");
            scriptBuilder.AppendLine("{$lua}");
            scriptBuilder.AppendLine("if (syntaxcheck) then return end");
            scriptBuilder.AppendLine("if memrec then print(memrec.Description) end");
            scriptBuilder.AppendLine("getLuaEngine().menuItem5.doClick()");
            scriptBuilder.AppendLine("\nlocal enableBattleScripts = {");

            // Use only selected entries for Enable
            foreach (var entry in enableOrder)
            {
                scriptBuilder.AppendLine($"  {entry.Id}, -- {entry.Description}");
            }
            scriptBuilder.AppendLine("}");
            scriptBuilder.AppendLine("local addressList = getAddressList()");
            scriptBuilder.AppendLine("\nfor _, id in ipairs(enableBattleScripts) do");
            scriptBuilder.AppendLine("  addressList.getMemoryRecordByID(id).Active = true");
            scriptBuilder.AppendLine("end");
            scriptBuilder.AppendLine("\nprint(\"Scripts ON; Total \" .. #enableBattleScripts .. \" items.\")");
            scriptBuilder.AppendLine("getLuaEngine().Close()\n");

            scriptBuilder.AppendLine("[DISABLE]");
            scriptBuilder.AppendLine("{$lua}");
            scriptBuilder.AppendLine("if (syntaxcheck) then return end");
            scriptBuilder.AppendLine("if memrec then print(memrec.Description) end");
            scriptBuilder.AppendLine("getLuaEngine().menuItem5.doClick()");
            scriptBuilder.AppendLine("\nlocal disableBattleScripts = {");

            // Use all entries for Disable
            foreach (var entry in disableOrder)
            {
                scriptBuilder.AppendLine($"  {entry.Id}, -- {entry.Description}");
            }
            scriptBuilder.AppendLine("}");
            scriptBuilder.AppendLine("local addressList = getAddressList()");
            scriptBuilder.AppendLine("\nfor _, id in ipairs(disableBattleScripts) do");
            scriptBuilder.AppendLine("  addressList.getMemoryRecordByID(id).Active = false");
            scriptBuilder.AppendLine("end");
            scriptBuilder.AppendLine("\nprint(\"Scripts OFF.\")");
            scriptBuilder.AppendLine("getLuaEngine().Close()\n");

            // Add comments
            scriptBuilder.AppendLine("-- Comments:");
            foreach (var entry in entries)
            {
                string indent = new string(' ', entry.Depth * 2);
                scriptBuilder.AppendLine($"-- {indent}ID: {entry.Id}, Description: {entry.Description}, Depth: {entry.Depth}");
            }

            // Show script in a Scintilla editor window
            Form form = new Form { Width = 800, Height = 600, Text = "Generated Lua Script" };
            Scintilla scintilla = new Scintilla
            {
                Dock = DockStyle.Fill,
                Text = scriptBuilder.ToString(),
                Lexer = Lexer.Lua
            };

            // Set Lua syntax highlighting
            scintilla.Styles[Style.Default].Font = "Consolas";
            scintilla.Styles[Style.Default].Size = 12;
            scintilla.Styles[Style.Default].ForeColor = System.Drawing.Color.Black;
            scintilla.Styles[Style.Lua.Comment].ForeColor = System.Drawing.Color.Gray;
            scintilla.Styles[Style.Lua.CommentLine].ForeColor = System.Drawing.Color.Gray; // Ensure `--` comments
            scintilla.Styles[Style.Lua.String].ForeColor = System.Drawing.Color.Brown;
            scintilla.Styles[Style.Lua.Number].ForeColor = System.Drawing.Color.Purple;
            scintilla.Styles[Style.Lua.Operator].ForeColor = System.Drawing.Color.DarkOrange;
            scintilla.Styles[Style.Lua.Word].ForeColor = System.Drawing.Color.Blue;
            scintilla.Styles[Style.Lua.Word].Bold = true;

            // Remove Lua built-in function highlighting
            scintilla.SetKeywords(0, "if then else end function local return for while do in break repeat until and or not");

            form.Controls.Add(scintilla);

            form.Shown += (sender, e) => SetForegroundWindow(form.Handle); // Ensure the form is brought to foreground

            Application.Run(form);
        }

        private static void TreeView_AfterCheck(object sender, TreeViewEventArgs e)
        {
            // Ensure child nodes follow parent check state
            if (e.Node.Nodes.Count > 0)
            {
                foreach (TreeNode child in e.Node.Nodes)
                {
                    child.Checked = e.Node.Checked;
                }
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
}