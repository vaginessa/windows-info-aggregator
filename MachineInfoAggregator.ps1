Param([string]$target)

function getDestination{
    param([string]$previousAttempt)
    if($previousAttempt -eq "wrong"){
        $dest = Read-Host "That path is not valid, please try again."
    }
    $dest = Read-Host "Enter Where you would like your report generated."
    if(-not (Test-Path $dest)){
        getDestination "wrong"
    } else {
        return $dest;
    }
}

function getRemote{
    $title = "Remote or Local"
    $message = "Is this being performed on the local machine or remote connection?"
    $local = New-Object System.Management.Automation.Host.ChoiceDescription "&Local Machine"
    $remote = New-Object System.Management.Automation.Host.ChoiceDescription "&Remote Machine"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($local, $remote)
    $result = $host.ui.PromptForChoice($title, $message, $options, 0)
    $response = "false"

    switch ($result)
    {
        0 { }
        1 {
           $computername = Read-Host "Please enter the target computer name"
           return $computername;
        }
    }
}

$destination = getDestination
$computername = 0;
$creds = 0;
$computername = getRemote

if($computername){
    $creds = Get-Credential
} else {
    $computername = "Local Machine"
}

clear
Write-Host "Preparing Analysis..."
cd $destination | out-null
$report = "Report"
$index = 1;
while(Test-Path $destination/$report){
    $index++
    $report = "Report$index"
}
mkdir $report | out-null
cd $report | out-null

#Load functions into memory
function getWmiClass{
    param([string]$class, [System.Object]$cred, [string]$computername)
    if($cred){
        Write-Host $computername
        trap{
            $myError = "Error: " + $error[0].Exception
            return $myError
        }
        $currentClass = Get-WmiObject -class $class -computername $computername -credential $cred -EA 'Stop'
    } else {
        trap{
            $myError = "Error: " + $error[0].Exception
            return $myError
        }
        $currentClass = Get-WmiObject -class $class -EA 'Stop'
    }
    if($currentClass){
        return $currentClass
    } else {
        return "No Data Retrieved"
    }
}

$suitableClasses = @()

#Because some classes return too much data and take too long to run, I've decided to exclude them.
$unfitClasses = "CIM_ManagedSystemElement","CIM_LogicalElement","CIM_System","Win32_NTDomain","CIM_SoftwareElement","Win32_SoftwareElement",`
                "CIM_SoftwareFeature","Win32_SoftwareFeature","CIM_Service","Win32_Service","Win32_DfsNode","Win32_ApplicationService",`
                "CIM_ApplicationService","CIM_ServiceAccessPoint","Win32_ServiceAccessPoint","Win32_CommandLineAccess","CIM2_CommandLineAccess",`
                "Win32_ShadowCopy","Win32_DfsTarget","CIM_LogicalFile","Win32_ShadowProvider","CIM_Directory","Win32_Directory",`
                "CIM_DataFile","Win32_DataFile","Win32_NTLogEvent","CIM_Product","Win32_Product","CIM_NTLogEvent","CIM_StatisticalInformation",`
                "Win32_StatisticalInformation","CIM_Setting","Win32_Setting","Win32_MSIResource","CIM_MSIResource","Win32_ServiceControl",`
                "CIM_ServiceControl","Win32_Property","CIM_Property","Win32_Patch","CIM_Patch","Win32_PatchPackage","CIM_PatchPackage",`
                "Win32_ShortcutFile","CIM_ShortcutFile","Win32_Binary","CIM_Binary","Win32_SecuritySetting","Win32_LogicalFileSecuritySetting",`
                "CIM_LogicalFileSecuritySetting","CIM_SecuritySetting","CIM_Action","Win32_Action","Win32_ODBCAttribute","CIM_ODBCAttribute",`
                "Win32_ODBCSourceAttribute","CIM_ODBCSourceAttribute","Win32_ShortcutAction","CIM_ShortcutAction","Win32_ExtensionInfoAction",`
                "CIM2_ExtensionInfoAction","CIM_DirectoryAction","Win32_DirectoryAction","CIM_CreateDirectoryAction","Win32_CreateDirectoryAction",`
                "Win32_CreateFolderAction","CIM_CreateFolderAction","Win32_RegistryAction","CIM_RegistryAction","Win32_ClassInfoAction",`
                "Win32_SelfRegModuleAction","Win32_TypeLibraryAction","Win32_TypeLibraryAction","Win32_BindImageAction","Win32_RemoveIniAction",`
                "Win32_MIMEInfoAction","Win32_FontInfoAction","Win32_PublishComponentAction","CIM_FileAction","Win32_MoveFileAction",`
                "CIM_CopyFileAction","Win32_DuplicateFileAction","CIM_RemoveFileAction","Win32_RemoveFileAction","Win32_ProductResource",`
                "CIM_Statistics","Win32_ManagedSystemElementResource","Win32_SoftwareElementResource","Win32_SID","Win32_ActionCheck",`
                "CIM_ElementSetting","Win32_SecuritySettingOfObject","Win32_SecuritySettingOfLogicalShare","Win32_SecuritySettingOfLogicalFile",`
                "Win32_PageFileElementSetting","CIM_InstalledSoftwareElement","Win32_InstalledSoftwareElement","Win32_SoftwareFeatureCheck",`
                "Win32_VolumeUserQuota","CIM_Check","CIM_DirectorySpecification","Win32_DirectorySpecification","Win32_SoftwareElementCondition",`
                "Win32_ODBCDriverSpecification","Win32_ODBCDataSourceSpecification","Win32_ODBCTranslatorSpecification","Win32_ServiceSpecification",`
                "CIM_FileSpecification","Win32_FileSpecification","Win32_IniFileSpecification","Win32_LaunchCondition","Win32_ProgIDSpecification",`
                "Win32_EnvironmentSpecification","Win32_ReserveCost","Win32_ODBCDriverAttribute","Win32_ODBCDataSourceAttribute","CIM_ElementConfiguration",`
                "Win32_Condition","Win32_ShadowStorage","Win32_ServiceSpecificationService","Win32_SettingCheck","Win32_PatchFile","Win32_ClientApplicationSetting",`
                "Win32_SecuritySettingOwner","Win32_LogicalFileOwner","Win32_PingStatus","CIM_SoftwareElementChecks","Win32_ShortcutSAP",`
                "Win32_SoftwareElementCheck","CIM_Component","CIM_DirectoryContainsFile","Win32_UserInDomain","Win32_SubDirectory","Win32_Reliability",`
                "Win32_ReliabilityRecords","OfficeSoftwareProtectionProduct","Win32_SecuritySettingGroup","Win32_SecuritySettingAuditing",`
                "CIM_Dependency","CIM_ServiceAccessBySAP","CIM_BootServiceAccessBySAP","CIM_ClusterServiceAccessBySAP","Win32_ApplicationCommandLine",`
                "Win32_PnPSignedDriverCIMDataFile","Win32_GroupInDomain","Win32_NTLogEventLog","Win32_SoftwareFeatureParent","Win32_DfsNodeTarget",`
                "Win32_ProductCheck","Win32_NTLogEventUser","Win32_NTLogEventComputer","Win32_CheckCheck","Win32_SecuritySettingAccess","Win32_Thread",`
                "CIM_Thread","Win32_COMClass","CIM_COMClass","Win32_ReliabilityStabilityMetrics","CIM_ProductSoftwareFeatures","Win32_ProductSoftwareFeatures"

$classes = Get-WMIObject -List| Where{$_.name -match ""}
$classes = $classes | Where {$_ -notmatch "perf"}
$classes = $classes | Where {$_ -notmatch "odbc"}
$classes = $classes | Where {$_ -notmatch "element"}
$classes = $classes | Where {$_ -notmatch "action"}
$classes = $classes | Where {$_ -notmatch "logical"}
$classes = $classes | Where {$_ -notmatch "sap"}
$classes = $classes | Where {$_ -notmatch "shadow"}
$classes = $classes | Where {$_ -notmatch "com"}

#Create they stylesheet
Write-Host "Creating stylesheet..."
$cssStream = [System.IO.StreamWriter] "$destination/$report/format.css"
$cssStream.WriteLine('body {margin:0;font:13px/18px "Lucida Grande", "Lucida Sans Unicode", Helvetica, Arial, Verdana, sans-serif;}')
$cssStream.WriteLine('body.index h1, body.index p{text-align:center}')
$cssStream.WriteLine("h1{padding-top:20px;}")
$cssStream.WriteLine("#valid div, #nodata div, #error div{transition:all 1s; background-color:white; width:300px; padding:15px; display:inline-block; overflow:hidden}")
$cssStream.WriteLine("#valid div:hover, #nodata div:hover, #error div:hover{transition:all 1s; background-color:#EEE}")
$cssStream.WriteLine("a{color:black; text-decoration:none;}")
$cssStream.WriteLine("table{text-align:center;font-size:10pt;}")
$cssStream.WriteLine("td{border:1px solid #CCC;}")
$cssStream.WriteLine("th{color:white;background-color:#555;font-weight:bold;padding:10px;}")
$cssStream.WriteLine(".error span{color:red; font-size:18pt; font-weight:bold; padding:15px;}")
$cssStream.WriteLine(".error{text-align:left}")
$cssStream.WriteLine("#valid, #nodata, #error{width:100%; display:block;margin-bottom:35px;}")
$cssStream.WriteLine("#panel{width:250px;display:inline-block;position:fixed;height:100%;box-shadow:0px 0px 20px 0px #AAA;background-color:#EEE;}")
$cssStream.WriteLine("#content{margin-left:250px;display:inline-block;text-align:center;}")
$cssStream.WriteLine(".header{text-align:center;font-size:16pt;padding:20px;margin-top:8px;}")
$cssStream.WriteLine(".details{text-align:center;}")
$cssStream.WriteLine("input{width:210px;margin-left:19px;margin-top:19px;height:25px;font-style:italic;padding-left:10px;}")
$cssStream.WriteLine(".link a{font-size:13pt; text-align:center; line-height:45px;margin-left:38px;}");
$cssStream.WriteLine(".link a:hover{color:green; text-decoration:underline;}");
$cssStream.close()

#Create the index page with all the appropriate links, and push viable classes to search
Write-Host "Creating Folders and Index File..."
$indexStream = [System.IO.StreamWriter] "$destination/$report/main.html"
$indexStream.WriteLine('<html><head><title>Your Report</title><link rel=stylesheet href=format.css><script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script></head><body class=index>')
$today = Get-Date
$indexStream.WriteLine("<div id=panel><div class=header>Report Details</div><div class=details>Date Ran: $today <br />Target Machine: $computername</div>")
$indexStream.WriteLine('<div id=searchBar><input type=input class=search placeholder="Type to search..." /></div>')
$indexStream.WriteLine('<div class=link><a href="systemProcess/systemProcess.html">System Processes</a><br /><a href="#valid">Valid Data</a><br /><a href="#nodata">No Data</a><br /><a href="#error">Errors</a><br /></div></div><div id=content>')
$indexStream.WriteLine("<div id=valid><h1>Report Index</h1><p>Click a link below to view an in depth detail, if data were available.<p></div>")
$indexStream.WriteLine("<div id=nodata><h1>No Data Returned</h1><p>The following WMI classes returned no data.</p></div>")
$indexStream.WriteLine("<div id=error><h1>Errors</h1><p>The following WMI classes were unable to be accessed.</p></div></div>")
foreach($class in $classes){
    if($unfitClasses -notcontains $class.name){
        $suitableClasses += $class.name
    }
}


#Perform analysis on each wmi class
$index = 0
Write-Host "Starting Analysis..."
foreach($klass in $suitableClasses){
    mkdir $klass | out-null
    cd $klass | out-null
    Write-Host $index, "/", $suitableClasses.length, "    Analyzing:", $klass
    if($creds){ Write-Host $creds, "WERE HERE"
    $analysis = getWmiClass $klass $creds $computername }
    else { $analysis = getWmiClass $klass }
    if($analysis -like "Error:*"){
          Write-host "Properly Archiving Error"
          $indexStream.WriteLine("<div class=error><h3>$klass</h3><br />$analysis</div>")
    } elseIf($analysis -eq "No Data Retrieved"){
          $indexStream.WriteLine("<div class=notvalid>$klass</div>")
    } else {
          $stream = [System.IO.StreamWriter] "$destination/$report/$klass/$klass.html"
          $stream.WriteLine("<html><head><title>$klass</title><link rel=stylesheet href=../format.css></head><body class=data>")
          $stream.WriteLine("<h1>$klass</h1><table><thead><tr>")
          $indexStream.WriteLine("<div class=valid><a href=" + $klass +"/" + $klass + ".html>$klass</a></div>")
          $current = $analysis
          $properties = $analysis | Get-Member | Where {$_.MemberType -eq "Property"}
          $props = @()
          foreach($property in $properties){
              $propName = $property.Name
              $props += $propName
              $stream.WriteLine("<th>$propName</th>")
          }
          $stream.WriteLine("</tr></thead><tbody>")
          foreach($entry in $current){
              $stream.WriteLine("<tr>")
              foreach($prop in $props){
                   $value = $entry[$prop]
                   $stream.WriteLine("<td>$value</td>")
              }
              $stream.WriteLine("</tr>")
          }
          $stream.WriteLine("</tbody></body></html>")
          $stream.close()
    }
    $index++
    cd ".." | out-null
}

#Close Index Page writer
$indexStream.WriteLine('<script>$(".notvalid").appendTo("#nodata");$(".valid").appendTo("#valid");$(".error").appendTo("#error");</script>')
$indexStream.WriteLine('<script>function search(e){var t=[];$.each(visible,function(){if(this.value.indexOf(e)==-1){$(this.el).hide()}else{t.push(this)}});visible=t.slice(0)}function releaseAll(){$("div").show()}window.klasses=[];window.input=$("input");window.currentLength=0;$.each($(".error, .valid, .notvalid"),function(){var e=this;klasses.push({value:function(){if($(e).hasClass("valid")){return $(e).children()[0].text.toLowerCase()}else{return $(e).text().toLowerCase()}}(),el:this})});window.visible=klasses.slice(0);input.on("keyup",function(){var e=input.val().toLowerCase();if(e.length<currentLength){visible=klasses.slice(0);releaseAll()}currentLength=e.length;if(currentLength>2){search(e)}else{releaseAll()}})</script>')
$indexStream.WriteLine("</body></html>")
$indexStream.close()

$start = $destination + "\" + $report + "\main.html"
Invoke-Item $start

#Get Service Names
