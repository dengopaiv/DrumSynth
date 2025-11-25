using System.Windows;

namespace DrumSynth;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        // Ensure UI Automation is available for screen readers
        System.Windows.Automation.Peers.AutomationPeer.ListenerExists(
            System.Windows.Automation.Peers.AutomationEvents.PropertyChanged);
    }
}
