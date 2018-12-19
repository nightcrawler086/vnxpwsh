<#
.SYNOPSIS
   This cmdlet queries filesystems on the VNX
.DESCRIPTION
   This cmdlet returns 
.EXAMPLE
   PS > Get-VnxFilesystem
#>
#function Get-VnxFileSystem {
    [CmdletBinding()]
    Param
    (
        # Get the filesystem by name
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$true,
         ParameterSetName = "ByName",
         Position=1)]
        [ValidateNotNullOrEmpty()]
         [string]$Name,
        # Get the filesystem by ID
        # Apparently this doesn't work either
        #[Parameter(Mandatory=$true,
        # ValueFromPipelineByPropertyName=$true,
        # ParameterSetName = "ById",
        # Position=2)]
        #[ValidateNotNullOrEmpty()]
        # [int]$Id,
        # Get filesystems by physical data mover
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$true,
         ParameterSetName = "ByMover",
         Position=3)]
        [ValidateNotNullOrEmpty()]
         [int]$Mover,
        # Get filesystems by virtual data mover
        [Parameter(Mandatory=$true,
          ValueFromPipelineByPropertyName=$true,
          ParameterSetName = "ByVdm",
          Position=4)]
        [ValidateNotNullOrEmpty()]
         [int]$Vdm,
        # Get fsCapabilities properties
        [Parameter(Mandatory=$false)]
         [switch]$FsCapabilities,
        # Get filesystem checkpoint information
        [Parameter(Mandatory=$false)]
         [switch]$FsCheckpointInfo
    )
    BEGIN {
        # Expecting a Global variable to be set called
        # CurrentVnxSystem which contains the existing
        # session.
        If (!$CurrentVnxFrame) {
            Write-Host -ForegroundColor Yellow "Not currently connected to a VNX System."
            Write-Host -ForegroundColor Yellow "Run Connect-VnxSystem first."
            Exit 1
        }
        # This is the query URL, created using the hostname in CurrentVnxFrame global variable
        $apiuri = "https://$($CurrentVnxFrame.HostName)/servlets/CelerraManagementServices"
        # Setting header for the HTML request
        $header = @{"Content-Type" = "x-www-form-urlencoded"}
        # XML sheet declaration
        $xmldec = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        # Standard format of XML Sheet
        $reqopen = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api" >'
        # Standard Footer for XML Sheet
        $reqclose = '</RequestPacket>'
        # Open the query node
        $qryopen = '<Request><Query>'
        # Open the filesystem query node
        $qrybegin = "<FileSystemQueryParams>"  
        # Close the filesystem query node
        $qryend =  "</FileSystemQueryParams>"
        # Close the query
        $qryclose = '</Query></Request>'
        # This is where we decide if we're going to filter the filesystems by
        # name or mover.
        If ($Name) {
            # Going to query a filesystem by name
            $filter = '<Alias name="'+ ${Name} + '" />'
        }
        ElseIf ($Id) {
            # Going to query a filesystem by Id
            $filter = '<FileSystem fileSystem="' + ${Id} + '" />'
        }
        ElseIf ($Mover) {
            # Going to query filesystems by physical datamover
            $filter = '<Mover mover="' + ${Mover} + '" />'
        }
        ElseIf ($Vdm) {
            # Going to query filesystems by VDM
            $filter = '<Vdm vdm="' + ${Vdm} + '" />'
        }
        Else {
            # No filter specified, retrieve all filesystems
            $filter = ""
        }
        # Defining all aspects available, to build the selection list
        $asp1 = 'fileSystems="true" '
        $asp2 = 'fileSystemCapacityInfos="true" '
        $asp3 = 'fileSystemCapabilities="true" '
        $asp4 = 'fileSystemCheckpointInfos="true" '
        # Need to figure out how to build the aspect selections
        $aspects = $asp1 + $asp2 
        # This next set of statements switches the options on/off according to the switches passed
        If ($FsCapabilities) {
            $aspects = $aspects + $asp3
        }
        If ($FsCheckpointInfo) {
            $aspects = $aspects + $asp4
        }
        $aspects = '<AspectSelection ' + $aspects + '/>'
        #write-host $aspects
        # Put all the pieces together to build the XML document
        If ($filter) {
            $body = $xmldec + $reqopen + $qryopen + $qrybegin + $aspects + $filter + $qryend + $qryclose + $reqclose
        }
        Else {
            $body = $xmldec + $reqopen + $qryopen + $qrybegin + $aspects + $qryend + $qryclose + $reqclose
            #Write-host $body
        }
    
    }
    PROCESS {
        $response = Invoke-RestMethod -Uri $apiuri -WebSession $CurrentVnxFrame.Session -Headers $header -Body $body -Method Post
        #Need to 
    }
    END {
        $response
    }
#}
#Get-VnxFileSystem