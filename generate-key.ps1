<#
.SYNOPSIS
  Creates a PrivateKey
.DESCRIPTION
  Creates a PrivateKey and Returns the PrivateKey, PublicKey, and Address as a Hashtable.
  To get the values as json, you can use ConvertTo-Json.
.OUTPUTS
  Returns a Hashtable with the following keys:
  - PrivateKey: The PrivateKey
  - PublicKey: The PublicKey
  - Address: The Address
.EXAMPLE
  .\generate-key.ps1
  # This command generates a private key, public key, and address, and outputs them as a hashtable.
.EXAMPLE
  .\generate-key.ps1 | ConvertTo-Json
  # This command generates a private key, public key, and address, and converts the output to JSON format.
#>

$projectPath = Join-Path "headless" "Lib9c" ".Libplanet" "tools" "Libplanet.Tools"
$expression = "dotnet run --project `"$projectPath`" -- key generate --public-key"
$line = Invoke-Expression $expression 2>$null

$items = $line -split " "
@{
  "PrivateKey" = $items[0]
  "PublicKey"  = $items[2]
  "Address"    = $items[1]
}
