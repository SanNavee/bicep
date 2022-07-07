using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Text;

namespace ConfigManagement
{
    class CommandRunner
    {
        private readonly ILogger _logger;

        public CommandRunner(ILogger<CommandRunner> logger)
        {
            _logger = logger;
        }

        public void RunProcess(string workingDir, string filename, string args)
        {
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                UseShellExecute = false,
                WorkingDirectory = workingDir,
                WindowStyle = ProcessWindowStyle.Hidden,
                FileName = filename,
                Arguments = args,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };

            try
            {
                _logger.LogInformation($"Process for '{filename} {args}' starting...");
                using (Process process = Process.Start(startInfo))
                {
                    StringBuilder output = new StringBuilder();
                    process.OutputDataReceived += delegate (object sender, DataReceivedEventArgs e)
                    {
                        Console.WriteLine(e.Data);
                    };
                    process.ErrorDataReceived += delegate (object sender, DataReceivedEventArgs e)
                    {
                        _logger.LogWarning(e.Data);
                    };

                    process.BeginErrorReadLine();
                    process.BeginOutputReadLine();

                    process.WaitForExit();
                    _logger.LogInformation($"Process for '{filename} {args}' finished");
                }
            }
            catch (Win32Exception w32ex)
            {
                _logger.LogCritical($"Cannot execute command '{filename}': {w32ex.Message}", w32ex);
                throw;
            }
        }
    }
}
