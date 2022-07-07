using ConfigManagement.Config;
using LexisNexis.Visualfiles.Ng.Azure.Storage.Blob;
using LexisNexis.Visualfiles.Ng.Azure.Storage.Table;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System;
using System.IO;
using System.Threading.Tasks;
using static ConfigManagement.Config.CommonConfig;

namespace ConfigManagement
{
    class DatabaseHandler
    {
        private readonly IAzureBlobStorageService _azureBlobStorageService;
        private readonly IAzureTableStorageService _azureTableStorageService;
        private readonly CommandRunner _cmdRunner;
        private readonly CommonConfig _config;
        private readonly ILogger<DatabaseHandler> _logger;

        public DatabaseHandler(IAzureBlobStorageService azureBlobStorageService,
                               IAzureTableStorageService azureTableStorageService,
                               CommandRunner cmdRunner,
                               IOptions<CommonConfig> commonConfig,
                               ILogger<DatabaseHandler> logger)
        {
            _azureBlobStorageService = azureBlobStorageService;
            _azureTableStorageService = azureTableStorageService;
            _cmdRunner = cmdRunner;
            _config = commonConfig.Value;
            _logger = logger;
        }

        
        public async Task UploadBackup(string backupFilePath)
        {
            if (!File.Exists(backupFilePath))
            {
                throw new FileNotFoundException("Provided backup file does not exist");
            }

            try
            {
                using (var fileStream = new FileStream(backupFilePath, FileMode.Open))
                {
                    await _azureBlobStorageService.UploadStreamAsync(fileStream, Path.GetFileName(backupFilePath));
                }
            }
            catch(Exception ex)
            {
                _logger.LogError("Upload failed: " + ex.Message, ex);
                throw;
            }
        }

        public async Task<string> DownloadBackup(string filename, string restorePath)
        {
            if (!Directory.Exists(restorePath))
            {
                Directory.CreateDirectory(restorePath);
            }

            string restoreFilename = $"{restorePath}\\{filename}";

            try
            {
                using (var stream = await _azureBlobStorageService.DownloadStreamAsync(filename))
                using (var fileStream = new FileStream(restoreFilename, FileMode.OpenOrCreate))
                {
                    stream.CopyTo(fileStream);
                }
       
            }
            catch (Exception ex)
            {
                _logger.LogError("Download failed: " + ex.Message, ex);
                throw;
            }

            return restoreFilename;
        }

        public async Task DeleteBackup(string filename) 
        {
            try
            {
                await _azureBlobStorageService.DeleteAsync(filename);
            }
            catch (Exception ex)
            {
                _logger.LogWarning("Could not delete backup file: " + ex.Message, ex);
            }
        }

        public async Task<bool> CheckIfBackupExists(string filename)
        {
            return await _azureBlobStorageService.CheckExistsAsync(filename);
        }

        public void BackupAzureTables(AzureStorageConfig azureTablesConfig)
        {
            if (!File.Exists($"{azureTablesConfig.AzCopyLocation}\\AzCopy.exe"))
            {
                _logger.LogError("AzCopy is not installed.  Install version 7.3: https://aka.ms/downloadazcopynet");
                throw new InvalidOperationException();
            }

            if (azureTablesConfig.SourceConnectionString == null || azureTablesConfig.StagingConnectionString == null)
            {
                _logger.LogError("Cannot locate ConnectionStrings.  Ensure configuration is setup correctly");
                throw new InvalidOperationException();
            }

            var sourceKey = azureTablesConfig.SourceConnectionString.Split(';')[2].Split("AccountKey=")[1];
            var sourceName = azureTablesConfig.SourceConnectionString.Split(';')[1].Split("AccountName=")[1];
            var targetKey = azureTablesConfig.StagingConnectionString.Split(';')[2].Split("AccountKey=")[1];
            var targetName = azureTablesConfig.StagingConnectionString.Split(';')[1].Split("AccountName=")[1];

            try
            {

                foreach (var table in azureTablesConfig.Tables)
                {
                    var sourceTableUrl = $"https://{sourceName}.table.core.windows.net/{table}";
                    var targetBlobUrl = $"https://{targetName}.blob.core.windows.net/qaconfmgmt";

                    _cmdRunner.RunProcess(null, $"\"{azureTablesConfig.AzCopyLocation}\\AzCopy.exe\"", $"/Source:{sourceTableUrl} /SourceKey:{sourceKey} /Dest:{targetBlobUrl} /DestKey:{targetKey} /Manifest:{table}.manifest /Y");
                   
                }
            }
            catch(Exception ex)
            {
                _logger.LogError("AzCopy failed", ex);
            }

        }

        public async Task RestoreAzureTables(AzureStorageConfig azureTablesConfig)
        {
            if (!File.Exists($"{azureTablesConfig.AzCopyLocation}\\AzCopy.exe"))
            {
                _logger.LogError("AzCopy is not installed.  Install version 7.3: https://aka.ms/downloadazcopynet");
                throw new InvalidOperationException();
            }

            if (azureTablesConfig.TargetConnectionString == null || azureTablesConfig.StagingConnectionString == null)
            {
                _logger.LogError("Cannot locate ConnectionStrings.  Ensure configuration is setup correctly");
                throw new InvalidOperationException();
            }

            var sourceKey = azureTablesConfig.StagingConnectionString.Split(';')[2].Split("AccountKey=")[1];
            var sourceName = azureTablesConfig.StagingConnectionString.Split(';')[1].Split("AccountName=")[1];
            var targetKey = azureTablesConfig.TargetConnectionString.Split(';')[2].Split("AccountKey=")[1];
            var targetName = azureTablesConfig.TargetConnectionString.Split(';')[1].Split("AccountName=")[1];

            try
            {

                foreach (var table in azureTablesConfig.Tables)
                {
                    var sourceTableUrl = $"https://{sourceName}.blob.core.windows.net/qaconfmgmt";
                    var targetBlobUrl = $"https://{targetName}.table.core.windows.net/{table}";

                    await _azureTableStorageService.ClearTable(table);
                    _cmdRunner.RunProcess(null, $"\"{azureTablesConfig.AzCopyLocation}\\AzCopy.exe\"", $"/Source:{sourceTableUrl} /SourceKey:{sourceKey} /Dest:{targetBlobUrl} /DestKey:{targetKey} /Manifest:{table}.manifest /EntityOperation:InsertOrReplace /Y");
                  
                }
            }
            catch (Exception ex)
            {
                _logger.LogError("AzCopy failed", ex);
            }

        }

    }
}
