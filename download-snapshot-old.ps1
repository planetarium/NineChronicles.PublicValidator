if ($args.Length -lt 2) {
	Write-Error "'baseUrl' and 'file_path' arguments are required.";
	exit -1;
}

$baseUrl = $args[0]
$file_path = $args[1]
$latest = "$($baseUrl)latest.json"
$latestState = "$($baseUrl)state_latest.zip"

echo "Clear existing store path"
# Remove-Item $file_path -Recurse -Force

$epoch = Invoke-WebRequest $latest |
ConvertFrom-Json |
Select BlockEpoch, TxEpoch, PreviousBlockEpoch, PreviousTxEpoch

$myarray = [System.Collections.ArrayList]::new()
[void]$myarray.Add($epoch)

echo "Calculating total amount of snapshots to download."

while($true)
{
	$nextEpochMeta = "$($baseUrl)snapshot-$($epoch.PreviousBlockEpoch)-$($epoch.PreviousTxEpoch).json"
	$epoch = Invoke-WebRequest $nextEpochMeta |
		ConvertFrom-Json |
		Select BlockEpoch, TxEpoch, PreviousBlockEpoch, PreviousTxEpoch
	[void]$myarray.Add($epoch)
	if( 0 -eq $epoch.PreviousBlockEpoch )
	{
		break;
	}
}

echo "Calculate finish. Number of $($myarray.count) snapshot download start."
foreach($currentEpoch in $myarray) {
	$filename = "snapshot-$($currentEpoch.BlockEpoch)-$($currentEpoch.TxEpoch).zip"
	echo "Download $($filename)."
	$nextsnapshot = "$($baseUrl)$($filename)"
	Invoke-WebRequest -Uri $nextsnapshot -Outfile $filename -Resume
}

$filename = "state_latest.zip"
echo "Download State."
Invoke-WebRequest -Uri  $latestState -Outfile $filename -Resume

echo "Download finish. snapshot extracting start."
$myarray.Reverse()

foreach($currentEpoch in $myarray) {
	$filename = "snapshot-$($currentEpoch.BlockEpoch)-$($currentEpoch.TxEpoch).zip"
	echo "Extract $($filename)."
	Expand-Archive -Path $filename -DestinationPath $file_path -Force
}

$filename = "state_latest.zip"
echo "Extract State."
Expand-Archive -Path $filename -DestinationPath $file_path -Force

echo "Extract finish. all snapshot download finish"

# Remove-Item "*.zip"