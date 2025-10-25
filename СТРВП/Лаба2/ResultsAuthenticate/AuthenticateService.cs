using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace ResultsAuthenticate
{
    public class AuthenticateService : IAuthenticate
    {
        private readonly AuthOptions _options;
        private readonly PasswordHasher<string> _hasher = new PasswordHasher<string>();
        private readonly Dictionary<string, (string hash, string[] roles)> _users;

        public AuthenticateService(AuthOptions options)
        {
            _options = options ?? throw new ArgumentNullException(nameof(options));
            if (string.IsNullOrWhiteSpace(_options.SigningKey))
                throw new ArgumentException("AuthOptions.SigningKey must be set.");

            _users = new Dictionary<string, (string, string[])>
            {
                { "reader", ( _hasher.HashPassword("reader", "reader123"), new[] { "READER" } ) },
                { "writer", ( _hasher.HashPassword("writer", "writer123"), new[] { "WRITER","READER" } ) }
            };
        }

        public Task<string> SignInAsync(string login, string password, string requiredRole = null)
        {
            if (string.IsNullOrEmpty(login) || string.IsNullOrEmpty(password))
                return Task.FromResult<string>(null);

            if (!_users.TryGetValue(login, out var entry))
                return Task.FromResult<string>(null);

            var res = _hasher.VerifyHashedPassword(login, entry.hash, password);
            if (res == PasswordVerificationResult.Failed)
                return Task.FromResult<string>(null);

            if (!string.IsNullOrEmpty(requiredRole))
            {
                var ok = Array.Exists(entry.roles, r => string.Equals(r, requiredRole, StringComparison.OrdinalIgnoreCase));
                if (!ok) return Task.FromResult<string>(null);
            }

            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, login),
                new Claim(ClaimTypes.Name, login)
            };
            foreach (var role in entry.roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.SigningKey));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var now = DateTime.UtcNow;
            var token = new JwtSecurityToken(
                issuer: _options.Issuer,
                audience: _options.Audience,
                claims: claims,
                notBefore: now,
                expires: now.AddMinutes(_options.TokenLifetimeMinutes),
                signingCredentials: creds
            );
            var jwt = new JwtSecurityTokenHandler().WriteToken(token);
            return Task.FromResult(jwt);
        }
    }
}
