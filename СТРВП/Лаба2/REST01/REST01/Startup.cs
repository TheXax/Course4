using Microsoft.AspNetCore.Authentication.JwtBearer; //для настройки JWT-аутентификации
using Microsoft.AspNetCore.Authentication.OAuth; //не используется
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens; //для валидации токенов
using ResultsAuthenticate; //внешнияя бибилиотека
using ResultsCollection; //внешнияя бибилиотека
using System.Text;

namespace REST01
{
    public class Startup
    {
        private readonly IConfiguration _cfg; //система, которая читает настройки из файла appsettings.json
        public Startup(IConfiguration configuration) => _cfg = configuration;


        //подключение настройки проекта, чтобы потом использовать их для инициализации сервисов
        public void ConfigureServices(IServiceCollection services) //место, где регистрируются все сервисы DI и middleware-ориентированные опции
        {

            //Подключаем модуль, который отвечает за хранение и работу с результатами
            // DI: Results (Transient)
            var resOpts = _cfg.GetSection("Results").Get<ResultsOptions>(); //Берётся конфигурационный раздел Results и преобразуется в ResultsOptions
            services.AddTransient<IResults>(sp => new ResultsService(resOpts)); //“Создавай новый экземпляр каждый раз, когда кто-то просит IResults."

            //подключаем модуль, который умеет логинить пользователей и создавать токены.
            // DI: Authenticate (Scoped)
            var authOpts = _cfg.GetSection("Auth").Get<AuthOptions>(); //Берётся конфигурация Auth в AuthOptions
            services.AddScoped<IAuthenticate>(sp => new AuthenticateService(authOpts)); //“Один объект на один HTTP-запрос.”

            //включаем вход по токенам и объясняем, как система должна проверять их подлинность.
            // JWT
            var key = Encoding.UTF8.GetBytes(authOpts.SigningKey); //Берём секретный ключ (SigningKey) и переводим его в байты
            services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme) //включает JWT Bearer обработчик.
                .AddJwtBearer(o =>
                {
                    o.RequireHttpsMetadata = false; //не требует HTTPS для получения метаданных / валидации
                    o.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true, //проверять издателя токена
                        ValidateAudience = true, //проверять аудиторию
                        ValidateIssuerSigningKey = true, //проверять подпись
                        ValidIssuer = authOpts.Issuer, //значения берутся из authOpts
                        ValidAudience = authOpts.Audience, //значения берутся из authOpts
                        IssuerSigningKey = new SymmetricSecurityKey(key) //ключ подписи из key
                    };
                });

            services.AddAuthorization(); //включает систему проверки ролей
            services.AddControllers(); //добавляет поддержку контроллеров, чтобы обрабатывать маршруты (api/...)
        }

        //В Configure выстраивается конвейер обработки запросов: маршрутизация → аутентификация → авторизация → вызов контроллеров.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env) //настраивает конвейер обработки запросов
        {
            if (env.IsDevelopment()) app.UseDeveloperExceptionPage(); //Если среда разработки — включается детальная страница для подробных ошибок

            app.UseRouting();
            app.UseAuthentication();
            app.UseAuthorization();

            app.UseEndpoints(endpoints => { endpoints.MapControllers(); });
        }
    }
}
