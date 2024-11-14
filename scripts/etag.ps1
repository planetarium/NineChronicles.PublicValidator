param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$Path,
    [ValidateScript({ $_ -gt 0 })]
    [int]$PartSizeMB = 8
)

$length = Get-Item -Path $Path | Select-Object -ExpandProperty Length
$partSizeBytes = $PartSizeMB * 1024 * 1024
$expectedPartCount = [math]::Ceiling($length / $partSizeBytes)

if ($expectedPartCount -gt 1) {
    $fileStream = [System.IO.File]::OpenRead($Path)
    $buffer = New-Object byte[] $partSizeBytes
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $stringAsStream = [System.IO.MemoryStream]::new()

    try {
        for ($i = 0; $i -lt $expectedPartCount; $i++) {
            $progressInfo = @{
                Activity        = "Part #$i" 
                Status          = "Computing Hash ..."
                PercentComplete = $i / $expectedPartCount * 100
            }
            Write-Progress @progressInfo
            $bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)
            if ($bytesRead -le 0) { break }

            $hash = $md5.ComputeHash($buffer, 0, $bytesRead)
            $stringAsStream.Write($hash, 0, $hash.Length)
            Start-Sleep -Milliseconds 250
        }
    } 
    finally {
        Write-Progress -Completed
    }

    $fileStream.Close()
    $stringAsStream.Position = 0
    $fileHash = Get-FileHash -InputStream $stringAsStream -Algorithm MD5
    $stringAsStream.Close()
    $hash = $fileHash.Hash.ToLower()
    $expectedPartCount -ge 2 ? "$hash-$expectedPartCount" : $hash
}
else {
    $fileHash = Get-FileHash -Path $Path -Algorithm MD5
    $fileHash.Hash.ToLower()
}
