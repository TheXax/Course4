using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text.Json;
using System.Threading.Tasks;
using JsonRpcServer.Models;

namespace JsonRpcServer.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class JsonRpcController : ControllerBase
    {
        [HttpPost]
        public async Task<IActionResult> Post()
        {
            using var doc = await JsonDocument.ParseAsync(Request.Body);
            var root = doc.RootElement;

            // если массив - это пакет запросов
            if (root.ValueKind == JsonValueKind.Array)
            {
                var requests = root.EnumerateArray().ToArray(); //пустой массив недопустим
                if (requests.Length == 0)
                {
                    return BadRequest(new JsonRpcResponse
                    {
                        Jsonrpc = "2.0",
                        Error = JsonRpcError.From(-32600, "Invalid Request"),
                        Id = null
                    });
                }

                var responses = new List<object>(); //если элемент является уведомлением, то возвращает null
                foreach (var reqEl in requests)
                {
                    var resp = ProcessSingleRequest(reqEl);
                    if (resp != null) responses.Add(resp); 
                }

                if (responses.Count == 0) return NoContent();

                return Ok(responses);
            }
            else //одиночный запрос
            {
                var resp = ProcessSingleRequest(root);
                if (resp == null) return NoContent();
                return Ok(resp);
            }
        }

        private object? ProcessSingleRequest(JsonElement reqEl)
        {
            //проверяем, что элемент является объектом
            if (reqEl.ValueKind != JsonValueKind.Object)
            {
                return new JsonRpcResponse
                {
                    Jsonrpc = "2.0",
                    Error = JsonRpcError.From(-32600, "Invalid Request"),
                    Id = null
                };
            }

            string? jsonrpc = reqEl.TryGetProperty("jsonrpc", out var jv) && jv.ValueKind == JsonValueKind.String
                ? jv.GetString()
                : null;

            JsonElement idEl = default;
            bool hasId = reqEl.TryGetProperty("id", out var idProp);
            if (hasId) idEl = idProp;

            string? method = reqEl.TryGetProperty("method", out var mv) && mv.ValueKind == JsonValueKind.String
                ? mv.GetString()
                : null;

            bool hasParams = reqEl.TryGetProperty("params", out var paramsEl);

            if (jsonrpc != "2.0" || string.IsNullOrEmpty(method))
            {
                return BuildErrorResponse(idEl, hasId, -32600, "Invalid Request");
            }

            try
            {
                var (ok, resultOrError) = ExecuteMethod(method!, hasParams ? paramsEl : default);

                if (!ok)
                {
                    return BuildErrorResponse(idEl, hasId, ((JsonRpcError)resultOrError!).Code, ((JsonRpcError)resultOrError!).Message);
                }
                else
                {
                    if (!hasId) return null; // уведомление (без id) - нет ответа
                    return new JsonRpcResponse
                    {
                        Jsonrpc = "2.0",
                        Result = resultOrError,
                        Id = idEl.Clone()
                    };
                }
            }
            catch (Exception ex)
            {
                return BuildErrorResponse(idEl, hasId, -32000, "Server error: " + ex.Message);
            }
        }

        private object BuildErrorResponse(JsonElement idEl, bool hasId, int code, string message)
        {
            if (!hasId)
            {
                return null!;
            }

            return new JsonRpcResponse
            {
                Jsonrpc = "2.0",
                Error = JsonRpcError.From(code, message),
                Id = idEl.Clone()
            };
        }

        private (bool, object?) ExecuteMethod(string method, JsonElement paramsEl)
        {
            var m = method.Trim().ToUpperInvariant();

            switch (m)
            {
                case "SUM":
                case "SUB":
                case "MUL":
                case "DIV":
                    {
                        if (!TryReadTwoParams(paramsEl, out double x, out double y, out JsonRpcError? perr))
                            return (false, perr);

                        try
                        {
                            double r = 0;
                            if (m == "SUM") r = x + y;
                            else if (m == "SUB") r = x - y;
                            else if (m == "MUL") r = x * y;
                            else if (m == "DIV")
                            {
                                if (y == 0) return (false, JsonRpcError.From(-32000, "Division by zero"));
                                r = x / y;
                            }
                            return (true, r);
                        }
                        catch (OverflowException)
                        {
                            return (false, JsonRpcError.From(-32000, "Overflow"));
                        }
                    }

                case "FACT": //для целых неотрицательных чисел
                    {
                        if (!TryReadOneParam(paramsEl, out double x, out JsonRpcError? perr))
                            return (false, perr);

                        if (x < 0 || x % 1 != 0)
                            return (false, JsonRpcError.From(-32000, "Factorial defined only for non-negative integers"));

                        BigInteger fact = 1;
                        for (int i = 2; i <= (int)x; i++) fact *= i;

                        if (fact > int.MaxValue) //если результат больше, то ошибка
                            return (false, JsonRpcError.From(-32000, "Result exceeds allowed maximum (int.MaxValue)"));

                        return (true, (int)fact);
                    }

                default:
                    return (false, JsonRpcError.From(-32601, "Method not found"));
            }
        }

        //поддерживаются 2 формата параметров
        private bool TryReadTwoParams(JsonElement paramsEl, out double x, out double y, out JsonRpcError? error)
        {
            x = y = 0;
            error = null;
            if (paramsEl.ValueKind == JsonValueKind.Undefined || paramsEl.ValueKind == JsonValueKind.Null)
            {
                error = JsonRpcError.From(-32602, "Missing params");
                return false;
            }

            if (paramsEl.ValueKind == JsonValueKind.Array)
            {
                var arr = paramsEl.EnumerateArray().ToArray();
                if (arr.Length < 2)
                {
                    error = JsonRpcError.From(-32602, "Insufficient params");
                    return false;
                }
                if (!TryGetDouble(arr[0], out x) || !TryGetDouble(arr[1], out y))
                {
                    error = JsonRpcError.From(-32602, "Invalid parameter type");
                    return false;
                }
                return true;
            }
            else if (paramsEl.ValueKind == JsonValueKind.Object)
            {
                //проверка длины массива, наличие x и y и типа параметров
                if (!paramsEl.TryGetProperty("x", out var xv) || !paramsEl.TryGetProperty("y", out var yv))
                {
                    error = JsonRpcError.From(-32602, "Named parameters x and y required");
                    return false;
                }
                if (!TryGetDouble(xv, out x) || !TryGetDouble(yv, out y))
                {
                    error = JsonRpcError.From(-32602, "Invalid parameter type");
                    return false;
                }
                return true;
            }
            else
            {
                error = JsonRpcError.From(-32602, "Invalid params");
                return false;
            }
        }

        //аналогично для одного параметра
        private bool TryReadOneParam(JsonElement paramsEl, out double x, out JsonRpcError? error)
        {
            x = 0;
            error = null;
            if (paramsEl.ValueKind == JsonValueKind.Undefined || paramsEl.ValueKind == JsonValueKind.Null)
            {
                error = JsonRpcError.From(-32602, "Missing params");
                return false;
            }

            if (paramsEl.ValueKind == JsonValueKind.Array)
            {
                var arr = paramsEl.EnumerateArray().ToArray();
                if (arr.Length < 1)
                {
                    error = JsonRpcError.From(-32602, "Insufficient params");
                    return false;
                }
                if (!TryGetDouble(arr[0], out x))
                {
                    error = JsonRpcError.From(-32602, "Invalid parameter type");
                    return false;
                }
                return true;
            }
            else if (paramsEl.ValueKind == JsonValueKind.Object)
            {
                // try "x" or "n"
                if (!paramsEl.TryGetProperty("x", out var xv) && !paramsEl.TryGetProperty("n", out xv))
                {
                    error = JsonRpcError.From(-32602, "Named parameter x (or n) required");
                    return false;
                }
                if (!TryGetDouble(xv, out x))
                {
                    error = JsonRpcError.From(-32602, "Invalid parameter type");
                    return false;
                }
                return true;
            }
            else
            {
                error = JsonRpcError.From(-32602, "Invalid params");
                return false;
            }
        }

        //извлечение дробного числа (double)
        private bool TryGetDouble(JsonElement el, out double v)
        {
            v = 0;
            try
            {
                if (el.ValueKind == JsonValueKind.Number)
                {
                    return el.TryGetDouble(out v);
                }
                else if (el.ValueKind == JsonValueKind.String) 
                {
                    var s = el.GetString();
                    if (double.TryParse(s, out v)) return true;
                }
            }
            catch { }
            return false;
        }
    }
}
