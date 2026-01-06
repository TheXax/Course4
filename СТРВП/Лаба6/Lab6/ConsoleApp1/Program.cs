using System;
using System.Threading.Tasks;
using Grpc.Net.Client;
using Grpc.Core;
using Lab6;

class Program
{
    static async Task Main(string[] args)
    {
        using var channel = GrpcChannel.ForAddress("https://localhost:7048");
        var client = new Calculator.CalculatorClient(channel);

        try
        {
            var sum = await client.SumAsync(new BinaryRequest { X = 10, Y = 5 });
            Console.WriteLine($"SUM(10, 5) = {sum.Result}");

            var sub = await client.SubAsync(new BinaryRequest { X = 10, Y = 5 });
            Console.WriteLine($"SUB(10, 5) = {sub.Result}");

            var mul = await client.MulAsync(new BinaryRequest { X = 10, Y = 5 });
            Console.WriteLine($"MUL(10, 5) = {mul.Result}");

            var div = await client.DivAsync(new BinaryRequest { X = 10, Y = 2 });
            Console.WriteLine($"DIV(10, 2) = {div.Result}");

            /*try
            {
                var divZero = await client.DivAsync(new BinaryRequest { X = 10, Y = 0 });
                Console.WriteLine($"DIV(10, 0) = {divZero.Result}");
            }
            catch (RpcException ex)
            {
                Console.WriteLine($"DIV(10, 0) → Ошибка: {ex.Status.Detail}");
            }*/

            // FACT — корректный вызов
            var fact = await client.FactAsync(new UnaryRequest { X = 3 });
            Console.WriteLine($"FACT(3) = {fact.Result}");

            // Ошибка попадёт в CATCH и не остановит программу
            /*try
            {
                var factOverflow = await client.FactAsync(new UnaryRequest { X = 20 });
                Console.WriteLine($"FACT(20) = {factOverflow.Result}");
            }
            catch (RpcException ex)
            {
                Console.WriteLine($"FACT(20) → Ошибка: {ex.Status.Detail}");
            }*/
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Общая ошибка: {ex.Message}");
        }

        Console.WriteLine("\nНажмите Enter для выхода...");
        Console.ReadLine(); 
    }
}
