$ResourceBaseName = 'umbraco9';
$Location = 'eastus';
$GroupName = "$($ResourceBaseName)-rg";

$AppServicePlanName = "$($ResourceBaseName)-asp";
Write-Host "Enter web app name (has to be globally unique, will be used as subdomain xxx.azurewebsites.net)";
$AppServiceName = Read-Host "(name has to be globally unique, can only contain lowercase characters, numbers, and dashes)";

Write-Host "Enter sql server name (has to be globally unique, will be used as subdomain xxx.database.windows.net)";
$SqlServerName = Read-Host "(name has to be globally unique, can only contain lowercase characters, numbers, and dashes)";
$SqlDbName = "$($ResourceBaseName)-sqldb";
$SqlAdminUser = "SqlAdmin";
$SqlAdminPwd = Read-Host -AsSecureString "Enter a password for Sql Server admin";

az config set --local `
    defaults.group=$GroupName `
    defaults.location=$Location `
    defaults.appserviceplan=$AppServicePlanName `
    defaults.web=$AppServiceName;

az group create --location $Location --resource-group $GroupName;

az sql server create `
    --location $Location `
    --resource-group $GroupName `
    --name $SqlServerName `
    --admin-user $SqlAdminUser `
    --admin-password $($SqlAdminPwd | ConvertFrom-SecureString -AsPlainText);

az sql db create `
    --server $SqlServerName `
    --name $SqlDbName;

# this allows Azure services to communicate with the Sql Server (there are more secure alternatives)
az sql server firewall-rule create `
    --resource-group $GroupName `
    --server $SqlServerName `
    --name AllowAzureServices `
    --start-ip-address 0.0.0.0 `
    --end-ip-address 0.0.0.0;

$ConnectionString = $(az sql db show-connection-string `
    --server $SqlServerName `
    --name $SqlDbName `
    --client ado.net `
    --auth-type SqlPassword) `
    -replace "<username>",$SqlAdminUser -replace "<password>",$($SqlAdminPwd | ConvertFrom-SecureString -AsPlainText) `
    | ConvertTo-SecureString -AsPlainText;

az appservice plan create `
    --location $Location `
    --resource-group $GroupName `
    --name $AppServicePlanName `
    --is-linux;

az webapp create `
    --name $AppServiceName `
    --plan $AppServicePlanName `
    --runtime '"DOTNET|5.0"'; #'" and "' is used to escape the | character in PowerShell

az webapp config connection-string set `
    --resource-group $GroupName `
    --name $AppServiceName `
    --settings umbracoDbDSN=$($ConnectionString | ConvertFrom-SecureString -AsPlainText) `
    --connection-string-type SQLAzure;