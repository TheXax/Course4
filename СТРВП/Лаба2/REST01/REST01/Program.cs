using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

namespace REST01
{
    public class Program
    {
        public static void Main(string[] args) => CreateHostBuilder(args).Build().Run(); //запускает сайт как сервер, который слушает входящие запросы

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder => { webBuilder.UseStartup<Startup>(); });
    }
}
