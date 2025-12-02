using Microsoft.AspNetCore.SignalR;
using System;

public class CalculatorHub : Hub //Hub — это класс SignalR. Принимает вызовы и отправляет ответы
{
    public double SUM(double x, double y) => x + y;
    public double SUB(double x, double y) => x - y;
    public double MUL(double x, double y) => x * y;

    public double DIV(double x, double y)
    {
        if (y == 0)
            throw new HubException("Division by zero is not allowed.");
        return x / y;
    }

    public int FACT(int x)
    {
        try
        {
            checked //проверка переполнения
            {
                int result = 1;
                for (int i = 2; i <= x; i++)
                    result *= i;
                return result;
            }
        }
        catch (OverflowException)
        {
            throw new HubException("Factorial result exceeds int capacity.");
        }
    }
}
