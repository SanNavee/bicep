using System;
using System.Collections.Generic;
using System.Text;

namespace ConfigManagement.Config
{
    public class CommonConfig
    {
        public string Mode { get; set; }
        public string DLC { get; set; }
        public string KeyVaultName { get; set; }
        public string OESourceDbPath { get; set; }
        public string DbPropsName { get; set; }
        public string AppServerName { get; set; }
        public bool UseAppServer { get; set; }
        public AzureStorageConfig AzureStorage { get; set; }

        public class AzureStorageConfig
        {
            public string AzCopyLocation { get; set; }
            public string SourceConnectionString { get; set; }
            public string SourceName { get; set; }
            public string StagingConnectionString { get; set; }
            public string StagingName { get; set; }
            public string TargetConnectionString { get; set; }
            public string TargetName { get; set; }
            public string[] Tables { get; set; }

        }
    }
}
