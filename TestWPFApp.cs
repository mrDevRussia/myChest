using System;
using System.Windows;

namespace TestWpfApp
{
    public class Program
    {
        [STAThread]
        public static void Main()
        {
            var app = new Application();
            var window = new Window
            {
                Title = "Test Window",
                Width = 400,
                Height = 300,
                WindowStartupLocation = WindowStartupLocation.CenterScreen
            };

            app.Run(window);
        }
    }
}