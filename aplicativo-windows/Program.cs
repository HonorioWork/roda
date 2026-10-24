using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

[assembly: System.Reflection.AssemblyTitle("Roda")]
[assembly: System.Reflection.AssemblyProduct("Roda")]
[assembly: System.Reflection.AssemblyCompany("HonorioWork")]
[assembly: System.Reflection.AssemblyVersion("1.4.4.0")]
[assembly: System.Reflection.AssemblyFileVersion("1.4.4.0")]

namespace RodaWindows
{
    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new RodaWindow());
        }
    }

    internal sealed class RodaWindow : Form
    {
        private const string CurrentVersion = "1.4.4";
        private const string RodaUrl = "https://honoriowork.github.io/roda/?app=windows";
        private const string UpdateManifestUrl = "https://honoriowork.github.io/roda/updates/windows.json";
        private const string TrustedDownloadHost = "honoriowork.github.io";
        private readonly WebView2 webView;
        private readonly Label startupStatus;
        private readonly NotifyIcon trayIcon;

        [DllImport("dwmapi.dll")]
        private static extern int DwmSetWindowAttribute(IntPtr window, int attribute, ref int value, int size);

        public RodaWindow()
        {
            Text = "Roda";
            StartPosition = FormStartPosition.Manual;
            Size = new Size(1180, 700);
            MinimumSize = new Size(420, 520);
            BackColor = Color.FromArgb(12, 17, 24);
            AutoScaleMode = AutoScaleMode.Dpi;
            FormBorderStyle = FormBorderStyle.Sizable;
            try { Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { }

            trayIcon = new NotifyIcon
            {
                Icon = Icon,
                Text = "Roda",
                Visible = true
            };
            trayIcon.BalloonTipClicked += delegate { RestoreWindow(); };

            webView = new WebView2
            {
                Dock = DockStyle.Fill,
                DefaultBackgroundColor = Color.FromArgb(12, 17, 24),
                Visible = false
            };
            startupStatus = new Label
            {
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleCenter,
                ForeColor = Color.Gainsboro,
                BackColor = Color.FromArgb(12, 17, 24),
                Font = new Font("Segoe UI", 12),
                Text = "Verificando atualizações…"
            };
            Controls.Add(webView);
            Controls.Add(startupStatus);
            HandleCreated += delegate { ApplyTitleBar(true); };
            Load += delegate { FitAndCenterWindow(); };
            Shown += InitializeRoda;
        }

        private void FitAndCenterWindow()
        {
            Rectangle workArea = Screen.FromPoint(Cursor.Position).WorkingArea;
            int availableWidth = Math.Max(1, workArea.Width - 32);
            int availableHeight = Math.Max(1, workArea.Height - 32);
            int width = Math.Min(1180, (int)Math.Floor(workArea.Width * 0.88));
            int height = Math.Min(700, (int)Math.Floor(workArea.Height * 0.90));

            width = Math.Min(availableWidth, Math.Max(Math.Min(900, availableWidth), width));
            height = Math.Min(availableHeight, Math.Max(Math.Min(560, availableHeight), height));
            Bounds = new Rectangle(
                workArea.Left + (workArea.Width - width) / 2,
                workArea.Top + (workArea.Height - height) / 2,
                width,
                height);
        }

        private void ApplyTitleBar(bool dark)
        {
            try
            {
                int enabled = dark ? 1 : 0;
                if (DwmSetWindowAttribute(Handle, 20, ref enabled, sizeof(int)) != 0)
                    DwmSetWindowAttribute(Handle, 19, ref enabled, sizeof(int));
                Color background = dark ? Color.FromArgb(12, 17, 24) : Color.FromArgb(242, 243, 245);
                BackColor = background;
                startupStatus.BackColor = background;
                startupStatus.ForeColor = dark ? Color.Gainsboro : Color.FromArgb(30, 31, 34);
                webView.DefaultBackgroundColor = background;
            }
            catch { }
        }

        private async void InitializeRoda(object sender, EventArgs args)
        {
            Shown -= InitializeRoda;
            try
            {
                if (await TryInstallUpdateAsync()) return;
                startupStatus.Text = "Abrindo o Roda…";

                string dataFolder = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "Roda",
                    "WebView2");
                Directory.CreateDirectory(dataFolder);

                CoreWebView2Environment environment =
                    await CoreWebView2Environment.CreateAsync(null, dataFolder);
                await webView.EnsureCoreWebView2Async(environment);

                CoreWebView2 core = webView.CoreWebView2;
                core.Settings.IsStatusBarEnabled = false;
                core.Settings.AreDevToolsEnabled = false;
                core.Settings.AreBrowserAcceleratorKeysEnabled = false;
                core.Settings.IsZoomControlEnabled = true;
                core.Settings.UserAgent = core.Settings.UserAgent + " RodaWindows/" + CurrentVersion;

                core.NewWindowRequested += delegate(object requestSender, CoreWebView2NewWindowRequestedEventArgs request)
                {
                    request.Handled = true;
                    core.Navigate(request.Uri);
                };
                core.ProcessFailed += delegate
                {
                    BeginInvoke(new Action(delegate { ShowFailure("O aplicativo encontrou uma falha. Feche e abra o Roda novamente."); }));
                };
                core.WebMessageReceived += delegate(object messageSender, CoreWebView2WebMessageReceivedEventArgs message)
                {
                    try
                    {
                        string value = message.TryGetWebMessageAsString();
                        string[] parts = value.Split(new[] { '\t' }, 3);
                        if (parts.Length == 3 && parts[0] == "RODA_NOTIFY")
                        {
                            trayIcon.BalloonTipTitle = parts[1];
                            trayIcon.BalloonTipText = parts[2];
                            trayIcon.BalloonTipIcon = ToolTipIcon.Info;
                            trayIcon.ShowBalloonTip(10000);
                        }
                        else if (parts.Length >= 2 && parts[0] == "RODA_THEME")
                        {
                            bool dark = !string.Equals(parts[1], "light", StringComparison.OrdinalIgnoreCase);
                            BeginInvoke(new Action(delegate { ApplyTitleBar(dark); }));
                        }
                    }
                    catch { }
                };

                startupStatus.Visible = false;
                webView.Visible = true;
                core.Navigate(RodaUrl + "&versao=" + CurrentVersion + "&atual=" + DateTimeOffset.UtcNow.ToUnixTimeSeconds());
            }
            catch (WebView2RuntimeNotFoundException)
            {
                ShowFailure("O componente WebView2 do Windows não foi encontrado. Atualize o Microsoft Edge ou instale o WebView2 Runtime e abra o Roda novamente.");
            }
            catch (Exception)
            {
                ShowFailure("Não foi possível abrir o Roda. Confira a conexão com a internet e tente novamente.");
            }
        }

        private void RestoreWindow()
        {
            if (WindowState == FormWindowState.Minimized) WindowState = FormWindowState.Normal;
            Show();
            Activate();
            webView.Focus();
        }

        private async Task<bool> TryInstallUpdateAsync()
        {
            try
            {
                string cacheBuster = "?t=" + DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                string json;
                using (WebClient client = NewWebClient())
                    json = await client.DownloadStringTaskAsync(new Uri(UpdateManifestUrl + cacheBuster));

                string versionText = ReadJsonString(json, "version");
                string urlText = ReadJsonString(json, "url");
                string expectedHash = ReadJsonString(json, "sha256").ToUpperInvariant();
                Version available;
                Uri downloadUri;
                if (!Version.TryParse(versionText, out available) ||
                    available <= new Version(CurrentVersion) ||
                    !Uri.TryCreate(urlText, UriKind.Absolute, out downloadUri) ||
                    downloadUri.Scheme != Uri.UriSchemeHttps ||
                    !string.Equals(downloadUri.Host, TrustedDownloadHost, StringComparison.OrdinalIgnoreCase) ||
                    !downloadUri.AbsolutePath.StartsWith("/roda/downloads/", StringComparison.Ordinal) ||
                    !Regex.IsMatch(expectedHash, "^[A-F0-9]{64}$"))
                    return false;

                startupStatus.Text = "Baixando a atualização " + versionText + "…";
                string updates = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "Roda",
                    "Updates");
                Directory.CreateDirectory(updates);
                string attemptMarker = Path.Combine(updates, "last-attempt-" + versionText + ".txt");
                if (File.Exists(attemptMarker) && File.GetLastWriteTimeUtc(attemptMarker) > DateTime.UtcNow.AddHours(-6))
                    return false;
                string finalPath = Path.Combine(updates, "Roda-Setup-" + versionText + ".msi");
                string temporaryPath = finalPath + ".download";
                if (File.Exists(temporaryPath)) File.Delete(temporaryPath);

                using (WebClient client = NewWebClient())
                    await client.DownloadFileTaskAsync(downloadUri, temporaryPath);

                if (!string.Equals(FileSha256(temporaryPath), expectedHash, StringComparison.OrdinalIgnoreCase))
                {
                    File.Delete(temporaryPath);
                    throw new InvalidDataException("A atualização baixada não passou na verificação.");
                }
                if (File.Exists(finalPath)) File.Delete(finalPath);
                File.Move(temporaryPath, finalPath);

                startupStatus.Text = "Instalando a atualização " + versionText + "…";
                File.WriteAllText(attemptMarker, DateTime.UtcNow.ToString("O"));
                Process.Start(new ProcessStartInfo
                {
                    FileName = "msiexec.exe",
                    Arguments = "/i \"" + finalPath + "\" /passive /norestart",
                    UseShellExecute = true
                });
                BeginInvoke(new Action(Close));
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static WebClient NewWebClient()
        {
            WebClient client = new WebClient();
            client.Headers[HttpRequestHeader.UserAgent] = "RodaWindows/" + CurrentVersion;
            client.Headers[HttpRequestHeader.CacheControl] = "no-cache";
            return client;
        }

        private static string ReadJsonString(string json, string property)
        {
            Match match = Regex.Match(json, "\"" + Regex.Escape(property) + "\"\\s*:\\s*\"([^\"]*)\"",
                RegexOptions.CultureInvariant);
            return match.Success ? match.Groups[1].Value : string.Empty;
        }

        private static string FileSha256(string path)
        {
            using (SHA256 sha = SHA256.Create())
            using (FileStream stream = File.OpenRead(path))
                return BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", string.Empty);
        }

        private void ShowFailure(string message)
        {
            Controls.Clear();
            Label title = new Label
            {
                AutoSize = true,
                ForeColor = Color.White,
                Font = new Font("Segoe UI", 18, FontStyle.Bold),
                Text = "Roda"
            };
            Label detail = new Label
            {
                AutoSize = true,
                MaximumSize = new Size(520, 0),
                ForeColor = Color.Gainsboro,
                Font = new Font("Segoe UI", 11),
                Text = message
            };
            Button retry = new Button
            {
                AutoSize = true,
                Text = "Tentar novamente",
                Padding = new Padding(12, 5, 12, 5)
            };
            retry.Click += delegate { Application.Restart(); };

            FlowLayoutPanel panel = new FlowLayoutPanel
            {
                Dock = DockStyle.Fill,
                FlowDirection = FlowDirection.TopDown,
                WrapContents = false,
                Padding = new Padding(48),
                BackColor = Color.FromArgb(12, 17, 24)
            };
            panel.Controls.Add(title);
            panel.Controls.Add(detail);
            panel.Controls.Add(retry);
            Controls.Add(panel);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                trayIcon.Visible = false;
                trayIcon.Dispose();
                webView.Dispose();
            }
            base.Dispose(disposing);
        }
    }
}
