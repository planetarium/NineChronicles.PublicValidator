# Public Validator for NineChronicles

Provides the necessary environment to run the Validator of NineChronicles
and participate in consensus.

## Requirements

* [.NET 8.0](https://dotnet.microsoft.com/download/dotnet/8.0)
* [PowerShell 7.4.x](https://github.com/PowerShell/PowerShell/releases/tag/v7.4.6)
* Approximately 580 GB of free storage space 
  * Snapshots: 260 GB
  * Store: 320 GB
* The private key to use when participating as a Validator

## Clone

```bash
git clone https://github.com/planetarium/NineChronicles.PublicValidator.git --recurse
cd NineChronicles.PublicValidator
```

## Build

```bash
dotnet build headless
```

### Generate PrivateKey

```powershell
pwsh generate-key.ps1
```

### Download snapshots

```powershell
pwsh download-snapshot.ps1 https://snapshots.nine-chronicles.com/9c-dev-v2 snapshots
```

### Extract snaphosts

```powershell
pwsh extract-snapshot.ps1 snapshots store
```

### Run Validator

```powershell
pwsh run-validator.ps1 <private-key> <fixed-ip-address> store
```
