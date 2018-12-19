<#
.SYNOPSIS
   This is a function to disconect from the VNX
.DESCRIPTION
    This function will disconnect from the VNX defined in the global
    $CurrentVnxFrame variable.  It will use the authentication session
    and Name stored in that variable
.EXAMPLE
   PS > .\Disconnect-Vnx
#>
function Disconnect-Vnx {
    BEGIN {
        If (!$CurrentVnxFrame) {
            Write-Host -ForegroundColor Yellow "No VNX is currently connected."
            Exit 1
        }
        # This header is used to actually tell the API server
        # to gracefully disconnect the session
        $headers = @{"CelerraConnector-Ctl" = "DISCONNECT"}
        # URL to hit for queries
        $apiuri = "https://$($CurrentVnxFrame.Hostname)/servlets/CelerraManagementServices"
        # Standard "top" of XML Sheet
        $xmltop = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        # Standard format of XML Shee
        # Can specify the API version herel, but letting the system default to
        # its version so this will work on Celerra (hopefully) and VNX
        $xmlformat = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api" >'
        # Standard beginning of a query
        $qrybegin = '<Request><Query>'
        # Line specifying the parameters we're querying
        $qryend= '</Query></Request>'
        # Standard Footer for XML Sheet
        $xmlfooter = '</RequestPacket>'
        # Adding all the pieces together
        $body = $xmltop + $xmlformat + $qrybegin + $qryend + $xmlfooter
    }
    PROCESS {
        $response = Invoke-Webrequest -Uri $apiuri -WebSession $CurrentVnxFrame.Session -Headers $headers -Body $body -Method Post
        $out = [pscustomobject]@{
            HostName = $CurrentVnxFrame.Hostname
            SystemName = $CurrentVnxFrame.SystemName;
            Status = $response.statusdescription;
            StatusCode = $response.StatusCode;
            Session = $response.headers.'CelerraConnector-Sess';
            DisconnectDate = $response.headers.date
        }
        If ($out.StatusCode -eq 200) {
            Remove-Variable -Name CurrentVnxFrame -Scope Global
        }
        Else {
            Write-Host -ForegroundColor Yellow "Unexpected exit code.  Expected status code 200, but received:"
            Write-Host -ForegroundColor Yellow "$($response.StatusCode): $($response.Status)"
            Exit
        }
    }
    END {
        $out
    }
}
Disconnect-Vnx
