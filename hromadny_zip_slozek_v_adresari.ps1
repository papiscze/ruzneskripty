# hromadný zip složek v adresáři pomocí 7zip
# Zeptáme se na výchozí složku obsahující podsložky
$SourceFolder = Read-Host "Zadejte cestu ke složce obsahující podsložky" 

# Zeptáme se na složku, kam se mají ukládat vytvořené ZIP archivy
$DestinationFolder = Read-Host "Zadejte cestu, kam se mají ukládat vytvořené ZIP archivy" 

# Cesta k 7-Zip
$SevenZipPath = "D:\Program Files\7-Zip\7z.exe"  # Změň podle své cesty k 7z.exe

# Ujistěte se, že cílová složka existuje, jinak ji vytvořte
if (!(Test-Path -Path $DestinationFolder)) {
    New-Item -ItemType Directory -Path $DestinationFolder
}

# Procházení všech podsložek ve zdrojové složce
Get-ChildItem -Path $SourceFolder -Directory | ForEach-Object {
    $FolderName = $_.Name
    $FolderPath = $_.FullName
    $FolderNameSanitized = $FolderName -replace '[^a-zA-Z0-9_-]', '_'
    $ZipPath = Join-Path -Path $DestinationFolder -ChildPath "$FolderNameSanitized.zip"

    # Debug informace
    Write-Host "Zpracovávám složku: $FolderPath"
    Write-Host "Výstupní ZIP: $ZipPath"

    # Komprese přes 7-Zip
    try {
        & "$SevenZipPath" a -tzip "$ZipPath" "$FolderPath\*" -r
        if (Test-Path -Path $ZipPath) {
            Write-Host "Složka '$FolderName' byla úspěšně zazipována do '$ZipPath'."
        } else {
            Write-Host "ZIP soubor '$ZipPath' nebyl vytvořen."
        }
    } catch {
        Write-Host "Chyba při zipování složky '$FolderName': $($_.Exception.Message)"
    }
}

Write-Host "Hotovo!"
