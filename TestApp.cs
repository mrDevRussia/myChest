using System;
using System.Windows;
using System.Windows.Controls;

namespace TestApp
{
    public class Program
    {
        [STAThread]
        public static void Main()
        {
            Application app = new Application();
            Window window = new Window
            {
                Title = "Test Window",
                Width = 400,
                Height = 300,
                WindowStartupLocation = WindowStartupLocation.CenterScreen,
                Content = new TextBlock { Text = "This is a test window", FontSize = 24, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center }
            };
            
            window.WindowState = WindowState.Normal;
            window.Visibility = Visibility.Visible;
            window.Show();
            window.Activate();
            window.Focus();
            
            app.Run(window);
        }
    }
}