using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Xml;
using System.Xml.Linq;
using ScintillaNET;

namespace AAToggleGenerator
{
    public class ScriptGenerator
    {
        // Constants for better maintainability
        private const int DefaultTreeViewDepth = 2;
        private const int DefaultStringBuilderCapacity = 4096;
        private const int DefaultFormWidth = 400;
        private const int DefaultFormHeight = 600;
        private const int ScriptFormWidth = 800;
        private const int ScriptFormHeight = 600;
        private const int TreeViewFontSize = 12;
        private const int ScintillaFontSize = 12;
        private const string ScintillaFontName = "Consolas";
        private const string LuaKeywords = "if then else end function local return for while do in break repeat until and or not synchronize";
        
        // Performance optimization: Pre-compiled exclusion patterns
        private static readonly HashSet<string> ExcludeKeywords = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "一鍵開啟",
            "scripts on/",
            "Toggle Scripts", 
            "一鍵切換",
            "Toggle some scripts"
        };
        public static void StartScriptGeneration()
        {
            // Show file dialog to select .CT file
            using (OpenFileDialog openFileDialog = new OpenFileDialog
            {
                Filter = "Cheat Engine Table (*.CT)|*.CT",
                Title = "Select a Cheat Engine Table"
            })
            {
                if (openFileDialog.ShowDialog() != DialogResult.OK)
                    return;

                string ctFilePath = openFileDialog.FileName;
                
                // Validate file exists and is accessible
                if (!File.Exists(ctFilePath))
                {
                    MessageBox.Show("Selected file does not exist.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                XDocument xml;
                try
                {
                    xml = XDocument.Load(ctFilePath);
                }
                catch (XmlException ex)
                {
                    MessageBox.Show($"Invalid XML file: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error reading file: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                ProcessCheatTable(xml);
            }
        }

        private static void ProcessCheatTable(XDocument xml)
        {
            // Extract Auto Assembler Script IDs and Descriptions with optimized filtering
            var entries = xml.Descendants("CheatEntry")
                .Select(e => new CheatEntry
                {
                    Id = e.Element("ID")?.Value ?? string.Empty,
                    Description = e.Element("Description")?.Value ?? string.Empty,
                    Depth = e.Ancestors("CheatEntry").Count(),
                    IsAutoAssembler = e.Element("VariableType")?.Value == "Auto Assembler Script",
                    HasOptionsWithMoHideChildren = e.Element("Options")?.Attributes()
                        .Any(attr => attr.Name == "moHideChildren" && attr.Value == "1") == true,
                    HasChildren = e.Element("CheatEntries") != null,  // Check if there are child nodes
                    IsGroup = e.Element("GroupHeader")?.Value == "1" &&
                              !(e.Element("Options")?.Attributes().Any(attr => attr.Name == "moHideChildren" && attr.Value == "1") == true)
                })
                .Where(e =>
                    (e.IsAutoAssembler || e.HasOptionsWithMoHideChildren || e.HasChildren) &&
                    !string.IsNullOrEmpty(e.Id) &&
                    !IsDescriptionExcluded(e.Description)
                )
                .ToList();

            ShowEntrySelectionDialog(entries);
        }
        
        private static bool IsDescriptionExcluded(string description)
        {
            if (string.IsNullOrEmpty(description))
                return false;
                
            // Use HashSet for O(1) lookup performance
            return ExcludeKeywords.Any(keyword => 
                description.IndexOf(keyword, StringComparison.OrdinalIgnoreCase) >= 0);
        }

        private static void ShowEntrySelectionDialog(List<CheatEntry> entries)
        {
            // Create TreeView for user selection
            using (TreeView treeView = new TreeView { Dock = DockStyle.Fill, CheckBoxes = true })
            {
                treeView.Font = new System.Drawing.Font(treeView.Font.FontFamily, TreeViewFontSize);

                treeView.AfterCheck += TreeView_AfterCheck;
                treeView.NodeMouseDoubleClick += (sender, e) => e.Node.Checked = !e.Node.Checked;


                // Build TreeView nodes
                // Store the last TreeNode at each Depth level
                Dictionary<int, TreeNode> depthLastNode = new Dictionary<int, TreeNode>();

                foreach (var entry in entries)
                {
                    TreeNode currentNode = new TreeNode(entry.Description ?? "Unnamed")
                    {
                        Tag = entry,
                        Checked = entry.IsAutoAssembler, // Only Auto Assembler scripts are pre-selected
                    };

                    if (entry.IsGroup)
                    {
                        // Group nodes (e.g., #A, #B) cannot be selected
                        currentNode.NodeFont = new System.Drawing.Font(treeView.Font, System.Drawing.FontStyle.Bold);
                        currentNode.ForeColor = System.Drawing.Color.Gray; // Differentiate visually
                    }

                    // Find the correct parent node
                    if (entry.Depth == 0)
                    {
                        treeView.Nodes.Add(currentNode);
                    }
                    else
                    {
                        if (depthLastNode.TryGetValue(entry.Depth - 1, out TreeNode? parentNode) && parentNode != null)
                        {
                            parentNode.Nodes.Add(currentNode);
                        }
                        else
                        {
                            treeView.Nodes.Add(currentNode);
                        }
                    }

                    // Update the last node at this depth
                    depthLastNode[entry.Depth] = currentNode;
                }

                treeView.AfterCheck += (sender, e) =>
                {
                    if (e.Node != null)
                    {
                        CheatEntry? entry = e.Node.Tag as CheatEntry;
                        if (entry != null && entry.IsGroup)
                        {
                            e.Node.Checked = false;  // Force reset
                        }
                    }
                };

                treeView.BeforeCheck += (sender, e) =>
                {
                    if (e.Node != null)
                    {
                        CheatEntry? entry = e.Node.Tag as CheatEntry;
                        if (entry != null && entry.IsGroup)
                        {
                            e.Cancel = true; // Prevent checking
                        }
                    }
                };

                treeView.NodeMouseDoubleClick += (sender, e) =>
                {
                    TreeNode node = e.Node;
                    if (node == null) return;

                    CheatEntry? entry = node.Tag as CheatEntry;
                    if (entry != null && entry.IsGroup)
                    {
                        node.Checked = false;  // Ensure it remains unchecked
                        return;  // Do not process further toggle Checked
                    }

                    // Only allow non-group nodes to toggle
                    node.Checked = !node.Checked;
                };

                ExpandTreeView(treeView, DefaultTreeViewDepth);

                // Create selection form with proper disposal
                using (Form treeForm = new Form
                {
                    Text = "Select Cheat Entries",
                    Width = DefaultFormWidth,
                    Height = DefaultFormHeight,
                    StartPosition = FormStartPosition.CenterScreen
                })
                using (Label depthLabel = new Label
                {
                    Text = "Expand Depth:",
                    Dock = DockStyle.Top,
                    TextAlign = System.Drawing.ContentAlignment.MiddleLeft
                })
                using (NumericUpDown depthSelector = new NumericUpDown
                {
                    Minimum = 0,
                    Maximum = 10,
                    Value = DefaultTreeViewDepth,
                    Dock = DockStyle.Top
                })
                using (Button confirmButton = new Button
                {
                    Text = "Confirm",
                    Dock = DockStyle.Bottom,
                    DialogResult = DialogResult.OK
                })
                {
                    depthSelector.ValueChanged += (sender, e) =>
                    {
                        int depth = (int)depthSelector.Value;
                        ExpandTreeView(treeView, depth);
                    };

                    treeForm.Controls.Add(treeView);
                    treeForm.Controls.Add(depthSelector);
                    treeForm.Controls.Add(depthLabel);
                    treeForm.Controls.Add(confirmButton);

                    // Apply theme after adding controls
                    ApplyThemeToDialog(treeForm, treeView, depthLabel, depthSelector, confirmButton);

                    if (treeForm.ShowDialog() != DialogResult.OK)
                        return;

                    // Filter selected entries
                    var selectedEntries = GetCheckedNodes(treeView.Nodes)
                        .Select(node => (CheatEntry)node.Tag)
                        .ToList();

                    // Generate script with selected entries
                    GenerateAndShowScript(selectedEntries, entries);
                }
            }
        }

        private static void GenerateAndShowScript(List<CheatEntry> selectedEntries, List<CheatEntry> allEntries)
        {
            // Ensure correct order
            var enableOrder = GetOrderedEntries(selectedEntries, true);
            var disableOrder = GetOrderedEntries(allEntries, false);

            // Generate script with pre-allocated capacity
            StringBuilder scriptBuilder = new StringBuilder(DefaultStringBuilderCapacity);

            scriptBuilder.AppendLine("[ENABLE]");
            scriptBuilder.AppendLine("{$lua}");
            scriptBuilder.AppendLine("if (syntaxcheck) then return end");
            scriptBuilder.AppendLine("synchronize(function()");
            scriptBuilder.AppendLine("  getLuaEngine().menuItem5.doClick()");
            scriptBuilder.AppendLine("  getLuaEngine().Close()");
            scriptBuilder.AppendLine("end)");
            scriptBuilder.AppendLine("\nlocal enableBattleScripts = {");

            foreach (var entry in enableOrder)
            {
                scriptBuilder.AppendLine($"  {entry.Id}, -- {entry.Description}");
            }
            scriptBuilder.AppendLine("}");
            scriptBuilder.AppendLine("local addressList = getAddressList()");
            scriptBuilder.AppendLine("synchronize(function()");
            scriptBuilder.AppendLine("  for _, id in ipairs(enableBattleScripts) do");
            scriptBuilder.AppendLine("    local memRec = addressList.getMemoryRecordByID(id)");
            scriptBuilder.AppendLine("    if memRec and not memRec.Active then");
            scriptBuilder.AppendLine("      memRec.Active = true");
            scriptBuilder.AppendLine("      sleep(30)");
            scriptBuilder.AppendLine("    end");
            scriptBuilder.AppendLine("    addressList.refresh()");
            scriptBuilder.AppendLine("  end");
            scriptBuilder.AppendLine("end)");
            scriptBuilder.AppendLine("synchronize(function() getLuaEngine().Close() end)");

            scriptBuilder.AppendLine("[DISABLE]");
            scriptBuilder.AppendLine("{$lua}");
            scriptBuilder.AppendLine("if (syntaxcheck) then return end");
            scriptBuilder.AppendLine("synchronize(function()");
            scriptBuilder.AppendLine("  getLuaEngine().menuItem5.doClick()");
            scriptBuilder.AppendLine("  getLuaEngine().Close()");
            scriptBuilder.AppendLine("end)");
            scriptBuilder.AppendLine("\nlocal disableBattleScripts = {");

            foreach (var entry in disableOrder)
            {
                scriptBuilder.AppendLine($"  {entry.Id}, -- {entry.Description}");
            }
            scriptBuilder.AppendLine("}");
            scriptBuilder.AppendLine("local addressList = getAddressList()");
            scriptBuilder.AppendLine("synchronize(function()");
            scriptBuilder.AppendLine("  for _, id in ipairs(disableBattleScripts) do");
            scriptBuilder.AppendLine("    local memRec = addressList.getMemoryRecordByID(id)");
            scriptBuilder.AppendLine("    if memRec and memRec.Active then");
            scriptBuilder.AppendLine("      memRec.Active = false");
            scriptBuilder.AppendLine("      sleep(30)");
            scriptBuilder.AppendLine("    end");
            scriptBuilder.AppendLine("    addressList.refresh()");
            scriptBuilder.AppendLine("  end");
            scriptBuilder.AppendLine("end)");
            scriptBuilder.AppendLine("synchronize(function() getLuaEngine().Close() end)");

            // Add comments
            scriptBuilder.AppendLine("-- Comments:");
            foreach (var entry in allEntries)
            {
                string indent = new string(' ', entry.Depth * 2);
                scriptBuilder.AppendLine($"-- {indent}ID: {entry.Id}, Description: {entry.Description}, Depth: {entry.Depth}");
            }

            // Add syntax highlighting using Scintilla
            ShowScriptWithHighlighting(scriptBuilder.ToString());
        }

        private static void ShowScriptWithHighlighting(string script)
        {
            using (Form scriptForm = new Form { Width = ScriptFormWidth, Height = ScriptFormHeight, Text = "Generated Lua Script" })
            using (Scintilla scintilla = new Scintilla
            {
                Dock = DockStyle.Fill,
                Text = script,
                Lexer = Lexer.Lua
            })
            {
                // Set Lua syntax highlighting
                scintilla.Styles[Style.Default].Font = ScintillaFontName;
                scintilla.Styles[Style.Default].Size = ScintillaFontSize;
                scintilla.Styles[Style.Default].ForeColor = System.Drawing.Color.Black;
                scintilla.Styles[Style.Lua.Comment].ForeColor = System.Drawing.Color.Gray;
                scintilla.Styles[Style.Lua.CommentLine].ForeColor = System.Drawing.Color.Gray;
                scintilla.Styles[Style.Lua.String].ForeColor = System.Drawing.Color.Brown;
                scintilla.Styles[Style.Lua.Number].ForeColor = System.Drawing.Color.Purple;
                scintilla.Styles[Style.Lua.Operator].ForeColor = System.Drawing.Color.DarkOrange;
                scintilla.Styles[Style.Lua.Word].ForeColor = System.Drawing.Color.Blue;
                scintilla.Styles[Style.Lua.Word].Bold = true;

                scintilla.SetKeywords(0, LuaKeywords);

                scriptForm.Controls.Add(scintilla);
                
                // Apply theme
                ApplyThemeToScriptDialog(scriptForm, scintilla);
                
                scriptForm.ShowDialog();
            }
        }
        private static void ApplyThemeToDialog(Form form, TreeView treeView, Label label, NumericUpDown numericUpDown, Button button)
        {
            if (WindowsThemeHelper.IsThemeAwareSupported())
            {
                form.ApplyTheme();
                treeView.ApplyTheme();
                label.ApplyTheme();
                numericUpDown.ApplyTheme();
                button.ApplyTheme();
                
                // Update node themes
                UpdateNodeThemes(treeView.Nodes);
            }
        }

        private static void ApplyThemeToScriptDialog(Form form, Scintilla scintilla)
        {
            if (WindowsThemeHelper.IsThemeAwareSupported())
            {
                form.ApplyTheme();
                scintilla.ApplyTheme();
            }
        }

        private static void UpdateNodeThemes(TreeNodeCollection nodes)
        {
            foreach (TreeNode node in nodes)
            {
                if (node.Tag is CheatEntry entry)
                {
                    node.UpdateNodeTheme(entry.IsGroup);
                }
                
                // Recursively update child nodes
                if (node.Nodes.Count > 0)
                {
                    UpdateNodeThemes(node.Nodes);
                }
            }
        }

        private static void TreeView_AfterCheck(object? sender, TreeViewEventArgs e)
        {
            TreeView? treeView = sender as TreeView;
            if (treeView == null) return;

            treeView.BeginUpdate();

            try
            {
                if (e.Node != null)
                {
                    foreach (TreeNode child in e.Node.Nodes)
                    {
                        child.Checked = e.Node.Checked;
                    }
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

        private static int ParseId(string id)
        {
            return int.TryParse(id, out var result) ? result : int.MaxValue;
        }

        private static List<CheatEntry> GetOrderedEntries(List<CheatEntry> entries, bool ascending)
        {
            return ascending
                ? entries.OrderBy(e => e.Depth)
                         .ThenBy(e => ParseId(e.Id))
                         .ToList()
                : entries.OrderByDescending(e => e.Depth)
                         .ThenByDescending(e => ParseId(e.Id))
                         .ToList();
        }
    }

    public class CheatEntry
    {
        public string Id { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int Depth { get; set; }
        public bool IsAutoAssembler { get; set; }
        public bool HasOptionsWithMoHideChildren { get; set; }
        
        public bool HasChildren { get; set; }  
        public bool IsGroup { get; set; }      
    }
}
