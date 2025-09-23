using System.Text.Json;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;

namespace Lab1;

public class Program
{
    //Глобальное состояние: RESULT общий для всех сессий
    private static int GlobalResult = 0;

    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        builder.Services.AddDistributedMemoryCache(); //кэш в памяти, который будет хранить данные сессий
        builder.Services.AddSession(options => //включение сессии
        {
            options.Cookie.HttpOnly = true; //cookie с id сессии недоступно из JS (безопасность)
            options.Cookie.IsEssential = true; //cookie помечается как «необходимое»
            options.IdleTimeout = TimeSpan.FromMinutes(30); //сессия закончится, если запросы не поступают 30мин
        });

        var app = builder.Build();

        app.UseStaticFiles();
        app.UseRouting();
        app.UseSession();

        var initials = "SVA";
        var routePattern = $"/resource.{initials}";

        static List<int> GetStack(ISession session) //читает из сессии JSON-строку под ключом STACK
        {
            var s = session.GetString("STACK");

            if (string.IsNullOrEmpty(s))  //если строка пустая, по возвращает пустой список
                return new List<int>();

            try
            {
                return JsonSerializer.Deserialize<List<int>>(s) ?? new List<int>();
            }
            catch
            {
                return new List<int>();
            }
        }

        static void SaveStack(ISession session, List<int> stack) => //сохраняем текущий стек в сессию
            session.SetString("STACK", JsonSerializer.Serialize(stack));

        static int? PeekStack(List<int> stack) => //возвращает верхний элемент стека
            (stack == null || stack.Count == 0) ? null : stack[^1]; //если пусто, то возвращает null
                                                                    //return stack[stack.Count - 1]; //иначе последний элемент стека

        app.MapGet(routePattern, (HttpContext ctx) =>
        {
            var stack = GetStack(ctx.Session); //считывание стека для сессии
            var total = GlobalResult + (PeekStack(stack) ?? 0); //сумма результата и верха стека

            return Results.Json(new
            {
                RESULT = total,
                BASE_RESULT = GlobalResult,
                TOP_OF_STACK = (int?)PeekStack(stack)
            });//возврат JSON-ответа
        });

        app.MapPost(routePattern, async (HttpContext ctx) =>
        {
            string? resultParam = ctx.Request.Query["RESULT"].FirstOrDefault(); //берём значение из RESULT
            if (string.IsNullOrEmpty(resultParam) && ctx.Request.HasFormContentType) //если resultParam пустой
            {
                var form = await ctx.Request.ReadFormAsync(); //читаем форму асинхронно
                resultParam = form["RESULT"].FirstOrDefault(); //берём значение
            }

            if (string.IsNullOrEmpty(resultParam) || !int.TryParse(resultParam, out var newResult)) //если после этого параметр отсутствует, то возвращаем ошибку
            {
                return Results.BadRequest(new { error = "Parameter RESULT is required and must be integer." });
            }

            //общий RESULT
            GlobalResult = newResult;

            var stack = GetStack(ctx.Session); //получаем стек
            var total = GlobalResult + (PeekStack(stack) ?? 0); //считываем новое значение

            return Results.Json(new { RESULT = total, BASE_RESULT = GlobalResult });
        });

        app.MapMethods(routePattern, new[] { "PUT" }, async (HttpContext ctx) => //добавление числа в стек
        {
            string? addParam = ctx.Request.Query["ADD"].FirstOrDefault(); //читает параметр ADD

            if (string.IsNullOrEmpty(addParam) && ctx.Request.HasFormContentType) //если отсутствует или не int, то ошибка
            {
                var form = await ctx.Request.ReadFormAsync();
                addParam = form["ADD"].FirstOrDefault();
            }

            if (string.IsNullOrEmpty(addParam) || !int.TryParse(addParam, out var addValue))
            {
                return Results.BadRequest(new { error = "Parameter ADD is required and must be integer." });
            }

            var stack = GetStack(ctx.Session); //загрузка стека
            stack.Add(addValue); //добавление значения
            SaveStack(ctx.Session, stack); //сохраняем изменения

            var total = GlobalResult + (PeekStack(stack) ?? 0); //новая сумма

            return Results.Json(new { ACTION = "PUSH", ADDED = addValue, RESULT = total, STACK_SIZE = stack.Count });
        });

        app.MapMethods(routePattern, new[] { "DELETE" }, (HttpContext ctx) => //удаление верха стека
        {
            var stack = GetStack(ctx.Session);

            if (stack.Count == 0)
            {
                return Results.BadRequest(new { error = "Stack is empty, nothing to pop." });
            }

            var popped = stack[^1]; //запоминаем верхний элемент
            stack.RemoveAt(stack.Count - 1); //удаляем последний элемент
            SaveStack(ctx.Session, stack); //сохраняем изменения

            var total = GlobalResult + (PeekStack(stack) ?? 0); //считывание нового результата

            return Results.Json(new { ACTION = "POP", POPPED = popped, RESULT = total, STACK_SIZE = stack.Count });
        });

        app.Run();
    }
}