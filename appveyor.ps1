# run the build script
$scriptDir = split-path -parent $MyInvocation.MyCommand.Definition

[System.IO.FileInfo]$buildFile = (Join-Path $scriptDir 'build.ps1')

<#
try{
    if($env:APPVEYOR_REPO_BRANCH -eq 'release' -and ([string]::IsNullOrWhiteSpace($env:APPVEYOR_PULL_REQUEST_NUMBER) )) {
        . $buildFile.FullName -publishToNuget
    }
    else{
        . $buildFile.FullName
    }
    
}
catch{
    throw ( 'Build error {0} {1}' -f $_.Exception, (Get-PSCallStack|Out-String) )
}
#>

$channelList = @('future','preview',$null)
$feedList = 'https://dotnet.myget.org/f/dotnet-cli','https://api.nuget.org/v3/index.json'
$installUrlList = 'https://raw.githubusercontent.com/dotnet/cli/rel/1.0.0/scripts/obtain/install.ps1','https://raw.githubusercontent.com/sayedihashimi/cli/issue2236/scripts/obtain/install.ps1'
$originalPath = $env:Path

foreach($installUrl in $installUrlList){
    # rest path to original
    'Trying with installer from [{0}]' -f $installUrlList | Write-Host
    try{
        $installdir = "$env:LOCALAPPDATA\Microsoft\dotnet"
        if(Test-Path $installdir){
            Remove-Item $installdir -Recurse
        }

        #$env:path = $originalPath
        #. $buildFile.FullName -installOnly -dotnetInstallChannel $channel

        foreach($channel in $channelList){
            $env:path = $originalPath
            @'
 ****
 **** Installing
 ****   - url    ={0}
 ****   - channel={1}
 ****
'@ -f $installUrl,$channel | Write-Host -ForegroundColor Green
            . $buildFile.FullName -installOnly -dotnetNugetFeedSource $channel -dotnetInstallUrl $installUrl

            foreach($feed in $feedList){
                try{
@'
 >>
 >> Trying build with 
 >>    - channel={0}
 >>    - nugeturl={1}
 >>    - installUrl={2}
 >>
'@ -f $channel,$feed,$installUrl | Write-Host -ForegroundColor Green
                    . $buildFile.FullName -dotnetNugetFeedSource $feed -SkipInstallDotNet -onlyBuildDOtnetProjects
                }
                catch{
                    ( 'Build error {0} {1}' -f $_.Exception, (Get-PSCallStack|Out-String) ) | Write-Warning
                }
            }
        }
    }
    catch{
        'Unable to install from url [{0}]. Error: {1}' -f $installUrl,$_.Exception | Write-Warning
    }
}

