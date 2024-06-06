# Function to calculate SHA-256 hash of a file
function Get-FileHashSHA256 {
    param (
        [string]$filePath
    )
    # Open the file stream and compute the hash
    $stream = [System.IO.File]::OpenRead($filePath)
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $hash = $hasher.ComputeHash($stream)
    $stream.Close()

    # Convert the byte array to a hexadecimal string
    $hashString = [BitConverter]::ToString($hash) -replace '-', ''
    return $hashString
}

# Function to move files containing "- Copy" to "Copy Files" folder in C:\
function Move-CopyFiles {
    param (
        [string]$filePath
    )
    # Check if the file contains "- Copy" in its filename
    if ($filePath -like "*- Copy*") {
        $copyFilesFolderPath = "C:\Copy Files"

        # Check if "Copy Files" folder already exists in C:\
        if (-not (Test-Path -Path $copyFilesFolderPath -PathType Container)) {
            # Create "Copy Files" folder in C:\
            $null = New-Item -Path $copyFilesFolderPath -ItemType Directory
        }

        # Move the file to "Copy Files" folder
        $fileName = Split-Path -Leaf $filePath
        $destinationPath = Join-Path -Path $copyFilesFolderPath -ChildPath $fileName
        Move-Item -Path $filePath -Destination $destinationPath -Force
    }
}

# Prompt the user to enter a folder path
$folderPath = Read-Host "Please enter the folder path to scan for duplicates"

# Check if the entered path is valid
if (-Not (Test-Path -Path $folderPath -PathType Container)) {
    Write-Host "The folder path you entered does not exist. Please run the script again with a valid path."
    exit
}

# Hashtable to store hashes and their corresponding file paths
$hashTable = @{}

# Recursively get all files in the folder
$files = Get-ChildItem -Path $folderPath -Recurse -File

foreach ($file in $files) {
    # Calculate the SHA-256 hash of the file
    $hash = Get-FileHashSHA256 -filePath $file.FullName

    # Check if the hash already exists in the hashtable
    if ($hashTable.ContainsKey($hash)) {
        # If it exists, add the current file path to the list of duplicates
        $hashTable[$hash] += $file.FullName
    } else {
        # If it doesn't exist, create a new list with the current file path
        $hashTable[$hash] = @($file.FullName)
    }
}

# Iterate through the hashtable to find and display duplicates
$firstSet = $true
foreach ($hash in $hashTable.Keys) {
    if ($hashTable[$hash].Count -gt 1) {
        if (-not $firstSet) {
            Write-Host ""
        }
        $firstSet = $false
        Write-Host "Duplicate files with hash $hash:"
        foreach ($filePath in $hashTable[$hash]) {
            Write-Host $filePath
            # Move files containing "- Copy" to "Copy Files" folder in C:\
            Move-CopyFiles -filePath $filePath
        }
    }
}

# If no duplicates were found, inform the user
if ($firstSet) {
    Write-Host "No duplicate files found."
}
