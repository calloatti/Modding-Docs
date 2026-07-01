# Define the exact path to your SteamCMD executable
$steamCmdPath = "C:\Users\calloatti\Documents\Timberborn\Mods.Modding\steamcmd\steamcmd.exe"

# Prompt the user for their Steam username
$steamUser = Read-Host "Enter your Steam Username (not your display name)"

# Update Normal Branch
Write-Host "Updating Normal Branch..." -ForegroundColor Cyan
Start-Process -FilePath $steamCmdPath -ArgumentList "+force_install_dir `"C:\Program Files (x86)\Steam\steamapps\common\Timberborn_Main`" +login $steamUser +app_update 1062090 validate +quit" -Wait

# Update Experimental Branch
Write-Host "Updating Experimental Branch..." -ForegroundColor Cyan
Start-Process -FilePath $steamCmdPath -ArgumentList "+force_install_dir `"C:\Program Files (x86)\Steam\steamapps\common\Timberborn_Experimental`" +login $steamUser +app_update 1062090 -beta experimental validate +quit" -Wait

Write-Host "Updates complete!" -ForegroundColor Green