using ConfigManagement.Config;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System;
using System.IO;
using System.Threading.Tasks;

namespace ConfigManagement
{
    class OEProvider
    {
        private readonly CommandRunner _cmdRunner;
        private readonly CommonConfig _commonConfig;
        private readonly ILogger<OEProvider> _logger;

        public OEProvider(CommandRunner cmdRunner,
                          IOptions<CommonConfig> commonConfig,
                          ILogger<OEProvider> logger)
        {
            _cmdRunner = cmdRunner;
            _commonConfig = commonConfig.Value;
            _logger = logger;
        }

        public void RemoveDbFiles(string targetDbPath)
        {
            var db = Path.GetFileName(targetDbPath);
            var dir = Path.GetDirectoryName(targetDbPath);

            _cmdRunner.RunProcess(dir, "cmd.exe", $"/c del {db}*");
        }

        public void StopAppServer()
        {          
            _cmdRunner.RunProcess("C:\\", $"{_commonConfig.DLC}bin\\asbman.bat", $"-name {_commonConfig.AppServerName} -stop");
        }

        public void StartAppServer()
        {
            _cmdRunner.RunProcess("C:\\", $"{_commonConfig.DLC}bin\\asbman.bat", $"-name {_commonConfig.AppServerName} -start");
        }

        public void StopDatabase(string targetDbPath)
        {
            var dir = Path.GetDirectoryName(targetDbPath);

            _cmdRunner.RunProcess(dir, $"{_commonConfig.DLC}bin\\dbman.bat", $"-database {_commonConfig.DbPropsName} -stop");
        }

        public void StartDatabase(string targetDbPath)
        {
            var dir = Path.GetDirectoryName(targetDbPath);

            _cmdRunner.RunProcess(dir, $"{_commonConfig.DLC}bin\\dbman.bat", $"-database {_commonConfig.DbPropsName} -start");
        }

        public async Task WaitUntilDbUnlocked(string targetDbPath)
        {
            var dir = Path.GetDirectoryName(targetDbPath);
            var db = Path.GetFileNameWithoutExtension(targetDbPath);
            var i = 0;
            var lockFile = Path.Combine(dir, $"{db}.lk");

            do
            {
                i++;

                await Task.Delay(5000);
                if (i > 50)
                {
                    throw new TimeoutException("Database .lk file wasn't removed in time");
                }
                _logger.LogInformation($"{lockFile} file still exists... checked {i} times");

            } while (File.Exists(lockFile));
           
        }

        public async Task WaitUntilDbLocked(string targetDbPath)
        {
            var dir = Path.GetDirectoryName(targetDbPath);
            var db = Path.GetFileNameWithoutExtension(targetDbPath);
            var i = 0;
            var lockFile = Path.Combine(dir, $"{db}.lk");

            do
            {
                i++;

                await Task.Delay(2000);
                if (i > 30)
                {
                    throw new TimeoutException("Database .lk file wasn't created in time");
                }
                _logger.LogInformation($"{lockFile} file doesn't exist... checked {i} times");

            } while (!File.Exists(lockFile));

        }

        public string BackupSourceDatabase(string databaseFilePath, string backupFilename)
        {

            if (!File.Exists($"{databaseFilePath}.db"))
            {
                return null;
            }

            var db = Path.GetFileName(databaseFilePath);
            var dir = Path.GetDirectoryName(databaseFilePath);

            _cmdRunner.RunProcess(dir, $"{_commonConfig.DLC}bin\\probkup.bat", $"online {db} {backupFilename} -verbose -com -red 5");

            return Path.Combine(dir, backupFilename);

        }

        public void RestoreDatabase(string targetDbPath, string backupFilePath)
        {

            var db = Path.GetFileName(targetDbPath);
            var dir = Path.GetDirectoryName(backupFilePath);

            _cmdRunner.RunProcess(dir, $"{_commonConfig.DLC}bin\\_dbutil", $"prorest {db} {backupFilePath} -verbose");

        }

       
    }
}
