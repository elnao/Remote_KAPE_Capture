###############################################################################################
#  Script Name:  Remote_KAPE_Capture
#  Programmer:   https://github.com/elnao/Remote_KAPE_Capture
#  Purpose:      Run Kape on a remote windows machine on the internal network.
#  Prerequisite: Run script as account that is admin on remote machine;
#                  Run from C:\elnao\Memory_Capture folder; Kape.zip (zipped kape files) 
#                  must be staged on the remote machine at C:\program files\elnao-files
###############################################################################################

# Speed up Copy-Item operations
$ProgressPreference = "SilentlyContinue"

# Create Timestamp and remote powershell session.
$KAPECaptureStartDate = (Get-Date -Format FileDateTimeUniversal)

# Ask for name of the computer that needs KAPE ran on it.
$input_computer = Read-Host -Prompt "Enter computer to run KAPE on"
write-host -ForegroundColor Magenta -BackgroundColor Yellow "KAPE will be run on" $input_computer

# Start logging script output.
# Set-PSDebug -Trace 1
Start-Transcript -path .\$KAPECaptureStartDate"-KAPE-LOG_FILE-"$input_computer".log"

# Get hashes of EXE and PS1 files in C:\elnao\Memory_Capture
write-host -ForegroundColor Magenta "- Get hashes of EXE and PS1 files in C:\elnao\Memory_Capture"
Get-FileHash *.exe, *.ps1 | Format-Table -AutoSize

# Create remote powershell session.
write-host -ForegroundColor Magenta -BackgroundColor Yellow $KAPECaptureStartDate "- Start Time"
$RemoteSession = new-pssession -computername $input_computer
$RemotePath1 = "C:\Program Files\elnao-Files"
$RemotePath2 = "C:\Program Files\elnao-Files\KAPE"
$LocalPath1 = "C:\elnao\Memory_Capture"

# Perform KAPE capture on remote machine.
# write-host -ForegroundColor Magenta "- KAPE capture being performed on" $input_computer
Invoke-Command -verbose -session $RemoteSession  -Scriptblock { CD "$using:RemotePath1";
                                                       write-host -ForegroundColor Magenta "- Expanding KAPE on" "$using:input_computer";
                                                       Expand-Archive -Path .\kape.zip;
                                                       CD "$using:RemotePath2";
                                                       Mkdir target-destination;
                                                       write-host -ForegroundColor Magenta "- Running KAPE on" "$using:input_computer";
                                                       .\kape.exe --tsource C: --tdest "C:\Program Files\elnao-Files\kape\target-destination\%m" --tflush --target !SANS_Triage --vhdx kape-image;
                                                       $KAPECaptureDoneDate = (Get-Date -Format FileDateTimeUniversal);
                                                       write-host -ForegroundColor Magenta -BackgroundColor Yellow $KAPECaptureDoneDate "- KAPE Capture Complete";
                                                        }

# Copy compressed KAPE image to requesting workstation.
write-host -ForegroundColor Magenta "- KAPE Image Being Sent to Requesting Workstation."
$RemotePath3 =  "C:\Program Files\elnao-Files\kape\target-destination\$input_computer\*.zip"
$RemotePath4 =  "C:\Program Files\elnao-Files\kape\target-destination\$input_computer\*.txt"

$RemotePath3 = $RemotePath3 -replace "`t|`n|`r",""
$RemotePath4 = $RemotePath4 -replace "`t|`n|`r",""

New-Item -Path $LocalPath1 -Name "$KAPECaptureStartDate-KAPE-IMAGE-$input_computer" -ItemType "directory"
$LocalPath2 =  "$LocalPath1\$KAPECaptureStartDate-KAPE-IMAGE-$input_computer"


copy-item -fromsession $RemoteSession -path $RemotePath3 -destination $LocalPath2
copy-item -fromsession $RemoteSession -path $RemotePath4 -destination $LocalPath2


# Delete KAPE directory from remote workstation.
write-host -ForegroundColor Magenta "- Delete KAPE directory from Remote Workstation."
Invoke-Command -verbose -session $RemoteSession  -Scriptblock { Get-ChildItem $using:RemotePath2 -Recurse | Remove-Item -Recurse -Force }


$KAPECaptureSendCompleteDate = (Get-Date -Format FileDateTimeUniversal)
write-host -ForegroundColor Magenta -BackgroundColor Yellow $KAPECaptureSendCompleteDate "- KAPE Capture Send Complete"

Stop-Transcript
