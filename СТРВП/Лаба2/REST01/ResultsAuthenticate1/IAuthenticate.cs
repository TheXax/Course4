using System.Threading.Tasks;

namespace ResultsAuthenticate
{
    //говорим, какие методы должны быть у сервиса
    public interface IAuthenticate //для определения контракта (поведения) сервиса аутентификации
    {
        Task<string> SignInAsync(string login, string password, string requiredRole = null);
    }
}
