using ConfigManagement.Config;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System;
using System.IO;
using System.Threading.Tasks;

namespace ConfigManagement.Processes
{
    class BackupProcessRunner : IProcessRunner
    {
        private readonly OEProvider _oEProvider;
        private readonly DatabaseHandler _dbFileHandler;
        private readonly CommonConfig _config;
        private readonly ILogger<BackupProcessRunner> _logger;

        public BackupProcessRunner(OEProvider oEProvider,
                                   DatabaseHandler dbFileHandler,
                                   IOptions<CommonConfig> config,
                                   ILogger<BackupProcessRunner> logger)
        {
            _oEProvider = oEProvider;
            _dbFileHandler = dbFileHandler;
            _config = config.Value;
            _logger = logger;
        }

        public async Task Begin(string bkupFilename)
        {

            _logger.LogInformation($"Beginning Backup Process...");

            try
            {
                _logger.LogInformation($"Performing online backup OE database: {_config.OESourceDbPath}...");
              
                var backupFile = _oEProvider.BackupSourceDatabase(_config.OESourceDbPath, bkupFilename);

                _logger.LogInformation($"Backup complete");

                if (File.Exists(backupFile))
                {
                    _logger.LogInformation($"Uploading backup: {backupFile}...");
                    await _dbFileHandler.UploadBackup(backupFile);
                    _logger.LogInformation($"Upload complete");
                }

                _logger.LogInformation($"Transferring Azure Tables...");
                 _dbFileHandler.BackupAzureTables(_config.AzureStorage);

                _logger.LogInformation("Backup Process completed successfully");
            }
            catch
            {
                _logger.LogCritical("Backup Process Failed.");
                throw;
            }
        }
    }
}
