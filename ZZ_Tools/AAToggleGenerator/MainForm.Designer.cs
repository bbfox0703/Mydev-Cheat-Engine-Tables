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
            this.btnAAToggleGen = new System.Windows.Forms.Button();
            this.btnIDRenumber = new System.Windows.Forms.Button();
            this.btnReplaceProcName = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // btnAAToggleGen
            // 
            this.btnAAToggleGen.Location = new System.Drawing.Point(41, 13);
            this.btnAAToggleGen.Margin = new System.Windows.Forms.Padding(4, 4, 4, 4);
            this.btnAAToggleGen.Name = "btnAAToggleGen";
            this.btnAAToggleGen.Size = new System.Drawing.Size(371, 45);
            this.btnAAToggleGen.TabIndex = 0;
            this.btnAAToggleGen.Text = "Generate AA bulk toggle script";
            this.btnAAToggleGen.UseVisualStyleBackColor = true;
            this.btnAAToggleGen.Click += new System.EventHandler(this.btnAAToggleGen_Click);
            // 
            // btnIDRenumber
            // 
            this.btnIDRenumber.Location = new System.Drawing.Point(41, 65);
            this.btnIDRenumber.Name = "btnIDRenumber";
            this.btnIDRenumber.Size = new System.Drawing.Size(371, 45);
            this.btnIDRenumber.TabIndex = 1;
            this.btnIDRenumber.Text = "Reassign .CT <ID> tag";
            this.btnIDRenumber.UseVisualStyleBackColor = true;
            this.btnIDRenumber.Click += new System.EventHandler(this.btnIDRenumber_Click);
            // 
            // btnReplaceProcName
            // 
            this.btnReplaceProcName.Location = new System.Drawing.Point(41, 116);
            this.btnReplaceProcName.Name = "btnReplaceProcName";
            this.btnReplaceProcName.Size = new System.Drawing.Size(371, 45);
            this.btnReplaceProcName.TabIndex = 2;
            this.btnReplaceProcName.Text = "Replace AOB .exe to $process";
            this.btnReplaceProcName.UseVisualStyleBackColor = true;
            this.btnReplaceProcName.Click += new System.EventHandler(this.btnReplaceProcName_Click);
            // 
            // MainForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(144F, 144F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            this.ClientSize = new System.Drawing.Size(456, 296);
            this.Controls.Add(this.btnReplaceProcName);
            this.Controls.Add(this.btnIDRenumber);
            this.Controls.Add(this.btnAAToggleGen);
            this.Font = new System.Drawing.Font("PMingLiU", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(136)));
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.Margin = new System.Windows.Forms.Padding(4, 4, 4, 4);
            this.MaximizeBox = false;
            this.Name = "MainForm";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "CE AA Script helper";
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button btnAAToggleGen;
        private System.Windows.Forms.Button btnIDRenumber;
        private System.Windows.Forms.Button btnReplaceProcName;
    }
}