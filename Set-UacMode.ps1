#Requires -Version 5.1
<#
.SYNOPSIS
    Switches Windows User Account Control between the stock behaviour and a no-prompt mode.

.DESCRIPTION
    Manages three values under HKLM\...\Policies\System: EnableLUA,
    ConsentPromptBehaviorAdmin and PromptOnSecureDesktop. The values present before
    the first change are saved to %ProgramData%\UacMode\backup.json, so Restore
    returns the machine to exactly that state rather than to assumed defaults.

    If the script is not running elevated it relaunches itself through RunAs.

.PARAMETER Mode
    NoPrompt  UAC stays on, administrators are elevated silently. Applies immediately.
              Processes still start with a filtered token unless they request elevation.
    Disabled  UAC is off (EnableLUA = 0). Every process of an administrator gets the
              full token. Requires a restart. Store/UWP apps stop launching in this mode.
    Restore   Writes back the saved values, or Windows defaults if no backup exists.

.PARAMETER Restart
    Schedules a restart when the change only takes effect after one.

.EXAMPLE
    .\Set-UacMode.ps1 -Mode Disabled -Restart

.NOTES
    Exit codes: 0 success, 1 failure, 1223 elevation was cancelled.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('NoPrompt', 'Disabled', 'Restore')]
    [string] $Mode,

    [switch] $Restart,

    # Set on the elevated relaunch so its window stays open long enough to read the output.
    [Parameter(DontShow)]
    [switch] $PauseOnExit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$PolicyKey           = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$BackupDir           = Join-Path $env:ProgramData 'UacMode'
$BackupFile          = Join-Path $BackupDir 'backup.json'
$RestartDelaySeconds = 15
$ErrorCancelled      = 1223

$WindowsDefaults = [ordered]@{
    EnableLUA                  = 1
    ConsentPromptBehaviorAdmin = 5
    PromptOnSecureDesktop      = 1
}

$ModeProfiles = @{
    NoPrompt = [ordered]@{ EnableLUA = 1; ConsentPromptBehaviorAdmin = 0; PromptOnSecureDesktop = 0 }
    Disabled = [ordered]@{ EnableLUA = 0; ConsentPromptBehaviorAdmin = 0; PromptOnSecureDesktop = 0 }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    ([Security.Principal.WindowsPrincipal] $identity).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Elevated {
    $arguments = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`"",
        '-Mode', $Mode,
        '-PauseOnExit'
    )
    if ($Restart) { $arguments += '-Restart' }

    try {
        $process = Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList $arguments `
            -Verb RunAs -Wait -PassThru
    }
    catch [System.InvalidOperationException] {
        Write-Warning 'Elevation was cancelled; nothing was changed.'
        return $ErrorCancelled
    }
    $process.ExitCode
}

# A missing value is recorded as $null so Restore can delete it instead of inventing one.
function Get-UacState {
    $state = [ordered]@{}
    $key = Get-ItemProperty -Path $PolicyKey
    foreach ($name in $WindowsDefaults.Keys) {
        $property = $key.PSObject.Properties[$name]
        $state[$name] = if ($null -ne $property) { [int] $property.Value } else { $null }
    }
    $state
}

function Set-UacState {
    param([Parameter(Mandatory)] [System.Collections.IDictionary] $State)

    foreach ($name in $State.Keys) {
        if ($null -eq $State[$name]) {
            Remove-ItemProperty -Path $PolicyKey -Name $name -ErrorAction SilentlyContinue
        }
        else {
            New-ItemProperty -Path $PolicyKey -Name $name -PropertyType DWord `
                -Value $State[$name] -Force | Out-Null
        }
    }
}

function Save-Backup {
    param([Parameter(Mandatory)] [System.Collections.IDictionary] $State)

    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    $State | ConvertTo-Json | Set-Content -Path $BackupFile -Encoding UTF8
}

function Read-Backup {
    $json = Get-Content -Path $BackupFile -Raw | ConvertFrom-Json
    $state = [ordered]@{}
    foreach ($name in $WindowsDefaults.Keys) {
        $property = $json.PSObject.Properties[$name]
        $state[$name] = if ($null -ne $property -and $null -ne $property.Value) {
            [int] $property.Value
        } else { $null }
    }
    $state
}

# Windows treats an absent EnableLUA as enabled.
function Get-EffectiveLua {
    param([System.Collections.IDictionary] $State)
    if ($null -eq $State.EnableLUA) { 1 } else { $State.EnableLUA }
}

function Invoke-Main {
    $current = Get-UacState
    $hasBackup = Test-Path -Path $BackupFile

    if ($Mode -eq 'Restore') {
        if ($hasBackup) {
            $target = Read-Backup
        }
        else {
            Write-Warning 'No backup found; applying Windows defaults.'
            $target = $WindowsDefaults
        }
    }
    else {
        # Keep the very first snapshot so switching between modes never overwrites the original state.
        if (-not $hasBackup) { Save-Backup -State $current }
        $target = $ModeProfiles[$Mode]
    }

    Set-UacState -State $target

    if ($Mode -eq 'Restore' -and $hasBackup) {
        Remove-Item -Path $BackupFile -Force
        if (-not (Get-ChildItem -Path $BackupDir -Force)) { Remove-Item -Path $BackupDir -Force }
    }

    Write-Host "UAC mode '$Mode' applied:"
    Get-UacState | ForEach-Object { [pscustomobject] $_ } | Format-List | Out-Host

    $restartRequired = (Get-EffectiveLua $current) -ne (Get-EffectiveLua $target)
    if (-not $restartRequired) {
        Write-Host 'No restart required.'
    }
    elseif ($Restart) {
        & "$env:SystemRoot\System32\shutdown.exe" /r /t $RestartDelaySeconds `
            /c "Restarting to apply UAC mode '$Mode'. Run 'shutdown /a' to cancel."
        if ($LASTEXITCODE -ne 0) { throw "shutdown.exe failed with exit code $LASTEXITCODE." }
        Write-Host "Restart scheduled in $RestartDelaySeconds s. Run 'shutdown /a' to cancel."
    }
    else {
        Write-Warning 'Restart Windows for the change to take effect.'
    }
}

if (-not (Test-IsAdministrator)) {
    exit (Invoke-Elevated)
}

$exitCode = 0
try {
    Invoke-Main
}
catch {
    Write-Error -ErrorRecord $_ -ErrorAction Continue
    $exitCode = 1
}
finally {
    if ($PauseOnExit) { Read-Host 'Press Enter to close' | Out-Null }
}
exit $exitCode
