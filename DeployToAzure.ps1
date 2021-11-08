If (Test-Path -Path './publish') {
    Remove-Item -Path './publish' -Recurse;
}
If (Test-Path -Path './publish.zip') {
    Remove-Item -Path './publish.zip' -Recurse;
}

dotnet publish . -c Release -o publish;
Compress-Archive -Path publish/* -DestinationPath publish.zip;
az webapp deploy `
    --clean true `
    --restart true `
    --src-path publish.zip `
    --type zip;