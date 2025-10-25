namespace ResultsAuthenticate
{
    public class AuthOptions
    {
        public string Issuer { get; set; } = "BSTU.Rest01";
        public string Audience { get; set; } = "BSTU.Rest01.Clients";
        public string SigningKey { get; set; }
        public int TokenLifetimeMinutes { get; set; } = 60;
    }
}
