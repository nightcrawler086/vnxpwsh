<#
.SYNOPSIS
   This cmdlet is used to get a list of all filesystems on a VNX
.DESCRIPTION
   This cmdlet returns all existing filesystems on the VNX.  If querying
   for a specific filesytem, use Get-VnxFilesystem
.EXAMPLE
   PS > Get-VnxFilesystem
#>
function Get-VnxFileSystem
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$true,
         Position=1)]
         [ValidateNotNullOrEmpty()]
         $Name,

        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$true,
         Position=1)]
         [ValidateNotNullOrEmpty()]
         $Id

    )
    BEGIN {
        # Expecting a Global variable to be set called
        # CurrentVnxSystem which contains the existing
        # session.
        If (!$CurrentVnxFrame) {
            Write-Host -ForegroundColor Red "Not currently connected to a VNX System."
            Write-Host -ForegroundColor Red "Run Connect-VnxSystem first."
            Exit 1
        }
        # This is the query URL
        $apiuri = "https://$($CurrentVnxFrame.HostName)/servlets/CelerraManagementServices"
        #write-host $apiuri
        # Setting header
        $header = @{"Content-Type" = "x-www-form-urlencoded"}
        # Standard "top" of XML Sheet
        $xmltop = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        # Standard format of XML Sheet
        $xmlformat = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api" >'
        # Standard Footer for XML Sheet
        $xmlfooter = '</RequestPacket>'
        # Query for CIFS Shares for entire frame
        $qryopen = '<Request><Query>'
        $qrybegin = "<FileSystemQueryParams> <AspectSelection fileSystems=""true"" fileSystemCapacityInfos=""true"" />"  
        $filter = '<Alias name=""${Name}"" />'
        $qryend =  "</FileSystemQueryParams>"
        $qryclose = '</Query></Request>'
        # Adding all the pieces together
        If (!$Name) {
            $request = $xmltop + $xmlformat + $qryopen + $qrybegin + $qryend + $qryclose + $xmlfooter   
        }
        Else {
            $request = $xmltop + $xmlformat + $qryopen + $qrybegin + $filter + $qryend + $qryclose + $xmlfooter
        }
    }
    PROCESS {
        $response = Invoke-RestMethod -Uri $apiuri -WebSession $CurrentVnxFrame.Session -Headers $header -Body $request -Method Post
    }
    END {
        $response.responsepacket.response.Filesystem
    }
}
Get-VnxFileSystem