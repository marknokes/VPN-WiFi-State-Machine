function Get-NetworkState {
    param(
        $WifiResult,
        [string[]]$HomeNetworks
    )

    if (
        -not $WifiResult -or
        -not $WifiResult.SSID -or
        -not $WifiResult.InterfaceName
    ) {
        return "Unknown"
    }

    if ($WifiResult.SSID -in $HomeNetworks) {
        return "Home"
    }

    return "Remote"
}

function Apply-State {
    param(
        [string]$State,
        $WifiResult,
        [string]$ServiceName,
        [string]$TunnelConfig
    )

    switch ($State) {

        "Unknown" {
            return
        }

        "Home" {
            Enter-HomeState `
                -WifiResult $WifiResult `
                -ServiceName $ServiceName
        }

        "Remote" {
            Enter-RemoteState `
                -WifiResult $WifiResult `
                -ServiceName $ServiceName `
                -TunnelConfig $TunnelConfig
        }
    }
}

function Enter-HomeState {
    param(
        $WifiResult,
        [string]$ServiceName
    )

    Reset-Dns -InterfaceAlias $WifiResult.InterfaceName

    $service = Ensure-WireGuardService -ServiceName $ServiceName

    if ($service.Status -eq 'Running') {
        Stop-Service -Name $ServiceName
    }

    $service = Get-WireGuardService $ServiceName
    $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(10))

    Stop-WireGuardGui
}

function Enter-RemoteState {
    param(
        $WifiResult,
        [string]$ServiceName,
        [string]$TunnelConfig
    )

    Set-CloudflareDns -InterfaceAlias $WifiResult.InterfaceName

    $service = Ensure-WireGuardService -ServiceName $ServiceName -TunnelConfig $TunnelConfig

    if ($service.Status -ne 'Running') {
        Start-Service -Name $ServiceName
    }

    $service = Get-WireGuardService $ServiceName
    $service.WaitForStatus('Running', [TimeSpan]::FromSeconds(10))

    Start-Process wireguard
}

function Get-WireGuardService {
    param($ServiceName)

    Get-Service $ServiceName -ErrorAction SilentlyContinue
}

function Ensure-WireGuardService {
    param(
        [string]$ServiceName,
        [string]$TunnelConfig
    )

    $service = Get-WireGuardService $ServiceName

    if (-not $service) {
        & wireguard /installtunnelservice $TunnelConfig
        $service = Wait-ServiceExists -ServiceName $ServiceName
    }

    return Get-WireGuardService $ServiceName
}

function Wait-ServiceExists {
    param(
        [string]$ServiceName,
        [int]$TimeoutSeconds = 10
    )

    for ($i = 0; $i -lt $TimeoutSeconds; $i++) {

        $service = Get-WireGuardService $ServiceName

        if ($service) {
            return $service
        }

        Start-Sleep -Seconds 1
    }

    return $null
}

function Reset-Dns {
    param([string]$InterfaceAlias)

    Set-DnsClientServerAddress `
        -InterfaceAlias $InterfaceAlias `
        -ResetServerAddresses
}

function Set-CloudflareDns {
    param([string]$InterfaceAlias)

    $desiredDns = @(
        '1.1.1.1',
        '1.0.0.1',
        '2606:4700:4700::1111',
        '2606:4700:4700::1001'
    )

    $currentDns = @(Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias).ServerAddresses

    if (@(Compare-Object $currentDns $desiredDns -SyncWindow 0).Count -gt 0) {
        Set-DnsClientServerAddress `
            -InterfaceAlias $InterfaceAlias `
            -ServerAddresses $desiredDns
    }
}

function Stop-WireGuardGui {
    Get-Process wireguard -ErrorAction SilentlyContinue |
        Stop-Process -Force
}

function Get-ConnectedWifiInterface {
    [CmdletBinding()]
    param(
        [string[]]$WlanInfo
    )

    $interfaceName  = $null
    $interfaceState = $null
    $ssid           = $null

    foreach ($line in $WlanInfo) {

        if ($line -match '^\s*Name\s*:\s*(.+)$') {

            if (
                $interfaceName -and
                $ssid -and
                $interfaceState -eq 'connected'
            ) {
                return [PSCustomObject]@{
                    InterfaceName = $interfaceName
                    SSID          = $ssid
                }
            }

            $interfaceName  = $matches[1].Trim()
            $interfaceState = $null
            $ssid           = $null
            continue
        }

        if ($line -match '^\s*State\s*:\s*(.+)$') {
            $interfaceState = $matches[1].Trim().ToLowerInvariant()
            continue
        }

        # Match SSID but not BSSID
        if ($line -match '^\s*SSID\s*:\s*(.+)$') {
            $ssid = $matches[1].Trim()
        }
    }

    if (
        $interfaceName -and
        $ssid -and
        $interfaceState -eq 'connected'
    ) {
        return [PSCustomObject]@{
            InterfaceName = $interfaceName
            SSID          = $ssid
        }
    }

    return $null
}