using ConfigManagement.Backup;
using ConfigManagement.Config;
using ConfigManagement.Processes;
using LexisNexis.Visualfiles.Ng.Azure.Storage.Blob;
using LexisNexis.Visualfiles.Ng.Azure.Storage.Table;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Threading.Tasks;

namespace ConfigManagement
{
    enum Mode
    {
        Unknown,
        Backup,
        Restore
    }

    class Program
    {
        private static IConfigurationRoot _configuration;
        private static Mode _runMode;

        static void Main(string[] args)
        {
            // Set up configuration sources.
            var builder = new ConfigurationBuilder()
                .SetBasePath(Path.Combine(AppContext.BaseDirectory))
                .AddJsonFile("appsettings.json", optional: true)
                .AddUserSecrets<Program>()
                .AddCommandLine(args);

            _configuration = builder.Build();

            var stagingConnectionString = _configuration.GetValue<string>("CommonConfig:AzureStorage:StagingConnectionString");
            string targetAzTableConnectionString = null;

            if (string.Equals(_configuration["CommonConfig:Mode"], "backup", StringComparison.OrdinalIgnoreCase))
            {
                _runMode = Mode.Backup;
                targetAzTableConnectionString = stagingConnectionString;
            }
            else if (string.Equals(_configuration["CommonConfig:Mode"], "restore", StringComparison.OrdinalIgnoreCase))
            {
                _runMode = Mode.Restore;
                targetAzTableConnectionString = _configuration.GetValue<string>("CommonConfig:AzureStorage:TargetConnectionString");
            }

            IServiceCollection services = new ServiceCollection();
            var loggerFactory = LoggerFactory.Create(builder => builder.AddConsole());
            ILogger logger = loggerFactory.CreateLogger<Program>();

            services.AddLogging(configure => configure.AddConsole());

            switch (_runMode)
            {
                case Mode.Backup:
                    services.AddSingleton<IProcessRunner, BackupProcessRunner>();
                    break;
                case Mode.Restore:
                    services.AddSingleton<IProcessRunner, RestoreProcessRunner>();
                    break;
                default:
                    logger.LogCritical("Invalid Mode specified");
                    throw new InvalidOperationException();
            }

            services.Configure<CommonConfig>(options => _configuration.GetSection("CommonConfig").Bind(options));
            services.AddSingleton(options => new BlobStorageConfig()
            {
                ConnectionString = stagingConnectionString,
                Container = "qaconfmgmt"
            });
            services.AddSingleton<DatabaseHandler>();
            services.AddSingleton<OEProvider>();
            services.AddSingleton<CommandRunner>();
            services.AddSingleton<IAzureBlobStorageService, AzureBlobStorageService>();
            services.AddSingleton<IAzureTableStorageService>(p => new AzureTableStorageService(targetAzTableConnectionString));
                        
            var serviceProvider = services.BuildServiceProvider();

            var runner = serviceProvider.GetService<IProcessRunner>();
            if (runner == null)
            {
                logger.LogError("Mode is not configured correctly");
            }
            else
            {
                logger.LogInformation($"****Configuration Management Utility****");
                const string backupFilename = "bkup_soldb.bkup";
                try
                {
                    Task.Run(() => runner.Begin(backupFilename)).Wait();
                }
                catch
                {
#if DEBUG
                    Console.Read();
#endif
                    throw;
                }
            }
        }
    }
}
