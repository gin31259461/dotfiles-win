Set-ExecutionPolicy Remotesigned -Scope CurrentUser -Force | Out-Null

# -------------------- util start --------------------
function Push-EnvironmentVariables
{
  # Get all machine and user environment variables and set them in the current process
  $machineEnv = [System.Environment]::GetEnvironmentVariables("Machine")
  $userEnv = [System.Environment]::GetEnvironmentVariables("User")
    
  # Merge and update current process
  $machineEnv.GetEnumerator() | ForEach-Object {
    [System.Environment]::SetEnvironmentVariable($_.Key, $_.Value, "Process")
  }
  $userEnv.GetEnumerator() | ForEach-Object {
    [System.Environment]::SetEnvironmentVariable($_.Key, $_.Value, "Process")
  }
}

function Add-ScoopAppToContextMenu
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$AppName, 
    [string]$MenuText,   
    [string]$CommandName,
    [string]$CommandFlag
  )

  if (-not $MenuText)
  {
    $MenuText = "Open with $AppName"
  }

  $appPath = scoop prefix $AppName 2>$null
  if (-not $appPath)
  {
    Write-Host "Can't find Scoop app: $AppName"
    return
  }

  $exePath = ""

  if ($CommandName)
  {
    $exePath = "$appPath\$CommandName"
  } else
  {
    $exeObject = Get-ChildItem "$appPath" -Filter "*.exe" -File -Recurse | Select-Object -First 1
    $exePath = $exeObject.FullName
  }

  if (-not (Test-Path $exePath))
  {
    Write-Host "Can't find exe in $exePath"
    return
  }

  $key = "HKCU:\Software\Classes\Directory\background\shell\$AppName"
  $cmd = "$key\command"

  New-Item -Path $key -Force | Out-Null
  Set-ItemProperty -Path $key -Name '(default)' -Value $MenuText
  Set-ItemProperty -Path $key -Name 'icon' -Value $exePath

  New-Item -Path $cmd -Force | Out-Null
  Set-ItemProperty -Path $cmd -Name '(default)' -Value "$exePath $CommandFlag"

  Write-Host "Done: $MenuText $exePath"
}

# -------------------- util end --------------------

# setup starship
if (-not (Test-Path $HOME/.starship))
{
  Write-Output "Copying PreConfig Files"
  Copy-Item -Path ./.starship -Destination $HOME/ -Recurse -Force
}


# setup powershell
if (-not (Test-Path $HOME/.pwsh))
{
  Write-Output "Copying PowerShell Profile"
  Copy-Item -Path ./.pwsh -Destination $HOME/ -Recurse -Force
  New-Item -Path $profile -Value $HOME/.pwsh/Microsoft.PowerShell_profile.ps1 -ItemType SymbolicLink -Force
}


# -------------------- install packages --------------------
# scoop
# PSReadLine
Write-Output "Installing Packages"

Write-Output "Check for PSReadLine"
if (-not (Get-Module -ListAvailable -Name PSReadLine))
{
  Install-Module PSReadLine -Force
}
Write-Output "Done"

# -------------------- install packages via scoop --------------------

Write-Output "Check for Scoop"
if (-not (Test-Path "$env:USERPROFILE\scoop"))
{
  Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  scoop bucket add extras
  scoop bucket add versions 
}
Write-Output "Done"

scoop list > scoop_list.txt

foreach($line in Get-Content scoop_pkgs.txt )
{
  Write-Output "Check for $line"
  if (
    (-not (Get-Content scoop_list.txt | Select-String -Pattern $line))
  )
  {
    scoop install $line
    scoop reset $line
  }
  Write-Output "Done"
}

Add-ScoopAppToContextMenu -AppName "wezterm-nightly" -CommandName "wezterm-gui.exe" -CommandFlag "start --cwd ."


# -------------------- install packages via winget --------------------

# install pwsh
winget install --id Microsoft.Powershell --source winget

winget list > winget_list.txt

Write-Output "Check for NodeJS"
if (-not (Get-Content winget_list.txt | Select-String -Pattern "NodeJS"))
{
  winget install --id OpenJS.NodeJS 
  Push-EnvironmentVariables
  npm install -g pnpm
}
Write-Output "Done"

foreach($line in Get-Content winget_pkgs.txt )
{
  $tokens = $line -split "\."
  $name = $tokens[-1]

  Write-Output "Check for $line"
  if (
    (-not (Get-Content winget_list.txt | Select-String -Pattern $line)) -and 
    (-not (Get-Content winget_list.txt | Select-String -Pattern $name))
  )
  {
    winget install --id $line
  }
  Write-Output "Done"
}

# -------------------- setup regs --------------------
# win10 right-click menu
# restore to win11 menu just delete reg
Write-Output "Setup Win10 Right-click Menu"
if (Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32")
{
  reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
  taskkill /f /im explorer.exe
  Start-Process explorer.exe
}
Write-Output "Done"
