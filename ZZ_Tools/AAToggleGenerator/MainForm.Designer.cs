namespace AAToggleGenerator
{
    partial class MainForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(MainForm));
            btnAAToggleGen = new System.Windows.Forms.Button();
            btnIDRenumber = new System.Windows.Forms.Button();
            btnReplaceProcName = new System.Windows.Forms.Button();
            SuspendLayout();
            // 
            // btnAAToggleGen
            // 
            btnAAToggleGen.Location = new System.Drawing.Point(13, 13);
            btnAAToggleGen.Margin = new System.Windows.Forms.Padding(4);
            btnAAToggleGen.Name = "btnAAToggleGen";
            btnAAToggleGen.Size = new System.Drawing.Size(300, 26);
            btnAAToggleGen.TabIndex = 0;
            btnAAToggleGen.Text = "Generate AA bulk toggle script";
            btnAAToggleGen.UseVisualStyleBackColor = true;
            btnAAToggleGen.Click += btnAAToggleGen_Click;
            // 
            // btnIDRenumber
            // 
            btnIDRenumber.Location = new System.Drawing.Point(13, 46);
            btnIDRenumber.Name = "btnIDRenumber";
            btnIDRenumber.Size = new System.Drawing.Size(300, 26);
            btnIDRenumber.TabIndex = 1;
            btnIDRenumber.Text = "Reassign .CT <ID> tag";
            btnIDRenumber.UseVisualStyleBackColor = true;
            btnIDRenumber.Click += btnIDRenumber_Click;
            // 
            // btnReplaceProcName
            // 
            btnReplaceProcName.Location = new System.Drawing.Point(13, 78);
            btnReplaceProcName.Name = "btnReplaceProcName";
            btnReplaceProcName.Size = new System.Drawing.Size(300, 26);
            btnReplaceProcName.TabIndex = 2;
            btnReplaceProcName.Text = "Replace AOB .exe to $process";
            btnReplaceProcName.UseVisualStyleBackColor = true;
            btnReplaceProcName.Click += btnReplaceProcName_Click;
            // 
            // MainForm
            // 
            AutoScaleDimensions = new System.Drawing.SizeF(96F, 96F);
            AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            ClientSize = new System.Drawing.Size(322, 157);
            Controls.Add(btnReplaceProcName);
            Controls.Add(btnIDRenumber);
            Controls.Add(btnAAToggleGen);
            Font = new System.Drawing.Font("新細明體", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, 136);
            Icon = (System.Drawing.Icon)resources.GetObject("$this.Icon");
            Margin = new System.Windows.Forms.Padding(4);
            MaximizeBox = false;
            Name = "MainForm";
            StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            Text = "CE AA Script helper";
            ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button btnAAToggleGen;
        private System.Windows.Forms.Button btnIDRenumber;
        private System.Windows.Forms.Button btnReplaceProcName;
    }
}