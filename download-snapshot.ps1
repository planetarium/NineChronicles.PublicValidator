param(
    [Parameter(Mandatory = $true)]
    [Uri]$Url,
    [string]$OutputPath = "snapshots"
)

function DownloadEpoch {
    param(
        [string]$Name
    )

    Write-Host "Fetching: $Name"
    $jsonName = "$Name.json"
    $jsonUrl = "$($baseUrl)$jsonName"
    $jsonOutputPath = ./scripts/download-file.ps1 -Url $jsonUrl -OutputPath $OutputPath

    $epoch = Get-Content -Path $jsonOutputPath | ConvertFrom-Json
    $epoch | Select-Object -Property BlockEpoch, TxEpoch, PreviousBlockEpoch, PreviousTxEpoch
    Write-Host "Fetched: $Name"
}

function DownloadZip {
    param(
        [string]$Name
    )

    $zipName = "$Name.zip"
    $zipUrl = "$($baseUrl)$zipName"
    ./scripts/download-file.ps1 -Url $zipUrl -OutputPath $OutputPath
}

function ExtractZip {
    param(
        [string]$Name
    ) 

    Write-Host "Downloading: $Name"
    $zipName = "$Name.zip"
    $zipOutputPath = Join-Path -Path $OutputPath -ChildPath $zipName
    Expand-Archive -Path $zipOutputPath -DestinationPath $OutputPath -Force
    Write-Host "Downloaded: $Name"
}

$baseUrl = $Url[-1] -eq '/' ? $Url : [Uri]"$Url/"
$OutputPath = New-Item $OutputPath -ItemType Directory -Force -ErrorAction SilentlyContinue

$epoches = @()
$epochName = "latest"
$epoch = DownloadEpoch -Name $epochName
$epochName = "snapshot-$($epoch.BlockEpoch)-$($epoch.TxEpoch)"

$epoches += "state_latest"

while ($epoch.PreviousBlockEpoch -ne 0) {
    
    $epoch = DownloadEpoch -Name $epochName
    $epoches += $epochName
    $epochName = "snapshot-$($epoch.PreviousBlockEpoch)-$($epoch.PreviousBlockEpoch)"
}

for ($i = 0; $i -lt $epoches.Length; $i++) {
    $item = $epoches[$i]
    DownloadZip -Name $item
}
