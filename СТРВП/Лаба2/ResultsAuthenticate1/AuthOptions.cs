namespace ResultsAuthenticate
{
    public class AuthOptions //модель конфигурации для параметров JWT-аутентификации (токенов)
    {
        public string Issuer { get; set; } = "BSTU.Rest01";
        public string Audience { get; set; } = "BSTU.Rest01.Clients";
        public string SigningKey { get; set; }
        public int TokenLifetimeMinutes { get; set; } = 60;
    }
}
