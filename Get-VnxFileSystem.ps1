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
         Position=2)]
         [ValidateNotNullOrEmpty()]
         $Mover,

         [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$true,
         Position=1)]
         [ValidateNotNullOrEmpty()]
         $Vdm,
        # Switch Parameters for aspect selections
        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$false,
         Position=2)]
         [switch]$FsCapabilities,

         [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$false,
         Position=2)]
         [switch]$FsCheckpointInfo,
         
         [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$false,
         Position=2)]
         [switch]$FsDhsmInfo,

         [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$false,
         Position=2)]
         [switch]$FsRdeInfo
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
        $qrybegin = "<FileSystemQueryParams>"
        $aspects = "<AspectSelection fileSystems=""true"" fileSystemCapacityInfos=""true"" />"  
        
        $qryend =  "</FileSystemQueryParams>"
        $qryclose = '</Query></Request>'
        # Adding all the pieces together
        If (!$Name) {
            <#
            [xml]$request = New-Object System.Xml.XmlDocument
            $dec = $request.CreateXmlDeclaration("1.0", "UTF-8", "yes")
            $request.AppendChild($dec)
            $request.AppendChild($xmlformat)
            $request.AppendChild($qryopen)
            $request.AppendChild($qrybegin)
            $request.AppendChild($qryend)
            $request.AppendChild($qryclose)
            $request.AppendChild($xmlfooter)
            write-host $request
            #>
            $request = $xmltop + $xmlformat + $qryopen + $qrybegin + $aspects + $qryend + $qryclose + $xmlfooter   
        }
        Else {
            $filter = '<Alias name=""${Name}"" />'
            $request = $xmltop + $xmlformat + $qryopen + $qrybegin + $aspects + $filter + $qryend + $qryclose + $xmlfooter
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