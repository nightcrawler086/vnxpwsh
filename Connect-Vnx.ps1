<#
.SYNOPSIS
   This is a function to make then inital connection to the VNX
.DESCRIPTION
    This function makes a connection to the VNX API and returns a
    web session.  The web session can be used for subsequent queries
    or configurations.  The web session will be set into a global
    variable for subsequent query/set/modify cmdlets to use
.EXAMPLE
   PS C:\Users\bhall\git\vnxpwsh> .\Connect-Vnx.ps1 -Name 192.168.1.105
    Accepting control station certificate without validating...

    Name   Platform Serial         FileOE       Slot
    ----   -------- ------         ------       ----
    system VG2      BB000C294C5E4C 8.1.8-37119  0
#>
function Connect-Vnx {
    [CmdletBinding()]
    Param
    (
        # Specify the VNX to connect to.  Name or IP will work.
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$true,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$Name,
        # Specify the credential object
        # If none specified, we can promptre
        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$false,
         Position=1)]
         [ValidateNotNullOrEmpty()]
         [System.Management.Automation.PSCredential]$Credential
    )
    BEGIN {
        # This is to check if an IP has been given
        # We need to store the hostname in the global variable after the connection
        # if we can't resolve the IP, we'll leave the IP as the hostname for
        # subsequent operations.
        If ($Name -match "\b((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3} (25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b") {
            $hostname = ([system.net.dns]::GetHostByAddress("${Name}")).Hostname
            If ($hostname) {
                $Name = $hostname
            }  
        }
        ElseIf ($Name -match "[0-9]{3}.[0-9]{3}.[0-9]{3}.[0-9]{3}") {
            # Looks like someone is passing an invalid IP
            Write-Host -ForegroundColor Yellow "$Name is not a valid IP address"
            Exit
        }
        $ping = New-Object System.Net.NetworkInformation.Ping
        $online = $ping.send("$Name", 5000)
        If ($online.status -ne "Success") {
            Write-Host -ForegroundColor Red "Ping test failed with the following status:  $($online.status)"
            Exit
        }
        # This disables certificate checking, so the self-signed certs dont' stop us
        Write-Host -Foreground Yellow "Accepting control station certificate without validating..."
        [system.net.servicepointmanager]::Servercertificatevalidationcallback = {$true}
        If (!$Credential) {
            $Credential = Get-Credential -Message "Enter credentials for ${Name}"
        }
        # Below two lines are how we retrieve the plain text version
        # of username and password
        $user = $Credential.GetNetworkCredential().UserName
        $pass = $Credential.GetNetworkCredential().Password
        # Login URL
        $loginuri = "https://${Name}/Login"
        # Credentials provided in the body
        # They will be sent via an HTTPS connection so
        # encrypted in flight
        $body = "user=${user}&password=${pass}&Login=Login"
        # Content-Type header
        $headers = @{"Content-Type" = "x-www-form-urlencoded"}
        # URL to hit for queries
        $apiuri = "https://${Name}/servlets/CelerraManagementServices"
        # Standard "top" of XML Sheet
        $xmltop = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        # Standard format of XML Shee
        # Can specify the API version here, but letting the system default to
        # its version so this will work on Celerra (hopefully) and VNX
        $xmlformat = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api" >'
        # Standard beginning of a query
        $qrybegin = '<Request><Query>'
        # Line specifying the parameters we're querying
        $qry = "<CelerraSystemQueryParams/>"
        $qryend= '</Query></Request>'
        # Standard Footer for XML Sheet
        $xmlfooter = '</RequestPacket>'
        # Adding all the pieces together
        $request = $xmltop + $xmlformat + $qrybegin + $qry + $qryend + $xmlfooter
    }
    PROCESS { 
        try {
            $login = Invoke-WebRequest -Uri $loginuri -Method Post -Body $body -SessionVariable ws -ErrorVariable err
        }
        catch {
            Write-Host -ForegroundColor red "$err"
            Exit
        }
        If ($login.StatusCode -eq 200) {
            $response = Invoke-RestMethod -Uri $apiuri -WebSession $ws -Headers $headers -Body $request -Method Post
            $obj = [pscustomobject]@{
                HostName = $Name;
                SystemName = $response.responsepacket.response.CelerraSystem.type;
                Platform = $response.responsepacket.response.CelerraSystem.productName;
                Serial = $response.responsepacket.response.CelerraSystem.serial;
                FileOE = $response.responsepacket.response.CelerraSystem.version;
                Slot = $response.responsepacket.response.CelerraSystem.celerra;
                Session = $ws
            }
            Set-Variable -Name CurrentVnxFrame -Value $obj -Scope Global
        }
        Else {
            Write-Host -ForegroundColor Yellow "Expected a 200 Status code, but received $($login.statuscode)"
            Write-Host -ForegroundColor Yellow "RESPONSE END"
            Write-Host -ForegroundColor Yellow "---------------------------------------------------"
            $login.rawcontent
            Write-Host -ForegroundColor Yellow "---------------------------------------------------"
            Write-Host -ForegroundColor Yellow "RESPONSE END"
        }
    }
    END {
        $CurrentVnxFrame | Select-Object SystemName,Platform,Serial,FileOE,Slot | Format-Table
    }
}
Connect-Vnx
