using System.Threading.Tasks;

namespace ResultsAuthenticate
{
    public interface IAuthenticate
    {
        Task<string> SignInAsync(string login, string password, string requiredRole = null);
    }
}
