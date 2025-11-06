using System;
using System.Windows;
using System.Windows.Controls;

namespace TestWPFApp
{
    public class Program
    {
        [STAThread]
        public static void Main()
        {
            Application app = new Application();
            app.Startup += App_Startup;
            app.Run();
        }

        private static void App_Startup(object sender, StartupEventArgs e)
        {
            // Create a very simple window
            Window window = new Window
            {
                Title = "Test WPF Window",
                Width = 400,
                Height = 300,
                WindowStartupLocation = WindowStartupLocation.CenterScreen
            };

            // Add some content
            StackPanel panel = new StackPanel();
            panel.Children.Add(new TextBlock { Text = "This is a test window", Margin = new Thickness(20) });
            Button button = new Button { Content = "Click Me", Width = 100, Margin = new Thickness(20) };
            button.Click += (s, args) => MessageBox.Show("Button clicked!");
            panel.Children.Add(button);
            window.Content = panel;

            // Show the window
            window.Show();
        }
    }
}