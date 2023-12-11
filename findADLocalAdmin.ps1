
Clear-Host
$dc=$env:LOGONSERVER
$fqdn = $env:USERDNSDOMAIN
#egyedi logfájl készítése
$logFile = ((get-date).Ticks).ToString() + "_adminScriptPolicy.txt"


Write-Host @"
  ___  ____  ____  ____     __   ____  _  _  __  __ _            
 / __)(  __)(_  _)(_  _)   / _\ (    \( \/ )(  )(  ( \           
( (_ \ ) _)   )(    )(    /    \ ) D (/ \/ \ )( /    /           
 \___/(____) (__)  (__)   \_/\_/(____/\_)(_/(__)\_)__)           
 ____  ____   __  ____  __  __    ____    ____  ____   __   _  _ 
(  _ \(  _ \ /  \(  __)(  )(  )  (  __)  (  __)(  _ \ /  \ ( \/ )
 ) __/ )   /(  O )) _)  )( / (_/\ ) _)    ) _)  )   /(  O )/ \/ \
(__)  (__\_) \__/(__)  (__)\____/(____)  (__)  (__\_) \__/ \_)(_/
 ____   __   __    __  ___  _  _                                 
(  _ \ /  \ (  )  (  )/ __)( \/ )                                
 ) __/(  O )/ (_/\ )(( (__  )  /                                 
(__)   \__/ \____/(__)\___)(__/                                  

"@

Write-Host "[+] Start script this logon server: $dc" -ForegroundColor Yellow
Write-Host "[+] Userdomain is: $fqdn" -ForegroundColor Yellow
Write-Host ".... please wait to many minutes"

function GetOU {
    param(
        [string]$ID,
        [string]$Content,
        [string]$Directory
    )


    $ldap = "LDAP://DC=$dcHostName,DC=$dcEnd"


    $ous = (([adsi]$('LDAP:\\DC='+$dcHostName+',DC='+$dcEnd)),(([adsisearcher]’(objectcategory=organizationalunit)’)).findall()).Path | ForEach-Object {
        if(([ADSI]”$_”).gPlink){

            #Write-Host ([adsi]$_).gplink -BackgroundColor Yellow -ForegroundColor Black

            $a=((([ADSI]”$_”).gplink) -replace “[[;]” -split “]”);
 
            
            for($i=0;$i -lt $a.length;$i++){
                
                if($a[$i] -like "*$ID*"){
                    Write-Host “[+] " -ForegroundColor Yellow -NoNewline
                    $ouPath= ([ADSI]”$_”).Path
                    Write-Host "OU Path: $ouPath” -ForegroundColor Yellow
                    #Write-Host $a -ForegroundColor Yellow
                    #Write-Host $a[$i] -BackgroundColor Black
                    $policyPath = ([ADSI]($a[$i]).Substring(0,$a[$i].length-1)).Path
                    $policyName = ([ADSI]($a[$i]).Substring(0,$a[$i].length-1)).DisplayName

                    Write-Host “Policy Path[$i]:”$policyPath
                    Write-Host “Policy Name[$i]:”$policyName 
                   
                    Write-Host "`n`n"
                    "[directory] $Directory" | Out-File -Encoding default -Append -FilePath $logFile
                    "[ou path] $ouPath" | Out-File -Encoding default -Append -FilePath $logFile 
                    "[policy name] $policyName" | Out-File -Encoding default -Append -FilePath $logFile
                    "----------------SCRIPT---------------------" | Out-File -Encoding default -Append -FilePath $logFile
                    $Content | Out-File -Encoding default -Append -FilePath $logFile
                    "-------------------------------------------`n" | Out-File -Encoding default -Append -FilePath $logFile

                } 
            };
        }
    }#foreach


}

$dir = Get-ChildItem "$dc\sysvol\$fqdn" -Recurse -File -Include *.cmd,*.ps1,*.bat
foreach ($d in $dir) {
    Write-Host "`n"
    
    Write-Host "[+] found script file : $d " -ForegroundColor Green -BackgroundColor Black
    Write-Host ""

    $r = Select-String -Path $d.FullName -Pattern 'pass','net user' -SimpleMatch -Quiet
    # találat a pass vagy net user vagy add-user akkor kiíratjuk a scriptet
    if ($r) {
        
        Write-Host "-------------- SCRIPT CONTENT -------------------------------`n`n" -ForegroundColor Yellow
        Write-Host ((get-content $d.FullName) -join "`n") -ForegroundColor Gray
        $content = (get-content $d.FullName) -join "`n"
        Write-Host "-------------------------------------------------------------`n" -ForegroundColor Yellow
        $policeId = $d.FullName.Split('{')[1].split('}')[0]
        $policeId =  "{"+$policeId+"}"

        GetOU -ID $policeId -Content $content -Directory $d

        Write-Host "*************************************************************"
        Write-Host "*************************************************************"
        Write-Host "*************************************************************"
        
    }
}

Write-Host "[+] saving file this filename " -ForegroundColor Green -NoNewline
Write-Host "$logFile"










