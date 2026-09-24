#Requires -Version 5.1

<#
.SYNOPSIS
    Richtet die Windows-Seite von Elias' Entwicklungsumgebung ein: WSL 2 mit Ubuntu 24.04,
    Windows Terminal, Visual Studio Code, PowerShell 7, optional Docker Desktop, die
    Claude-Desktop-App und die ChatGPT-App sowie die VS-Code-Extensions auf der Windows-Seite.

.DESCRIPTION
    Teil des dotfiles-Repos https://github.com/Elias-Martinelli/dotfiles (Datei windows/setup.ps1).

    AUSFUeHREN IN POWERSHELL ALS ADMINISTRATOR
    (Windows-Taste druecken, "PowerShell" tippen, Rechtsklick -> "Als Administrator ausfuehren"):

        Set-ExecutionPolicy -Scope Process Bypass; .\setup.ps1

    Oder als Einzeiler ohne vorherigen Download (funktioniert nur, wenn das Repo oeffentlich ist;
    Parameter lassen sich auf diesem Weg nicht uebergeben):

        irm https://raw.githubusercontent.com/Elias-Martinelli/dotfiles/main/windows/setup.ps1 | iex

    Das Skript ist idempotent: Was schon vorhanden ist, wird uebersprungen. Du kannst es also
    jederzeit erneut ausfuehren - zum Beispiel nach dem Neustart, den eine frische
    WSL-Installation verlangt.

    Ablauf (6 Schritte):
      1. Vorpruefungen: Administratorrechte, Windows-Version, winget
      2. WSL 2 installieren bzw. aktualisieren, Ubuntu-24.04 installieren (ohne ersten Start)
      3. Programme per winget: Windows Terminal, VS Code, PowerShell 7, optional Docker Desktop
      4. KI-Apps per winget: Claude (Anthropic) und ChatGPT (OpenAI, aus dem Microsoft Store)
      5. VS-Code-Extensions auf der Windows-Seite: WSL, Claude Code, Codex/ChatGPT
      6. .wslconfig anlegen (RAM/CPU fuer die WSL-VM), danach Zusammenfassung und naechste Schritte

    Alles, was IN Ubuntu passiert (zsh, Python, Claude Code CLI, ...), uebernimmt anschliessend
    install.sh aus demselben Repo - siehe docs/02-installation.md.

.PARAMETER SkipDocker
    Docker Desktop nicht installieren.

.PARAMETER SkipClaudeApp
    Die Claude-Desktop-App (winget-ID Anthropic.Claude) nicht installieren. Die VS-Code-Extension
    "Claude Code" wird trotzdem installiert; das Claude-Code-CLI installiert install.sh in Ubuntu.

.PARAMETER SkipChatGPT
    Die ChatGPT-App und die VS-Code-Extension openai.chatgpt (Codex) nicht installieren.

.PARAMETER SkipWsl
    WSL nicht anfassen: weder installieren/aktualisieren noch Ubuntu-24.04 oder .wslconfig anlegen.

.PARAMETER DryRun
    Nur anzeigen, was passieren wuerde ("[dry-run] befehl ..."); nichts installieren, nichts schreiben.
    Funktioniert auch ohne Administratorrechte.

.EXAMPLE
    .\setup.ps1
    Vollstaendige Einrichtung.

.EXAMPLE
    .\setup.ps1 -SkipDocker -SkipChatGPT
    Ohne Docker Desktop und ohne ChatGPT.

.EXAMPLE
    .\setup.ps1 -DryRun
    Zeigt nur, was das Skript tun wuerde.

.NOTES
    Getestet mit Windows 11, Windows PowerShell 5.1 und PowerShell 7.
    Die Datei ist bewusst reines ASCII (ae/oe/ue statt Umlaute) und OHNE BOM gespeichert:
    Windows PowerShell 5.1 liest BOM-lose Dateien als ANSI (Umlaute kaemen kaputt an), und ein
    BOM wuerde den Einzeiler "irm ... | iex" brechen, weil irm das BOM als Zeichen an den Parser
    weiterreicht. Beim Bearbeiten bitte keine Umlaute einbauen.
    Alle winget-IDs wurden am 2026-09-23 mit "winget search --id <ID> -e" geprueft.
#>
[CmdletBinding()]
param(
    [switch]$SkipDocker,
    [switch]$SkipClaudeApp,
    [switch]$SkipChatGPT,
    [switch]$SkipWsl,
    [switch]$DryRun
)

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'

# Ordner, in dem dieses Skript liegt (leer, wenn es per "irm ... | iex" gestartet wurde).
$ScriptDir = $PSScriptRoot

$RepoUrl = 'https://github.com/Elias-Martinelli/dotfiles'
$RepoRawBase = 'https://raw.githubusercontent.com/Elias-Martinelli/dotfiles/main'

# Name der Distribution, wie ihn "wsl --list --online" ausgibt.
$UbuntuDistro = 'Ubuntu-24.04'

# WSL 2 braucht Windows 10 Version 2004 (Build 19041) oder Windows 11.
# Quelle: https://learn.microsoft.com/windows/wsl/install
$MinWindowsBuild = 19041

# winget-Pakete. Alle IDs geprueft mit "winget search --id <ID> -e" (Stand 2026-09-23).
$BasePackages = @(
    @{ Id = 'Microsoft.WindowsTerminal';  Name = 'Windows Terminal' },
    @{ Id = 'Microsoft.VisualStudioCode'; Name = 'Visual Studio Code' },
    # PowerShell 7: "winget list -e --id" erkennt eine bestehende Installation nicht immer -> zusaetzlich pwsh.exe pruefen.
    @{ Id = 'Microsoft.PowerShell';       Name = 'PowerShell 7'; Command = 'pwsh.exe' }
)
$DockerPackage = @{ Id = 'Docker.DockerDesktop'; Name = 'Docker Desktop' }
$ClaudePackage = @{ Id = 'Anthropic.Claude'; Name = 'Claude (Desktop-App)' }
# ChatGPT gibt es offiziell nur im Microsoft Store (Herausgeber: OpenAI). winget spricht den Store
# ueber die Quelle "msstore" an; die Store-Produkt-ID ist 9PLM9XGG6VKS.
$ChatGptPackage = @{ Id = '9PLM9XGG6VKS'; Name = 'ChatGPT (Microsoft Store)'; Source = 'msstore' }

# "App Installer" liefert winget mit; Store-Produkt-ID 9NBLGGH4NNS1 (Herausgeber: Microsoft Corporation).
$AppInstallerStoreUrl = 'ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1'

# VS-Code-Extensions auf der WINDOWS-Seite. Die Extensions auf der WSL-Seite installiert
# install.sh aus packages/vscode-extensions.txt.
$WindowsExtensions = @(
    @{ Id = 'ms-vscode-remote.remote-wsl'; Name = 'WSL' },
    @{ Id = 'anthropic.claude-code';       Name = 'Claude Code' },
    @{ Id = 'openai.chatgpt';              Name = 'Codex (ChatGPT)'; IsChatGpt = $true }
)

# Laufzeit-Zustand
$script:NeedsRestart = $false
$script:FailureCount = 0
$script:Summary = New-Object System.Collections.Generic.List[string]
$script:LastExitCode = 0

# ---------------------------------------------------------------------------
# Ausgabe-Helfer
# ---------------------------------------------------------------------------
function Write-Step {
    param([string]$Text)
    Write-Host ''
    Write-Host "==== $Text ====" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Text)
    Write-Host "==> $Text"
}

function Write-Ok {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "[WARNUNG] $Text" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Text)
    Write-Host "[FEHLER] $Text" -ForegroundColor Red
}

function Write-Skip {
    param([string]$Text)
    Write-Host "[--] $Text - uebersprungen (bereits vorhanden)" -ForegroundColor DarkGray
}

function Write-DryRun {
    param([string]$Text)
    Write-Host "[dry-run] $Text" -ForegroundColor Magenta
}

function Write-Hint {
    param([string]$Text)
    Write-Host "     $Text" -ForegroundColor DarkGray
}

function Add-Summary {
    param([string]$Text)
    $script:Summary.Add($Text)
}

# ---------------------------------------------------------------------------
# Befehls-Helfer
# ---------------------------------------------------------------------------
function Invoke-Native {
    <#
        Fuehrt ein externes Programm NUR LESEND aus (Pruefungen wie "winget list" oder "wsl --list"),
        faengt stdout und stderr ein und liefert bereinigte Zeilen zurueck. Den Exit-Code legt es in
        $script:LastExitCode ab.
        Encoding-Fallstrick: wsl.exe gibt je nach Version UTF-16 aus, was in PowerShell als Text mit
        Nullbytes ankommt ("U\0b\0u\0..."). Deshalb werden Nullbytes entfernt, bevor verglichen wird.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$ArgumentList = @()
    )
    $ErrorActionPreference = 'Continue'
    $raw = & $FilePath @ArgumentList 2>&1
    $script:LastExitCode = $LASTEXITCODE
    $lines = @()
    foreach ($item in @($raw)) {
        $text = ("$item" -replace "\0", '').Trim()
        if ($text -ne '') {
            $lines += $text
        }
    }
    return $lines
}

function Invoke-Action {
    <#
        Fuehrt eine VERAeNDERNDE Aktion aus (installieren, aktualisieren). Bei -DryRun wird der Befehl
        nur angezeigt. Liefert $true bei Exit-Code 0, sonst $false (und zaehlt den Fehler).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$ArgumentList = @()
    )
    $commandLine = (@($FilePath) + $ArgumentList) -join ' '
    if ($DryRun) {
        Write-DryRun $commandLine
        return $true
    }
    Write-Info $Description
    Write-Host "     > $commandLine" -ForegroundColor DarkGray
    $ErrorActionPreference = 'Continue'
    & $FilePath @ArgumentList
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        Write-Fail "'$commandLine' endete mit Exit-Code $code."
        $script:FailureCount++
        return $false
    }
    return $true
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-WingetPackage {
    # $true, wenn winget das Paket als installiert kennt (Exit-Code 0 bei "winget list -e --id").
    param([Parameter(Mandatory = $true)][string]$Id)
    $null = Invoke-Native -FilePath 'winget' -ArgumentList @('list', '-e', '--id', $Id, '--accept-source-agreements')
    return ($script:LastExitCode -eq 0)
}

function Install-WingetPackage {
    <#
        Installiert ein winget-Paket idempotent. Rueckgabe: 'vorhanden', 'installiert', 'dry-run' oder 'fehler'.
    #>
    param([Parameter(Mandatory = $true)][hashtable]$Package)
    $label = "$($Package.Name) [$($Package.Id)]"
    if ($Package.ContainsKey('Command') -and (Get-Command $Package.Command -ErrorAction SilentlyContinue)) {
        Write-Skip $label
        Add-Summary "$($Package.Name): bereits vorhanden"
        return 'vorhanden'
    }
    if (Test-WingetPackage -Id $Package.Id) {
        Write-Skip $label
        Add-Summary "$($Package.Name): bereits vorhanden"
        return 'vorhanden'
    }
    $wingetArgs = @('install', '-e', '--id', $Package.Id, '--accept-package-agreements', '--accept-source-agreements')
    if ($Package.ContainsKey('Source')) {
        $wingetArgs += @('-s', $Package.Source)
    }
    if (Invoke-Action -Description "$label installieren" -FilePath 'winget' -ArgumentList $wingetArgs) {
        if ($DryRun) {
            Add-Summary "$($Package.Name): wuerde installiert"
            return 'dry-run'
        }
        Write-Ok "$($Package.Name) installiert."
        Add-Summary "$($Package.Name): installiert"
        return 'installiert'
    }
    Add-Summary "$($Package.Name): FEHLER - manuell nachholen: winget install -e --id $($Package.Id)"
    if ($Package.ContainsKey('Source') -and $Package.Source -eq 'msstore') {
        Write-Warn "Alternative: Microsoft Store oeffnen und '$($Package.Name)' von dort installieren: ms-windows-store://pdp/?ProductId=$($Package.Id)"
    }
    return 'fehler'
}

function Test-WslInstalled {
    # $true, wenn wsl.exe vorhanden ist und "wsl --status" ohne Fehler antwortet.
    if (-not (Get-Command 'wsl.exe' -ErrorAction SilentlyContinue)) {
        return $false
    }
    $null = Invoke-Native -FilePath 'wsl.exe' -ArgumentList @('--status')
    return ($script:LastExitCode -eq 0)
}

function Get-WslDistributions {
    # Namen der installierten Distributionen (leer, wenn keine vorhanden ist).
    $lines = @(Invoke-Native -FilePath 'wsl.exe' -ArgumentList @('--list', '--quiet'))
    if ($script:LastExitCode -ne 0) {
        return @()
    }
    return $lines
}

function Get-CodeCommand {
    # Pfad zu code.cmd. Erst PATH neu einlesen: winget hat VS Code eventuell gerade erst installiert,
    # die laufende Shell kennt den neuen Pfad aber noch nicht.
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    $command = Get-Command 'code.cmd' -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    # Standardpfade der Benutzer- und der Systeminstallation von VS Code.
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }
    return $null
}

function Get-WslConfigTemplate {
    # Vorlage windows/wslconfig.example: lokal neben dem Skript, sonst aus dem Repo, sonst eingebaut.
    if ($ScriptDir) {
        $localPath = Join-Path $ScriptDir 'wslconfig.example'
        if (Test-Path -LiteralPath $localPath) {
            Write-Info "Vorlage: $localPath"
            return (Get-Content -LiteralPath $localPath -Raw -Encoding UTF8)
        }
    }
    $url = "$RepoRawBase/windows/wslconfig.example"
    try {
        Write-Info "Vorlage wird geladen: $url"
        return (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    } catch {
        Write-Warn "Vorlage konnte nicht geladen werden ($($_.Exception.Message)). Verwende die eingebaute Minimalvorlage."
    }
    return @"
# Erzeugt von windows/setup.ps1 (eingebaute Minimalvorlage).
# Referenz: https://learn.microsoft.com/windows/wsl/wsl-config
[wsl2]
memory=__MEMORY__GB
processors=__PROCESSORS__
swap=8GB
"@
}

# ---------------------------------------------------------------------------
# Schritte
# ---------------------------------------------------------------------------
function Invoke-StepChecks {
    Write-Step '1/6 Vorpruefungen'

    if (Test-IsAdministrator) {
        Write-Ok 'PowerShell laeuft mit Administratorrechten.'
    } elseif ($DryRun) {
        Write-Warn 'Keine Administratorrechte - fuer -DryRun in Ordnung, fuer die echte Installation noetig.'
    } else {
        Write-Fail 'Dieses Skript braucht Administratorrechte.'
        Write-Hint 'Windows-Taste druecken, "PowerShell" tippen, Rechtsklick -> "Als Administrator ausfuehren", dann erneut starten.'
        throw 'Keine Administratorrechte.'
    }

    $build = [Environment]::OSVersion.Version.Build
    if ($build -lt $MinWindowsBuild) {
        Write-Fail "Windows-Build $build ist zu alt. WSL 2 braucht Windows 10 Version 2004 (Build $MinWindowsBuild) oder Windows 11."
        throw 'Windows-Version zu alt.'
    }
    Write-Ok "Windows-Build $build erkannt."

    if (Get-Command 'winget' -ErrorAction SilentlyContinue) {
        $version = @(Invoke-Native -FilePath 'winget' -ArgumentList @('--version')) | Select-Object -First 1
        Write-Ok "winget vorhanden ($version)."
    } else {
        Write-Fail 'winget (Windows-Paketmanager) fehlt.'
        Write-Hint "Installiere 'App Installer' aus dem Microsoft Store: $AppInstallerStoreUrl"
        Write-Hint 'oder fuehre Windows Update aus. Danach dieses Skript erneut starten.'
        throw 'winget fehlt.'
    }

    if ($DryRun) {
        Write-Info 'DryRun aktiv: Es wird nichts installiert und nichts geschrieben.'
    }
}

function Invoke-StepWsl {
    Write-Step "2/6 WSL 2 und $UbuntuDistro"
    if ($SkipWsl) {
        Write-Info 'Uebersprungen (-SkipWsl).'
        Add-Summary 'WSL: uebersprungen (-SkipWsl)'
        return
    }

    $wslWasInstalled = Test-WslInstalled
    if ($wslWasInstalled) {
        Write-Skip 'WSL'
        if (Invoke-Action -Description 'WSL auf die neueste Version aktualisieren' -FilePath 'wsl.exe' -ArgumentList @('--update')) {
            if (-not $DryRun) {
                Write-Ok 'WSL ist aktuell.'
            }
        } else {
            Write-Warn 'wsl --update ist fehlgeschlagen (kein Internet oder Store gesperrt?). Spaeter manuell: wsl --update'
        }
        Add-Summary 'WSL: bereits vorhanden (Update geprueft)'
    } else {
        Write-Info 'WSL ist noch nicht installiert.'
        if (Invoke-Action -Description 'WSL 2 installieren (ohne Distribution)' -FilePath 'wsl.exe' -ArgumentList @('--install', '--no-distribution')) {
            $script:NeedsRestart = $true
            if (-not $DryRun) {
                Write-Ok 'WSL installiert. Windows muss danach neu gestartet werden.'
            }
            Add-Summary 'WSL: installiert (Neustart noetig)'
        } else {
            Add-Summary 'WSL: FEHLER bei der Installation'
            Write-Warn 'Pruefe, ob die Virtualisierung im BIOS/UEFI aktiviert ist (Task-Manager -> Leistung -> CPU -> "Virtualisierung: Aktiviert").'
            return
        }
    }

    $distros = @()
    if ($wslWasInstalled) {
        $distros = @(Get-WslDistributions)
    }
    $otherUbuntu = @($distros | Where-Object { $_ -like 'Ubuntu*' -and $_ -ne $UbuntuDistro })

    if ($distros -contains $UbuntuDistro) {
        Write-Skip $UbuntuDistro
        Add-Summary "${UbuntuDistro}: bereits vorhanden"
    } elseif ($otherUbuntu.Count -gt 0) {
        Write-Warn "Es ist bereits eine Ubuntu-Distribution vorhanden: $($otherUbuntu -join ', '). Ich installiere keine zweite."
        Write-Hint "Falls du zusaetzlich $UbuntuDistro willst: wsl --install -d $UbuntuDistro --no-launch"
        Add-Summary "${UbuntuDistro}: uebersprungen, vorhanden ist $($otherUbuntu -join ', ')"
    } elseif ($script:NeedsRestart -and -not $DryRun) {
        # Direkt nach der WSL-Installation klappt das erst nach einem Neustart.
        Write-Info "$UbuntuDistro wird nach dem Neustart installiert: Windows neu starten und dieses Skript erneut ausfuehren."
        Add-Summary "${UbuntuDistro}: nach dem Neustart (Skript erneut ausfuehren)"
    } else {
        if (Invoke-Action -Description "$UbuntuDistro installieren (ohne ersten Start)" -FilePath 'wsl.exe' -ArgumentList @('--install', '-d', $UbuntuDistro, '--no-launch')) {
            if (-not $DryRun) {
                Write-Ok "$UbuntuDistro installiert. Der erste Start (Benutzer anlegen) folgt bei den naechsten Schritten."
            }
            Add-Summary "${UbuntuDistro}: installiert"
        } else {
            Add-Summary "${UbuntuDistro}: FEHLER - nach dem Neustart erneut: wsl --install -d $UbuntuDistro --no-launch"
            if ($script:NeedsRestart) {
                Write-Warn 'Direkt nach einer frischen WSL-Installation ist das normal: Windows neu starten und dieses Skript erneut ausfuehren.'
            }
        }
    }
}

function Invoke-StepPrograms {
    Write-Step '3/6 Programme per winget'
    foreach ($package in $BasePackages) {
        $null = Install-WingetPackage -Package $package
    }
    if ($SkipDocker) {
        Write-Info 'Docker Desktop uebersprungen (-SkipDocker).'
        Add-Summary 'Docker Desktop: uebersprungen (-SkipDocker)'
    } else {
        $result = Install-WingetPackage -Package $DockerPackage
        if ($result -ne 'vorhanden') {
            Write-Hint 'Nach dem ersten Start von Docker Desktop: Settings -> Resources -> WSL integration -> Ubuntu aktivieren.'
        }
    }
}

function Invoke-StepAiApps {
    Write-Step '4/6 KI-Apps: Claude und ChatGPT'
    if ($SkipClaudeApp) {
        Write-Info 'Claude-Desktop-App uebersprungen (-SkipClaudeApp).'
        Add-Summary 'Claude (Desktop-App): uebersprungen (-SkipClaudeApp)'
    } else {
        $null = Install-WingetPackage -Package $ClaudePackage
        Write-Hint 'Das Claude-Code-CLI fuer das Terminal installiert install.sh in Ubuntu (nicht hier).'
    }
    if ($SkipChatGPT) {
        Write-Info 'ChatGPT uebersprungen (-SkipChatGPT).'
        Add-Summary 'ChatGPT: uebersprungen (-SkipChatGPT)'
    } else {
        $null = Install-WingetPackage -Package $ChatGptPackage
    }
}

function Invoke-StepExtensions {
    Write-Step '5/6 VS-Code-Extensions (Windows-Seite)'
    $codeCmd = Get-CodeCommand
    if (-not $codeCmd) {
        Write-Warn 'code.cmd nicht gefunden. VS Code wurde eventuell gerade erst installiert.'
        Write-Hint 'Neues PowerShell-Fenster (als Administrator) oeffnen und dieses Skript erneut ausfuehren, oder manuell:'
        foreach ($extension in $WindowsExtensions) {
            Write-Hint "code --install-extension $($extension.Id)"
        }
        Add-Summary 'VS-Code-Extensions: uebersprungen (code.cmd nicht gefunden)'
        return
    }
    Write-Info "VS Code gefunden: $codeCmd"
    $installed = @(Invoke-Native -FilePath $codeCmd -ArgumentList @('--list-extensions'))
    foreach ($extension in $WindowsExtensions) {
        if ($extension.ContainsKey('IsChatGpt') -and $SkipChatGPT) {
            Write-Info "Extension $($extension.Id) uebersprungen (-SkipChatGPT)."
            continue
        }
        $label = "Extension $($extension.Name) [$($extension.Id)]"
        if ($installed -contains $extension.Id) {
            Write-Skip $label
            Add-Summary "Extension $($extension.Id): bereits vorhanden"
            continue
        }
        if (Invoke-Action -Description "$label installieren" -FilePath $codeCmd -ArgumentList @('--install-extension', $extension.Id, '--force')) {
            if ($DryRun) {
                Add-Summary "Extension $($extension.Id): wuerde installiert"
            } else {
                Write-Ok "Extension $($extension.Id) installiert."
                Add-Summary "Extension $($extension.Id): installiert"
            }
        } else {
            Add-Summary "Extension $($extension.Id): FEHLER - manuell: code --install-extension $($extension.Id)"
        }
    }
}

function Invoke-StepWslConfig {
    Write-Step '6/6 .wslconfig (Ressourcen der WSL-VM)'
    if ($SkipWsl) {
        Write-Info 'Uebersprungen (-SkipWsl).'
        return
    }
    $target = Join-Path $env:USERPROFILE '.wslconfig'
    if (Test-Path -LiteralPath $target) {
        Write-Skip ".wslconfig ($target)"
        Add-Summary '.wslconfig: bereits vorhanden'
        return
    }

    try {
        $system = Get-CimInstance -ClassName Win32_ComputerSystem
        $totalGb = [math]::Round($system.TotalPhysicalMemory / 1GB)
        $logical = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
        if (-not $logical) {
            $logical = $system.NumberOfLogicalProcessors
        }
    } catch {
        Write-Warn "Hardware konnte nicht abgefragt werden ($($_.Exception.Message))."
        Write-Hint "Lege $target manuell an - Vorlage: windows/wslconfig.example im Repo."
        Add-Summary '.wslconfig: uebersprungen (Hardware-Abfrage fehlgeschlagen)'
        return
    }
    # Haelfte des RAM (auf ganze GB gerundet) und Haelfte der logischen Kerne, mindestens 2.
    $memoryGb = [int][math]::Max(2, [math]::Round($totalGb / 2))
    $processors = [int][math]::Max(2, [math]::Floor($logical / 2))
    Write-Info "Erkannt: $totalGb GB RAM, $logical logische Prozessoren -> memory=${memoryGb}GB, processors=$processors, swap=8GB"

    # Nur die Schluessel-Zeilen ersetzen, nicht die Erklaerungen der Platzhalter im Kopfkommentar.
    $content = (Get-WslConfigTemplate).Replace('memory=__MEMORY__GB', "memory=${memoryGb}GB").Replace('processors=__PROCESSORS__', "processors=$processors")
    # Windows-Zeilenenden, damit die Datei in Notepad sauber aussieht.
    $content = ($content -replace "`r?`n", "`r`n")

    if ($DryRun) {
        Write-DryRun ".wslconfig schreiben nach $target"
        Add-Summary ".wslconfig: wuerde angelegt (memory=${memoryGb}GB, processors=$processors)"
        return
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($target, $content, $utf8NoBom)
    Write-Ok ".wslconfig angelegt: $target"
    Write-Hint 'Gilt ab dem naechsten Start von WSL (vorher in PowerShell: wsl --shutdown).'
    Add-Summary ".wslconfig: angelegt (memory=${memoryGb}GB, processors=$processors)"
}

function Show-Summary {
    Write-Host ''
    Write-Host '==== Zusammenfassung ====' -ForegroundColor Cyan
    foreach ($line in $script:Summary) {
        Write-Host " - $line"
    }
    if ($script:FailureCount -gt 0) {
        Write-Warn "$($script:FailureCount) Aktion(en) sind fehlgeschlagen - siehe oben. Das Skript kann gefahrlos erneut ausgefuehrt werden."
    }
    if ($script:NeedsRestart) {
        Write-Host ''
        Write-Host '>>> NEUSTART ERFORDERLICH: WSL wurde neu installiert. Bitte Windows jetzt neu starten' -ForegroundColor Yellow
        Write-Host '>>> und dieses Skript danach noch einmal ausfuehren (es ueberspringt alles, was schon da ist).' -ForegroundColor Yellow
    }

    Write-Host ''
    Write-Host '==== Naechste Schritte ====' -ForegroundColor Cyan
    Write-Host ' 1. Falls oben ein Neustart verlangt wird: Windows neu starten und dieses Skript erneut ausfuehren.'
    Write-Host " 2. Ubuntu zum ersten Mal starten: Startmenue -> 'Ubuntu 24.04 LTS' (oder in PowerShell: wsl -d $UbuntuDistro)."
    Write-Host '    Beim ersten Start einen Linux-Benutzernamen (Kleinbuchstaben, ohne Leerzeichen) und ein Passwort festlegen.'
    Write-Host '    Das Passwort wird beim Tippen NICHT angezeigt - das ist normal.'
    Write-Host ' 3. Windows Terminal oeffnen und Ubuntu als Standardprofil waehlen (Einstellungen -> Start -> Standardprofil).'
    Write-Host ' 4. In Ubuntu die dotfiles installieren (Details: docs/02-installation.md im Repo):'
    Write-Host '    Weg A (Elias, Repo privat; gh fehlt auf frischem Ubuntu und kommt aus den Ubuntu-Paketquellen):'
    Write-Host '      sudo apt-get update && sudo apt-get install -y git gh'
    Write-Host '      gh auth login'
    Write-Host '      gh repo clone Elias-Martinelli/dotfiles ~/code/Elias-Martinelli/dotfiles'
    Write-Host '      cd ~/code/Elias-Martinelli/dotfiles && ./install.sh'
    Write-Host '    Weg B (Einsteiger, funktioniert nur bei oeffentlichem Repo):'
    Write-Host "      bash <(curl -fsSL $RepoRawBase/bootstrap.sh)"
    Write-Host ' 5. Docker Desktop (falls installiert) einmal starten: Settings -> Resources -> WSL integration -> Ubuntu aktivieren.'
    Write-Host ' 6. Claude-App und ChatGPT-App starten und anmelden. Das Claude-Code-CLI richtet install.sh in Ubuntu ein.'
    Write-Host ''
}

function Invoke-Main {
    Write-Host ''
    Write-Host 'dotfiles / windows/setup.ps1 - Windows-Seite der Entwicklungsumgebung einrichten' -ForegroundColor Cyan
    Write-Host "Repo: $RepoUrl"
    if ($DryRun) {
        Write-Host 'Modus: DryRun (nur anzeigen, nichts veraendern)' -ForegroundColor Magenta
    }
    Invoke-StepChecks
    Invoke-StepWsl
    Invoke-StepPrograms
    Invoke-StepAiApps
    Invoke-StepExtensions
    Invoke-StepWslConfig
    Show-Summary
}

# ---------------------------------------------------------------------------
# Start
# ---------------------------------------------------------------------------
try {
    Invoke-Main
} catch {
    Write-Fail "Abbruch: $($_.Exception.Message)"
    # Als Datei gestartet: mit Exit-Code 1 beenden. Per "irm | iex" gestartet: die Sitzung offen lassen.
    if ($MyInvocation.MyCommand.Path) {
        exit 1
    }
}
