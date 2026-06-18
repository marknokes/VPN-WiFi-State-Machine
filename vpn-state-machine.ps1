. "$PSScriptRoot\functions.ps1"

### Edit these variables ###
$tunnelName = "MyWireGuardTunnel"

$homeNetworks = @(
    'HomeNetwork',
    'HomeNetwork-5G'
)
### Stop Editing ###

$serviceName = "WireGuardTunnel`$$tunnelName"

$tunnelConfig = Join-Path $env:ProgramFiles (
    "WireGuard\Data\Configurations\{0}.conf.dpapi" -f $tunnelName
)

$result = Get-ConnectedWifiInterface -WlanInfo (netsh wlan show interfaces)

$state = Get-NetworkState -WifiResult $result -HomeNetworks $homeNetworks

Apply-State `
    -State $state `
    -WifiResult $result `
    -ServiceName $serviceName `
    -TunnelConfig $tunnelConfig