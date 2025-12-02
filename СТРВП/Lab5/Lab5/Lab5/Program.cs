var builder = WebApplication.CreateBuilder(args);

// Разрешаем CORS (Cross-Origin Resource Sharing) — механизм, который разрешает браузеру делать запросы к серверу с другого домена
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        //разрешаем обращаться к серверу из фронтенда, который открыт по этому адресу
        policy.WithOrigins("http://127.0.0.1:5500", "http://127.0.0.1:5501", "http://localhost:5500", "http://localhost:5501") //то, где запускается index.html
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials(); 
    });
});

//без этой строки хаб не сможет работать
builder.Services.AddSignalR(); //регистрирует сервисы SignalR внутри ASP

var app = builder.Build();

app.UseCors(); //подключает middleware CORS

app.MapHub<CalculatorHub>("/calculatorHub");

app.Run();
