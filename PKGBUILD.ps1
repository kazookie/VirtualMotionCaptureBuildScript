$pkgname="VirtualMotionCapture"
$pkgver="0.47"
$url="https://vmc.info/"
$source=@(
    "https://github.com/sh-akira/VirtualMotionCapture/archive/refs/tags/v${pkgver}.zip"
    "https://github.com/ValveSoftware/steamvr_unity_plugin/releases/download/2.6.1/steamvr_2_6_1.unitypackage"
    "https://github.com/vrm-c/UniVRM/releases/download/v0.53.0/UniVRM-0.53.0_6b07.unitypackage"
    "https://securecdn.oculus.com/binaries/download/?id=1698211783621806"
    "https://github.com/hecomi/uOSC/releases/download/v0.0.2/uOSC-v0.0.2.unitypackage"
    "https://github.com/keijiro/MidiJack/raw/master/MidiJack.unitypackage"
    "https://dl.vive.com/SDK/vivesense/SRanipal/SDK-v1.3.6.8.zip"
    "https://github.com/sh-akira/ColorPickerWPF/archive/c6cd911.zip"
)
$depends=@("Unity-2019.4.8f1","VisualStudio2019")
$wrkdir=pwd
$srcdir="${wrkdir}\src"
$prjname="${pkgname}-${pkgver}"
$prjpath="${srcdir}\${prjname}"

$unity_hub_download="https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.exe"
$unity_hub=''
$unity_version =  ($depends | Where-Object {($_ -match "^Unity")}).Replace("Unity-", "")
$unitiy_release_url = "https://unity.com/releases/editor/whats-new/" + $unity_version -replace "f.*",""
$unity_editor_download = (Invoke-WebRequest -UseBasicParsing $unitiy_release_url).Links | Where-Object {$_.href -like "*Windows64EditorInstalle*"} | Select-Object -ExpandProperty href
$unity_editor=''

$vs_download="https://aka.ms/vs/16/release/vs_community.exe"
$vswhere ="${env:programFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs_version = ($depends | Where-Object { $_ -match "^VisualStudio" }) -replace "^[a-zA-Z]*"
$vs_components=@(
    "Microsoft.VisualStudio.Workload.ManagedDesktop"
    "Microsoft.Net.Component.4.7.1.TargetingPack"
)
$msbuild=''
$buildconfig='BETA'

function check() {
    # Check Unity Hub installed and set installed path
    echo "Checking Unity Hub installed ..."
    $unity_hub = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Unity Technologies\Hub").InstallLocation
    if ($unity_hub -eq $null) {
        $input = Read-Host "Not found Unitu Hub. Would you like to install it?(y/n)"
        if ($input -eq "y") {
            $filename = Split-Path $unity_hub_download -leaf
            echo "Downloading UnityHubSetup.exe from ${unity_hub_url}"
            curl.exe -LO $unity_hub_download
            $installer_proc = Start-Process -FilePath $filename -PassThru
            $installer_proc.WaitForExit()
            Read-Host "Please sign in to Unity Hub and activate your license.(Press enter to proceed)"
        }
        else {
          exit
        }
    }
    $unity_hub = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Unity Technologies\Hub").InstallLocation
    $unity_hub = "${unity_hub}\Unity Hub.exe"
    Set-Variable -Scope script -Name "unity_hub" -Value $unity_hub
    
    # Check Unity Editor installed and set installed path
    echo "Checking Unity Editor installed ..."
    $unity_editor_info = & $unity_hub -- --headless editors -i | Select-String -Pattern "${unity_version}"
    if ($unity_editor_info -eq $null){
        $input = Read-Host "Not found Unitu Editor ${unity_version}. Would you like to install it?(y/n)"
        if ($input -eq "y") {
            $filename = Split-Path $unity_editor_download -leaf
            echo "Downloading ${filename} from ${unity_editor_download}"
            curl.exe -LO $unity_editor_download
            $installer_proc = Start-Process -FilePath $filename -PassThru
            $installer_proc.WaitForExit()
            Read-Host "Please add Unity Editor location to Unity Hub.(Press enter to proceed)"
        }
        else {
          exit
        }
    }
    $unity_editor_info = & $unity_hub -- --headless editors -i | Select-String -Pattern "${unity_version}"
    $unity_editor = [RegEx]::Replace($unity_editor_info, "^.*installed at ", {})
    Set-Variable -Scope script -Name "unity_editor" -Value $unity_editor
    
    # Check VisualStudio
    echo "Checking Visual Studio installed ..."
    $visual_studio_info = & $vswhere -requires $vs_components |
        Select-String -Pattern "displayName","installationPath" |
        Select-String -Pattern "${vs_version}" |
        Select-Object -First 1
    
    if ($visual_studio_info -eq $null) {
        echo "Not found Visual Studio ${$vs_version} with .NET 4.7.1 desktop development."
        $input = Read-Host "Would you like to install it?(y/n)"
        if ($input -eq "y") {
            $filename = Split-Path $vs_download -leaf
            echo "Downloading ${filename} from ${unity_editor_download}"
            curl.exe -LO $vs_download
            $installer_proc = Start-Process -FilePath $filename -ArgumentList "--add ${vs_components}" -PassThru
            $installer_proc.WaitForExit()
            Read-Host "(Press enter when the installation is finished)"
            $visual_studio_info = & $vswhere -products * | Select-String -Pattern "displayName","installationPath" | Select-String -Pattern "${vs_version}" | Select-Object -First 1
        }
        else {
          exit
        }
    }
    $vs_location = ($visual_studio_info | Select-String -Pattern "installationPath") -replace "installationPath: ",""
    $msbuild = (Get-ChildItem -Path $vs_location "MSBuild.exe" -Recurse).FullName | Select-String -Pattern "amd64"
    Set-Variable -Scope script -Name "msbuild" -Value $msbuild
    
    # Check if there is a Final IK
    echo "Checking 'Final IK.unitypackage' ..."
    if (!(Test-Path "Final IK.unitypackage")) {
        $finalIK = (Get-ChildItem -Path "${env:APPDATA}\Unity\Asset Store-5.x" -Recurse "Final IK.unitypackage").FullName
        if ($finalIK) {
            $input = Read-Host "Copy 'Final IK.unitypackage' from ${finalIK} to current folder?(y/n)"
            if ($input -eq "y") {
                Copy-Item $finalIK $wrkdir -Force
            }
            else {
                exit
            }
        }
        else {
            echo "Not Found 'Final IK.unitypackage'. Please download from Asset Store"
            exit
        }
    }
}


function download() {
    New-Item -Path $srcdir -ItemType Directory -Force | Out-Null; cd $srcdir
    
    # Download VMC and assets
    foreach ($url in $source) {
        $conatent_disposition = curl.exe -sLI $url | Select-String -Pattern "^Content-Disposition"
        $filename = $conatent_disposition -replace '.*\bfilename=(.+)(?: |$)', '$1'
        $filename = if($filename -ne ''){ $filename }else{ Split-Path $url -leaf }
        
        echo "Downloading ${filename} from ${url}"
        curl.exe -L $url -o $filename
    }
    
    # Extract zip file
    $archives = Get-ChildItem -Name *.zip
    foreach($archive in $archives) {
        Expand-Archive -Path $archive -DestinationPath $srcdir
    }
    
    cd $wrkdir
}


function build() {
    # Copy unitypackage to project root directory
    $packages = Get-ChildItem -Recurse *.unitypackage
    Copy-Item $packages $prjpath -Force
    
    # Add BuildAssistant to project
    Copy-Item "BuildAssistant" "${prjpath}\Assets" -Recurse -Force
    
    # Backup ProjectSettings directory
    Copy-Item "${prjpath}\ProjectSettings" "${prjpath}\ProjectSettings.default" -Recurse -Force
    
    # Import packages
    echo "Import Packages ..."
    $unity_proc = Start-Process -FilePath $unity_editor -ArgumentList "-projectPath ${prjpath} -executeMethod BuildAssistant.ImportPackage" -PassThru
    $unity_proc.WaitForExit()
    
    # Fixed Layout
    $dirnames=@("RootMotion","SteamVR","VRM", "Oculus","uOSC","MidiJack")
    foreach ($dirname in $dirnames) {
        $asset = Get-ChildItem -Recurse -Directory $dirname | Sort-Object | Select-Object -First 1
        Move-Item $asset "${prjpath}\Assets\ExternalPlugins" -Force
    }
    Copy-Item "${prjpath}\UnityMemoryMappedFile" "${prjpath}\Assets\ExternalPlugins" -Recurse -Force
    
    # Remove-Item "${prjpath}\Assets\Scripts\LipTracking" -Recurse -Force
   Remove-Item "${prjpath}\Assets\Scripts\EyeTracking" -Recurse -Force
  
    $ColorPickerWPF = Get-ChildItem -Recurse -Directory "ColorPickerWPF-*"
    Copy-Item "${ColorPickerWPF}\*" "${prjpath}\ColorPickerWPF\" -Recurse -Force
    
    # Build Unity
    echo "VirtualMotionCapture Building ..."
    Copy-Item "${prjpath}\ProjectSettings.default\*" "${prjpath}\ProjectSettings\" -Recurse -Force
    Remove-Item "${prjpath}\Assets\BuildAssistant\BuildAssistant.asmdef" -Recurse -Force
    $unity_proc = Start-Process -FilePath $unity_editor -ArgumentList "-projectPath ${prjpath} -executeMethod BuildAssistant.Build" -PassThru
    $unity_proc.WaitForExit()
    
    # Build BetaMode VirtualMotionCaptureControlPanel
    echo "VirtualMotionCaptureControlPanel Building ..."
    $vs_proc = Start-Process -FilePath $msbuild -ArgumentList "${prjpath}\ControlWindowWPF /t:clean;rebuild /p:Configuration=${buildconfig}" -PassThru
    $vs_proc.WaitForExit()
}


function package() {
  $build_result = "${prjpath}\ControlWindowWPF\ControlWindowWPF\bin\${buildconfig}\*"
  Compress-Archive -Path $build_result -DestinationPath "${pkgname}${pkgver}.zip" -Force
}


check
download
build
package
