using System.Threading.Tasks;

namespace ConfigManagement
{
    interface IProcessRunner
    {
        Task Begin(string backupFilename);
    }
}