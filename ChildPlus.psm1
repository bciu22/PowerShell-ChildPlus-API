Function Decode-Request{
    <#
    .SYNOPSIS
        Decodes a Base64 encoded ZipArcive, and extracts the SoapBody File

    #>
      param(
        $base64Body
    )
  [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression') | Out-Null

  $ZipBytes =  [System.Convert]::FromBase64String($base64Body)
  $ZipStream = New-Object System.IO.Memorystream
  $ZipStream.Write($ZipBytes,0,$ZipBytes.Length)
  $ZipArchive = New-Object System.IO.Compression.ZipArchive($ZipStream)
  $ZipEntry = $ZipArchive.GetEntry('SoapBody')
  $EntryReader = New-Object System.IO.StreamReader($ZipEntry.Open())
  $DocItemSet = $EntryReader.ReadToEnd()
  return $DocItemSet
}

Function Encode-Request 
{
    <#
    .SYNOPSIS
        Encodes and compresses a SoapBody as a file in a Base64 encoded ZipArcive

    #>
    param (
        $SOAPBody
    )
    # first, ZIP the soap body as soapBody in the ZipArchive
    $MemoryStream = New-Object System.IO.Memorystream
    $ZipArchive = New-Object System.IO.Compression.ZipArchive($MemoryStream, [System.IO.Compression.ZipArchiveMode]::Create)
    $Entry = $ZipArchive.CreateEntry("SoapBody")
    $sw = New-Object System.IO.StreamWriter ($Entry.open())
    $sw.write($SoapBody);
    $sw.flush()
    $sw.close()
    $MemoryStream.Seek(0,0) | Out-Null
    [Convert]::ToBase64String($MemoryStream.ToArray())
    #Then convert to base 64
    
  return $DocItemSet
}

Function Decode-GZip {
    <#
    .SYNOPSIS
        Not used in this module, but good for reference - Dcodeds GZip Stream to a string.
    #>
    param(
        $Bytes
    )
    $data = Get-Content "C:\Users\ccrossan\Desktop\test.gz" -Encoding Byte
    $ms = New-Object System.IO.MemoryStream
    $ms.Write($data,0,$data.length)
    $ms.seek(0,0)
    $stream = new-object -TypeName System.IO.MemoryStream
    $GZipStream = New-object -TypeName System.IO.Compression.GZipStream -ArgumentList $ms, ([System.IO.Compression.CompressionMode]::Decompress)
    $sr = New-Object System.IO.StreamReader ($GZipStream)
    $js = $sr.ReadToEnd()
}


#Get-Students : GET https://www.childplus.net/Services/VersionService_4.5.91.0/api/ServicesNavigation/GetPersonsFromSavedSearch HTTP/1.1
# Then Decode GZIP




Function Connect-ChildPlusService
{
     <#
    .SYNOPSIS
        Connects to the ChildPlus service.

    .PARAMETER agencyName  
        The name of the ChildPlus Agency 
    .PARAMETER user 
        The User Name
    .PARAMETER encodedPassword
        The encoded password (must capture from HTTPS inspection of actualy ChildPlus Login with Fiddler)
    #>
    Param(
        $agencyName,
        $user,
        $encodedPassword
    )
    
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression') | Out-Null

    $Headers = @{
        "SOAPAction" = "https://www.childplus.net/Services/VersionService/Login"
    }

    #Get the SesssionID
    $SOAPRequest="<?xml version=""1.0"" encoding=""utf-8""?><soap:Envelope xmlns:soap=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema""><soap:Header><AuthenticationHeader xmlns=""https://www.childplus.net/Services/VersionService""><UserID>00000000-0000-0000-0000-000000000000</UserID><DatabaseID>00000000-0000-0000-0000-000000000000</DatabaseID><SessionID>00000000-0000-0000-0000-000000000000</SessionID></AuthenticationHeader></soap:Header><soap:Body><Login xmlns=""https://www.childplus.net/Services/VersionService""><agencyName>$agencyName</agencyName><user>$user</user><password>$encodedPassword</password></Login></soap:Body></soap:Envelope>"
    $RequestBody  = Encode-Request -SOAPBody $SOAPRequest
    $response = Invoke-WebRequest -URI "https://www.childplus.net/Services/VersionService_4.5.91.0/Service.asmx" -Method POST -UserAgent "Mozilla/4.0 (compatible; MSIE 6.0; MS Web Services Client Protocol 4.0.30319.42000)" -ContentType "text/xml; charset=utf-8" -Headers $Headers -Body $RequestBody
    $SessionXML = [xml](Decode-Request -base64Body $response.content)
    Set-Variable -Scope Global -Name "SessionID" -Value $SessionXML.Envelope.Header.AuthenticationHeader.SessionID


    #Lie to CP about the current computer
    $Headers = @{
        "SOAPAction" = "https://www.childplus.net/Services/VersionService/SubmitClientMetrics"
    }

    $SOAPRequest = "<?xml version=""1.0"" encoding=""utf-8""?><soap:Envelope xmlns:soap=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema""><soap:Header><AuthenticationHeader xmlns=""https://www.childplus.net/Services/VersionService""><UserID>00000000-0000-0000-0000-000000000000</UserID><DatabaseID>00000000-0000-0000-0000-000000000000</DatabaseID><SessionID>$($SessionXML.Envelope.Header.AuthenticationHeader.SessionID)</SessionID></AuthenticationHeader></soap:Header><soap:Body><SubmitClientMetrics xmlns=""https://www.childplus.net/Services/VersionService""><clientMetrics><MachineName>$env:computername</MachineName><UserName>$env:username</UserName><UserDomain>$env:USERDOMAIN</UserDomain><HostName>$env:computername</HostName><DomainName>$env:USERDNSDOMAIN</DomainName><OS_MajorVersion>10</OS_MajorVersion><OS_MinorVersion>0</OS_MinorVersion><OS_BuildNumber>14393</OS_BuildNumber><OS_RevisionNumber>0</OS_RevisionNumber><OS_ServicePack>0</OS_ServicePack><OS_PlatformID>2</OS_PlatformID><OS_Bits>64</OS_Bits><DotNet_10 xsi:nil=""true"" /><DotNet_11 xsi:nil=""true"" /><DotNet_20>2</DotNet_20><DotNet_30>2</DotNet_30><DotNet_35>1</DotNet_35><DotNet_40>0</DotNet_40><IsThinApp>false</IsThinApp><HasThinAppWritePermission xsi:nil=""true"" /><IsTS>false</IsTS><DisplayWidth>1920</DisplayWidth><DisplayHeight>1080</DisplayHeight><LogicalPixelsX>96</LogicalPixelsX><LogicalPixelsY>96</LogicalPixelsY><IsProcessDPIAware>true</IsProcessDPIAware><IsUserAdministrator xsi:nil=""true"" /><IsProcessElevated xsi:nil=""true"" /><IsUACActive>true</IsUACActive><UserSecuritySetting>NormalUser</UserSecuritySetting><NumberFilesCopied xsi:nil=""true"" /><TotalSizeCopied xsi:nil=""true"" /><TotalTimeCopying xsi:nil=""true"" /><NumberFilesDownloaded xsi:nil=""true"" /><TotalSizeDownloaded xsi:nil=""true"" /><TotalTimeDownloading xsi:nil=""true"" /><TotalTimeUpdating xsi:nil=""true"" /></clientMetrics></SubmitClientMetrics></soap:Body></soap:Envelope>"
    $RequestBody  = Encode-Request -SOAPBody $SOAPRequest
    $response = Invoke-WebRequest -URI "https://www.childplus.net/Services/VersionService_4.5.91.0/Service.asmx" -Method POST -UserAgent "Mozilla/4.0 (compatible; MSIE 6.0; MS Web Services Client Protocol 4.0.30319.42000)" -ContentType "text/xml; charset=utf-8" -Headers $Headers -Body $RequestBody
    $DBXML = [xml](Decode-Request -base64Body $response.content)
    Set-Variable -Scope Global -Name "DatabaseID" -Value  $DBXML.Envelope.Header.AuthenticationHeader.DatabaseID


    Set-Variable -Scope Global -Name "UserID" -Value $SessionXML.Envelope.Header.AuthenticationHeader.UserID
    


}


function Get-ChildPlusStudents
{
     <#
    .SYNOPSIS
       Retrieves the 

    .PARAMETER agencyName  
        The name of the ChildPlus Agency 
    .PARAMETER user 
        The User Name
    .PARAMETER encodedPassword
        The encoded password (must capture from HTTPS inspection of actualy ChildPlus Login with Fiddler)
    #>
    $soapbody = "<?xml version=""1.0"" encoding=""utf-8""?><soap:Envelope xmlns:soap=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema""><soap:Header><AuthenticationHeader xmlns=""https://www.childplus.net/Services/VersionService""><UserID>$($(Get-Variable -Name ""UserID"").value)</UserID><DatabaseID>$($(Get-Variable -Name ""DatabaseID"").value)</DatabaseID><SessionID>$($(Get-Variable -Name ""SessionID"").value)</SessionID></AuthenticationHeader></soap:Header><soap:Body><GetDataSet xmlns=""https://www.childplus.net/Services/VersionService""><dataAccessType>Report_LiveQuery</dataAccessType><methodName>GetDataSet</methodName><parameters><anyType xsi:type=""LiveQueryFilterCriteria""><CustomFilterMatchAll>false</CustomFilterMatchAll><LiveQueryID>ddd48caa-da08-4b5e-b5f8-c95cd5efa219</LiveQueryID><ParametersDefinition>[{""ControlType"":""ProgramTerm"",""EditValue"":""d4f5f536-6309-4347-88af-4003f40ccf59"",""Name"":""ProgramTerm"",""IsRequired"":false,""UseSeparateLabelControl"":true,""LabelText"":""Program Term"",""LabelToolTipText"":null,""Width"":400},{""UseSeparateLabelControl"":false,""ControlType"":""Checkbox"",""EditValue"":true,""Name"":""ExpandToSchoolYear"",""IsRequired"":false,""LabelText"":""Include other Program Terms in the same School Year"",""LabelToolTipText"":null,""Width"":25},{""ControlType"":""Location"",""AgencyID"":""11111111-1111-1111-1111-111111111111"",""SiteID"":""11111111-1111-1111-1111-111111111111"",""ClassroomID"":""11111111-1111-1111-1111-111111111111"",""Name"":""LocationControl"",""IsRequired"":false,""UseSeparateLabelControl"":true,""LabelText"":""Location"",""LabelToolTipText"":null,""Width"":400},{""AllowedStatuses"":[],""DefaultCheckedStatuses"":[],""CheckedStatusTypes"":[3],""ControlType"":""EnrollmentStatus"",""Name"":""Status"",""IsRequired"":false,""UseSeparateLabelControl"":true,""LabelText"":""Status"",""LabelToolTipText"":null,""Width"":null}]</ParametersDefinition></anyType></parameters></GetDataSet></soap:Body></soap:Envelope>"

    $RequestBody = Encode-Request -SOAPBody $soapbody

     $Headers = @{
        "SOAPAction" = "https://www.childplus.net/Services/VersionService/GetDataSet"
    }

    $q = Invoke-WebRequest -URI "https://www.childplus.net/Services/VersionService_4.5.91.0/Service.asmx" -Method POST -UserAgent "Mozilla/4.0 (compatible; MSIE 6.0; MS Web Services Client Protocol 4.0.30319.42000)" -ContentType "text/xml" -Headers $Headers -Body $RequestBody
    $xml = [xml](Decode-Request $q.content)
    $xml.Envelope.Body.GetDataSetResponse.GetDataSetResult.ds.diffgram.NewDataSet.Table1
}


Function Get-CallEmAll {

    $soapbody = "<?xml version=""1.0"" encoding=""utf-8""?><soap:Envelope xmlns:soap=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema""><soap:Header><AuthenticationHeader xmlns=""https://www.childplus.net/Services/VersionService""><UserID>$($(Get-Variable -Name ""UserID"").value)</UserID><DatabaseID>$($(Get-Variable -Name ""DatabaseID"").value)</DatabaseID><SessionID>$($(Get-Variable -Name ""SessionID"").value)</SessionID></AuthenticationHeader></soap:Header><soap:Body><GetDataSet xmlns=""https://www.childplus.net/Services/VersionService""><dataAccessType>Report_LiveQuery</dataAccessType><methodName>GetDataSet</methodName><parameters><anyType xsi:type=""LiveQueryFilterCriteria""><CustomFilterMatchAll>false</CustomFilterMatchAll><LiveQueryID>20c787b9-1a61-4f85-b0fa-b95d9603cb77</LiveQueryID><ParametersDefinition>[{""ControlType"":""ProgramTerm"",""EditValue"":""cc2f1d08-1799-495c-a2aa-e3fca2a93a99"",""Name"":""PTID"",""IsRequired"":false,""UseSeparateLabelControl"":true,""LabelText"":""Program Term"",""LabelToolTipText"":null,""Width"":400},{""UseSeparateLabelControl"":false,""ControlType"":""Checkbox"",""EditValue"":true,""Name"":""ExpandToSchoolYear"",""IsRequired"":false,""LabelText"":""Include other Program Terms in the same School Year"",""LabelToolTipText"":null,""Width"":25},{""ControlType"":""Location"",""AgencyID"":""11111111-1111-1111-1111-111111111111"",""SiteID"":""11111111-1111-1111-1111-111111111111"",""ClassroomID"":""11111111-1111-1111-1111-111111111111"",""Name"":""LocationControl"",""IsRequired"":false,""UseSeparateLabelControl"":true,""LabelText"":""Location"",""LabelToolTipText"":null,""Width"":400},{""AllowedStatuses"":[""New"",""Accepted"",""Waitlisted"",""Enrolled"",""Dropped"",""Drop_Wait"",""Drop_Accepted"",""Completed""],""DefaultCheckedStatuses"":[""Enrolled"",""Dropped"",""Drop_Wait"",""Drop_Accepted"",""Completed""],""CheckedStatusTypes"":[3,4,5,8,6],""ControlType"":""EnrollmentStatus"",""Name"":""Status"",""IsRequired"":false,""UseSeparateLabelControl"":true,""LabelText"":""Status"",""LabelToolTipText"":null,""Width"":null}]</ParametersDefinition></anyType></parameters></GetDataSet></soap:Body></soap:Envelope>"

    $RequestBody = Encode-Request -SOAPBody $soapbody

     $Headers = @{
        "SOAPAction" = "https://www.childplus.net/Services/VersionService/GetDataSet"
    }

    $q = Invoke-WebRequest -URI "https://www.childplus.net/Services/VersionService_4.5.91.0/Service.asmx" -Method POST -UserAgent "Mozilla/4.0 (compatible; MSIE 6.0; MS Web Services Client Protocol 4.0.30319.42000)" -ContentType "text/xml" -Headers $Headers -Body $RequestBody
    $xml = [xml](Decode-Request $q.content)
    $xml.Envelope.Body.GetDataSetResponse.GetDataSetResult.ds.diffgram.NewDataSet.Table1
    
}

Function Get-SchoolMessengerStudentExport {

$soapbody = "<?xml version=""1.0"" encoding=""utf-8""?><soap:Envelope xmlns:soap=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema""><soap:Header><AuthenticationHeader xmlns=""https://www.childplus.net/Services/VersionService""><UserID>$($(Get-Variable -Name ""UserID"").value)</UserID><DatabaseID>$($(Get-Variable -Name ""DatabaseID"").value)</DatabaseID><SessionID>$($(Get-Variable -Name ""SessionID"").value)</SessionID></AuthenticationHeader></soap:Header><soap:Body><GetDataSet xmlns=""https://www.childplus.net/Services/VersionService""><dataAccessType>Report_LiveQuery</dataAccessType><methodName>GetDataSet</methodName><parameters><anyType xsi:type=""LiveQueryFilterCriteria""><CustomFilterMatchAll>false</CustomFilterMatchAll><LiveQueryID>24bd570c-0f56-4093-8e93-2d671a373d15</LiveQueryID><ParametersDefinition>[{""ControlType"":""ProgramTerm"",""EditValue"":""d4f5f536-6309-4347-88af-4003f40ccf59"",""Name"":""ProgramTerm"",""IsRequired"":false,""UseSeparateLabelControl"":true,""LabelText"":""Program Term"",""LabelToolTipText"":null,""Width"":400},{""UseSeparateLabelControl"":false,""ControlType"":""Checkbox"",""EditValue"":true,""Name"":""ExpandToSchoolYear"",""IsRequired"":false,""LabelText"":""Include other Program Terms in the same School Year"",""LabelToolTipText"":null,""Width"":25},{""ControlType"":""Location"",""AgencyID"":""11111111-1111-1111-1111-111111111111"",""SiteID"":""11111111-1111-1111-1111-111111111111"",""ClassroomID"":""11111111-1111-1111-1111-111111111111"",""Name"":""LocationControl"",""IsRequired"":false,""UseSeparateLabelControl"":true,""LabelText"":""Location"",""LabelToolTipText"":null,""Width"":400},{""AllowedStatuses"":[""New"",""Accepted"",""Waitlisted"",""Enrolled"",""Dropped"",""Drop_Wait"",""Drop_Accepted"",""Completed"",""Abandoned""],""DefaultCheckedStatuses"":[""Enrolled"",""Dropped"",""Drop_Wait"",""Drop_Accepted"",""Completed""],""CheckedStatusTypes"":[3,4,5,8,6],""ControlType"":""EnrollmentStatus"",""Name"":""Status"",""IsRequired"":false,""UseSeparateLabelControl"":true,""LabelText"":""Status"",""LabelToolTipText"":null,""Width"":null}]</ParametersDefinition></anyType></parameters></GetDataSet></soap:Body></soap:Envelope>"

    $RequestBody = Encode-Request -SOAPBody $soapbody

     $Headers = @{
        "SOAPAction" = "https://www.childplus.net/Services/VersionService/GetDataSet"
    }

    $q = Invoke-WebRequest -URI "https://www.childplus.net/Services/VersionService_4.5.91.0/Service.asmx" -Method POST -UserAgent "Mozilla/4.0 (compatible; MSIE 6.0; MS Web Services Client Protocol 4.0.30319.42000)" -ContentType "text/xml" -Headers $Headers -Body $RequestBody
    $xml = [xml](Decode-Request $q.content)
    $xml.Envelope.Body.GetDataSetResponse.GetDataSetResult.ds.diffgram.NewDataSet.Table1

}