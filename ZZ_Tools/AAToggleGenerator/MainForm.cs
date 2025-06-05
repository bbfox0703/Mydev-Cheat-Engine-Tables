using System;
using System.Windows.Forms;

namespace AAToggleGenerator
{
    public partial class MainForm : Form
    {
        public MainForm()
        {
            InitializeComponent();
        }

        private void btnAAToggleGen_Click(object sender, EventArgs e)
        {
            try
            {
                ScriptGenerator.StartScriptGeneration();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An error occurred: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void btnIDRenumber_Click(object sender, EventArgs e)
        {
            try
            {
                OpenFileDialog openFileDialog = new OpenFileDialog
                {
                    Filter = "Cheat Engine Table (*.CT)|*.CT",
                    Title = "Select a Cheat Engine Table for re-number"
                };

                if (openFileDialog.ShowDialog() == DialogResult.OK)
                {
                    CTFileIDProcessor.RenumberIDs(openFileDialog.FileName);

                    MessageBox.Show("ID reassign completed successfully.", "Success",
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An unexpected error occurred: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void btnReplaceProcName_Click(object sender, EventArgs e)
        {
            try
            {
                OpenFileDialog openFileDialog = new OpenFileDialog
                {
                    Filter = "Cheat Engine Table (*.CT)|*.CT",
                    Title = "Select a Cheat Engine Table"
                };

                if (openFileDialog.ShowDialog() == DialogResult.OK)
                {
                    CTRenameEXE2Process.ReplaceProcessName(openFileDialog.FileName);

                    MessageBox.Show("Process name replacement completed successfully.", "Success",
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An unexpected error occurred: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

    }
}
