# Anti-Cheat

This repository demonstrates a rough concept of an anti-cheat system that continuously scans for windows using content protection APIs. The goal is to create an app that stays pinned on top of the screen, displaying continuous updates to help improve cheat detection.

### Implementation

1. Enumerate Windows: Uses the EnumWindows API to scan all active windows
  
2. Check Protection Status: Calls GetWindowDisplayAffinity to determine if a window is protected

3. Gather Process Details: Collects detailed information about protected processes

4. Live Monitoring: Updates the display in real-time with protection status changes


### Future Development
This proof-of-concept demonstrates the core detection logic. Future enhancements could include:
- Always-on-Top Window
- GUI interface for easier monitoring
- Logging capabilities for historical analysis
- Notification system for new protected windows
- Cross-platform support for other operating systems

### Running the PowerShell Script

1. Copy the PowerShell script into a `.ps1` file.
2. Open PowerShell as Administrator.
3. Run the script to start scanning for content-protected windows.
