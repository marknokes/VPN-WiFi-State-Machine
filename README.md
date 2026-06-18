# WireGuard VPN State Machine

A simple PowerShell-based state machine that automatically enables or disables a WireGuard tunnel based on the currently connected Wi-Fi network.

The script is intended to keep your VPN disconnected while you're on trusted home networks and automatically connect it everywhere else.

## How It Works

The script performs the following steps:

1. Detects the currently connected Wi-Fi network.
2. Determines whether the network is one of your configured trusted networks.
3. Applies the appropriate VPN state:

   * **Home network:** WireGuard tunnel is stopped.
   * **Any other network:** WireGuard tunnel is started.

## DNS Management

In addition to managing the WireGuard tunnel state, the script also automatically adjusts the DNS configuration of the active Wi-Fi adapter. When connected to a trusted home network, the adapter's DNS settings are reset to use the network's default configuration (typically provided by your router via DHCP). When connected to any untrusted or remote network, the script configures the adapter to use Cloudflare's public DNS resolvers (1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, and 2606:4700:4700::1001). The DNS settings are only changed when necessary, avoiding unnecessary network reconfiguration and ensuring consistent name resolution behavior while using the VPN on public networks.

## Configuration

Edit the following variables in the main script:

```powershell
$tunnelName = "MyWireGuardTunnel"

$homeNetworks = @(
    'HomeNetwork',
    'HomeNetwork-5G'
)
```

### `$tunnelName`

The name of your WireGuard tunnel as it appears in the WireGuard client.

Example:

```powershell
$tunnelName = "WorkVPN"
```

### `$homeNetworks`

An array of trusted Wi-Fi SSIDs where the VPN should remain disconnected.

Example:

```powershell
$homeNetworks = @(
    'MyHomeWifi',
    'MyHomeWifi-5G',
    'GuestNetwork'
)
```

## Requirements

* Windows 10 or Windows 11
* PowerShell 5.1 or later
* WireGuard for Windows installed
* A configured WireGuard tunnel

The script expects the WireGuard tunnel configuration to exist at:

```text
%ProgramFiles%\WireGuard\Data\Configurations\<TunnelName>.conf.dpapi
```

## Installing the Scheduled Task

The repository includes an `install-task.ps1` script that installs the scheduled task used to run the VPN state machine automatically.

### Installation Steps

1. Open the Start Menu.
2. Search for **PowerShell**.
3. Right-click **Windows PowerShell** and select **Run as administrator**.
4. Navigate to the project directory:

```powershell
cd "C:\Path\To\WireGuard-StateMachine"
```

5. Run the installer:

```powershell
.\install-task.ps1
```

The installer will create the scheduled task and configure it to run automatically.

## Updating Configuration

After changing the tunnel name or home network list:

1. Save your changes.
2. Re-run the installer if the scheduled task configuration needs to be updated:

```powershell
.\install-task.ps1
```

## Manual Execution

You can test the state machine manually:

```powershell
.\vpn-state-machine.ps1
```

## Project Structure

```text
.
├── vpn-state-machine.ps1
├── functions.ps1
├── install-task.ps1
└── README.md
```

## Example Behavior

| Connected Network | VPN Action     |
| ----------------- | -------------- |
| HomeNetwork       | Disconnect VPN |
| HomeNetwork-5G    | Disconnect VPN |
| CoffeeShopWiFi    | Connect VPN    |
| AirportWiFi       | Connect VPN    |

## License

GNU General Public License v3.0
