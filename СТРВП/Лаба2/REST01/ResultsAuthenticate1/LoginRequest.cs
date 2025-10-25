namespace ResultsAuthenticate
{
    public class LoginRequest //модель запроса для аутентификации (то, что клиент отправляет при входе)
    {
        public string Login { get; set; }
        public string Password { get; set; }
    }
}
