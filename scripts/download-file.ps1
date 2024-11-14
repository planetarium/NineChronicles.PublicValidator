param(
    [Parameter(Mandatory = $true)]
    [Uri]$Url,
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$OutputPath
)

$name = Split-Path -Path $Url.PathAndQuery -Leaf
$fileUrl = $Url
$filePath = Join-Path $OutputPath "$name"
$downloadDirectory = Join-Path $OutputPath "downloads"
$trashDirectory = Join-Path $OutputPath "trash"
$infoDirectory = Join-Path $OutputPath "infos"
$downloadPath = Join-Path $downloadDirectory "$name.temp"
$infoPath = Join-Path $infoDirectory "$name.head.json"

if (!(Test-Path -Path $downloadDirectory -PathType Container)) {
    $downloadDirectory = New-Item -Path $downloadDirectory -ItemType Directory
}
if (!(Test-Path -Path $trashDirectory -PathType Container)) {
    $trashDirectory = New-Item -Path $trashDirectory -ItemType Directory
}
if (!(Test-Path -Path $infoDirectory -PathType Container)) {
    $infoDirectory = New-Item -Path $infoDirectory -ItemType Directory
}
$trashPath = Join-Path $trashDirectory "$name"

if (Test-Path -Path $infoPath -PathType Leaf) {
    $info = Get-Content -Path $infoPath | ConvertFrom-Json -AsHashtable
}
else {
    $info = @{
        Length = 0
        LastWriteTime = $null
        ETag = ""
    }
}
$info.Length = $info.Length ? $info.Length : 0
$info.LastWriteTime = $info.LastWriteTime ? (Get-Date $info.LastWriteTime) : $null
$info.ETag = $info.ETag ? $info.ETag : ""

if (Test-Path -Path $filePath -PathType Leaf) {
    if ($info.Length -ne (Get-Item -Path $filePath).Length) {
        Move-Item -Path $filePath -Destination $trashPath
        $info.Length = 0
        $info.Etag = ""
    }
    elseif ($info.LastWriteTime -ne (Get-Item -Path $filePath).LastWriteTime) {
        Move-Item -Path $filePath -Destination $trashPath
        $info.LastWriteTime = $null
        $info.Etag = ""
    }
}

if (Test-Path -Path $downloadPath -PathType Leaf) {
    Invoke-WebRequest -Uri $fileUrl -OutFile $downloadPath -Resume
    Move-Item -Path $downloadPath -Destination $filePath
}
elseif (!(Test-Path -Path $filePath -PathType Leaf)) {
    Invoke-WebRequest -Uri $fileUrl -OutFile $downloadPath
    Move-Item -Path $downloadPath -Destination $filePath
}

if (!$info.Length) {
    $info.Length = (Get-Item -Path $filePath).Length
    $modified = $true
}

if (!$info.LastWriteTime) {
    $info.LastWriteTime = (Get-Item -Path $filePath).LastWriteTime
    $modified = $true
}

if (!$info.ETag) {
    $head = Invoke-WebRequest -Uri $fileUrl -Method HEAD
    $info.ETag = ($head.BaseResponse.Headers.Etag.Tag).Trim("`"")
    $modified = $true
}

if (Test-Path -Path $trashPath -PathType Leaf) {
    Remove-Item -Path $trashPath
}
    
if ($modified) {
    Set-Content -Path $infoPath -Value ($info | ConvertTo-Json)
}

$filePath
