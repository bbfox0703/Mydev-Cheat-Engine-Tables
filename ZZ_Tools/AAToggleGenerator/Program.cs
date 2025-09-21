using System;
using System.Windows.Forms;

namespace AAToggleGenerator
{
    class Program
    {
        [STAThread]
        static void Main()
        {
            // Enable high DPI awareness for .NET Framework and .NET Core/.NET 5+
            Application.SetHighDpiMode(HighDpiMode.SystemAware);
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            Application.Run(new MainForm());
        }
    }
}
