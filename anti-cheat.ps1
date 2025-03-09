Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WindowDetector {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowDisplayAffinity(IntPtr hWnd, out uint affinity);
    
    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    
    public const uint WDA_NONE = 0;
    public const uint WDA_EXCLUDEFROMCAPTURE = 1;
    public const uint WDA_MONITOR = 2;
    
    public static string GetWindowTitle(IntPtr hWnd) {
        int length = GetWindowTextLength(hWnd);
        if (length == 0) return "";
        StringBuilder sb = new StringBuilder(length + 1);
        GetWindowText(hWnd, sb, sb.Capacity);
        return sb.ToString();
    }
    
    public static uint GetWindowProcessId(IntPtr hWnd) {
        uint processId = 0;
        GetWindowThreadProcessId(hWnd, out processId);
        return processId;
    }
}
"@

# Initialize a global ArrayList to hold app details for each scan
$global:protectedApps = New-Object System.Collections.ArrayList

# Define the callback to process each window found
$enumWindowsCallback = [WindowDetector+EnumWindowsProc] {
    param($hWnd, $lParam)
    
    # Check the window display affinity
    $affinity = 0
    $result = [WindowDetector]::GetWindowDisplayAffinity($hWnd, [ref]$affinity)
    
    # If the window is using content protection, get details and add to our list
    if ($result -and $affinity -ne [WindowDetector]::WDA_NONE) {
        $title = [WindowDetector]::GetWindowTitle($hWnd)
        $processId = [WindowDetector]::GetWindowProcessId($hWnd)
        
        try {
            $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
            $processName    = $process.ProcessName
            $processPath    = $process.Path
            $productName    = $process.MainModule.FileVersionInfo.ProductName
            $companyName    = $process.MainModule.FileVersionInfo.CompanyName
            $fileDescription= $process.MainModule.FileVersionInfo.FileDescription
        }
        catch {
            $processName    = "Unknown"
            $processPath    = "Unknown"
            $productName    = "Unknown"
            $companyName    = "Unknown"
            $fileDescription= "Unknown"
        }
        
        $protectedInfo = [PSCustomObject]@{
            WindowTitle    = $title
            ProcessId      = $processId
            ProcessName    = $processName
            ProcessPath    = $processPath
            ProductName    = $productName
            CompanyName    = $companyName
            FileDescription= $fileDescription
            AffinityValue  = $affinity
            IsVisible      = [WindowDetector]::IsWindowVisible($hWnd)
        }
        [void]$global:protectedApps.Add($protectedInfo)
    }
    
    return $true
}

# Continuous loop for live scanning
while ($true) {
    $global:protectedApps.Clear()
    
    # Enumerate windows to populate $global:protectedApps
    [WindowDetector]::EnumWindows($enumWindowsCallback, [IntPtr]::Zero) | Out-Null
    
    Clear-Host
    
    # Get the count of detected protected windows
    $count = $global:protectedApps.Count
    Write-Host "Scanning for Protected Windows..." -ForegroundColor Cyan
    Write-Host "Detected Protected Windows: $count" -ForegroundColor Yellow
    Write-Host "Last Scan: $(Get-Date)" -ForegroundColor Gray
    
    # If any window is detected, display detailed app information in red with an alert
    if ($count -gt 0) {
        Write-Host "ALERT: Applications using content protection API found!" -ForegroundColor Red
        foreach ($window in $global:protectedApps) {
            Write-Host "------------------------------------" -ForegroundColor Red
            Write-Host "Application: $($window.ProcessName)" -ForegroundColor Red
            Write-Host "Window Title: $($window.WindowTitle)" -ForegroundColor Red
            Write-Host "Product Name: $($window.ProductName)" -ForegroundColor Red
            Write-Host "Company: $($window.CompanyName)" -ForegroundColor Red
            Write-Host "Description: $($window.FileDescription)" -ForegroundColor Red
            Write-Host "Process ID: $($window.ProcessId)" -ForegroundColor Red
            Write-Host "Process Path: $($window.ProcessPath)" -ForegroundColor Red
            Write-Host "Protection Level: $($window.AffinityValue)" -ForegroundColor Red
            Write-Host "Visible: $($window.IsVisible)" -ForegroundColor Red
        }
    }
    
    # Sleep interval as needed
    Start-Sleep -Seconds 1
}
