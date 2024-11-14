param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$SnapshotPath,
    [string]$OutputPath = "store"
)

function ExtractZip {
    param(
        [string]$Name
    ) 

    $zipName = "$Name.zip"
    $zipOutputPath = Join-Path -Path $SnapshotPath -ChildPath $zipName
    Expand-Archive -Path $zipOutputPath -DestinationPath $OutputPath -Force
}

$OutputPath = New-Item $OutputPath -ItemType Directory -Force -ErrorAction SilentlyContinue

if (Test-Path -Path $OutputPath -PathType Container) {
    $items = Get-ChildItem -Path $OutputPath
    if ($items.Length -gt 0) {
        throw "Outputpath must be non-existent or empty directory."
    }
}

$epoches = @()
$epoch = Get-Content -Path (Join-Path $SnapshotPath "latest.json") | ConvertFrom-Json -AsHashtable
$epochName = "snapshot-$($epoch.BlockEpoch)-$($epoch.TxEpoch)"

$epoches += "state_latest"

while ($epoch.PreviousBlockEpoch -ne 0) {
    Write-Host $epochName
    $epochPath = Join-Path $SnapshotPath "$epochName.json"
    $epoch = Get-Content -Path $epochPath | ConvertFrom-Json -AsHashtable
    $epoches += $epochName
    $epochName = "snapshot-$($epoch.PreviousBlockEpoch)-$($epoch.PreviousBlockEpoch)"
}

for ($i = $epoches.Length - 1; $i -ge 0; $i--) {
    $item = $epoches[$i]
    Write-Host "Extracting: $item"
    ExtractZip($epoches[$i])
    Write-Host "Extracted: $item"
}
