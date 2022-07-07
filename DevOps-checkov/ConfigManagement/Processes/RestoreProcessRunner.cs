using ConfigManagement.Config;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading.Tasks;

namespace ConfigManagement.Backup
{
    class RestoreProcessRunner : IProcessRunner
    {
        private readonly OEProvider _oEProvider;
        private readonly DatabaseHandler _dbFileHandler;
        private readonly CommonConfig _config;
        private readonly ILogger<RestoreProcessRunner> _logger;

        public RestoreProcessRunner(OEProvider oEProvider,
                                    DatabaseHandler dbFileHandler,
                                    IOptions<CommonConfig> config,
                                    ILogger<RestoreProcessRunner> logger)
        {
            _oEProvider = oEProvider;
            _dbFileHandler = dbFileHandler;
            _config = config.Value;
            _logger = logger;
        }

        public async Task Begin(string bkupFilename)
        {

            _logger.LogInformation($"Beginning Restore Process...");

            try
            {               
                if (await _dbFileHandler.CheckIfBackupExists(bkupFilename))
                {
                    if (_config.UseAppServer && !string.IsNullOrEmpty(_config.AppServerName))
                    {
                        _logger.LogInformation($"Stopping AppServer ${_config.AppServerName}...");
                        _oEProvider.StopAppServer();
                    }
                    _logger.LogInformation($"Performing download of OE database backup...");
                    var restoredBackup = await _dbFileHandler.DownloadBackup(bkupFilename, Path.GetDirectoryName(_config.OESourceDbPath));
                    _logger.LogInformation($"Downloaded backup to {restoredBackup}");

                    _logger.LogInformation($"Making temp backup of {_config.OESourceDbPath}...");
                    var tempbkup = _oEProvider.BackupSourceDatabase(_config.OESourceDbPath, "tmp_soldb.bkup");
                    if (tempbkup != null)
                    {
                        _logger.LogInformation($"Performing restore of OE database from backup...");

                        _oEProvider.StopDatabase(_config.OESourceDbPath);
                        await _oEProvider.WaitUntilDbUnlocked(_config.OESourceDbPath);

                        _oEProvider.RemoveDbFiles(_config.OESourceDbPath);

                        _oEProvider.RestoreDatabase(_config.OESourceDbPath, restoredBackup);

                        _oEProvider.StartDatabase(_config.OESourceDbPath);
                        await _oEProvider.WaitUntilDbLocked(_config.OESourceDbPath);

                        _oEProvider.RemoveDbFiles(tempbkup);
                        _oEProvider.RemoveDbFiles(restoredBackup);
                        //  await _dbFileHandler.DeleteBackup(bkupFilename);
                    }
                    if (_config.UseAppServer && !string.IsNullOrEmpty(_config.AppServerName))
                    {
                        _logger.LogInformation($"Starting AppServer ${_config.AppServerName}...");
                        _oEProvider.StartAppServer();
                    }

                    _logger.LogInformation("Restore Process completed successfully");
                }
                _logger.LogInformation($"Restoring Azure Tables...");
                await _dbFileHandler.RestoreAzureTables(_config.AzureStorage);

            }
            catch(Exception ex)
            {
                _logger.LogCritical("Restore Process Failed:" + ex.Message, ex);
                throw ex;
            }
        }
    }
}
