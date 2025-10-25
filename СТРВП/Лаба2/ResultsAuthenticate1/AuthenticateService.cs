using Microsoft.AspNetCore.Identity; //для хеширования паролей
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace ResultsAuthenticate
{
    //СЕРВИС ВХОДА В СИСТЕМУ
    public class AuthenticateService : IAuthenticate
    {
        private readonly AuthOptions _options; //настройки из AuthOptions
        private readonly PasswordHasher<string> _hasher = new PasswordHasher<string>(); //используется чтобы хешировать пароли по безопасному алгоритму
        private readonly Dictionary<string, (string hash, string[] roles)> _users; //словарь пользователей в формате: login -> (hash, roles[])

        public AuthenticateService(AuthOptions options) //конструктор принимает параметры
        {
            _options = options ?? throw new ArgumentNullException(nameof(options));
            if (string.IsNullOrWhiteSpace(_options.SigningKey)) //Проверяет, что есть ключ для подписи токена
                throw new ArgumentException("AuthOptions.SigningKey must be set.");

            _users = new Dictionary<string, (string, string[])> //жёстко закодированный набор тестовых пользователей
            {
                { "reader", ( _hasher.HashPassword("reader", "reader123"), new[] { "READER" } ) }, //для каждого создаётся хеш пароля
                { "writer", ( _hasher.HashPassword("writer", "writer123"), new[] { "WRITER","READER" } ) }
            };
        }

        //Далее авторизация
        public Task<string> SignInAsync(string login, string password, string requiredRole = null) //возвращает JWT в виде строки или null при ошибке
        {
            if (string.IsNullOrEmpty(login) || string.IsNullOrEmpty(password))
                return Task.FromResult<string>(null); //Task.FromResult — метод синхронно возвращает завершённую задачу

            if (!_users.TryGetValue(login, out var entry)) //Пытаемся найти данные пользователя в _users (словаре)
                return Task.FromResult<string>(null);

            var res = _hasher.VerifyHashedPassword(login, entry.hash, password); //проверка пароля
            if (res == PasswordVerificationResult.Failed)
                return Task.FromResult<string>(null);

            if (!string.IsNullOrEmpty(requiredRole)) //проверка наличия указанной роли
            {
                var ok = Array.Exists(entry.roles, r => string.Equals(r, requiredRole, StringComparison.OrdinalIgnoreCase)); //Используется Array.Exists и сравнение без учёта регистра
                if (!ok) return Task.FromResult<string>(null);
            }

            var claims = new List<Claim> //формирует набор утверждений, которые будут положены в payload JWT
            {
                new Claim(JwtRegisteredClaimNames.Sub, login), //JwtRegisteredClaimNames.Sub — стандартный зарегистрированный claim sub (subject) сохраняем как логин пользователя
                new Claim(ClaimTypes.Name, login) //то же самое, но с именем
            };
            foreach (var role in entry.roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            //подготовка ключа и подписи
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.SigningKey)); //кодирование в байты
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256); //создаётся с алгоритмом симметричной подписи

            //Создаём токен с указанными параметрами
            var now = DateTime.UtcNow;
            var token = new JwtSecurityToken(
                issuer: _options.Issuer, //издатель токена
                audience: _options.Audience, //потребитель
                claims: claims, //список утверждений
                notBefore: now, //токен не действителен до этого времени
                expires: now.AddMinutes(_options.TokenLifetimeMinutes), //время истечения токена
                signingCredentials: creds //подпись, чтобы получатель мог проверить подлинность токена
            );
            var jwt = new JwtSecurityTokenHandler().WriteToken(token);
            return Task.FromResult(jwt);
        }
    }
}
