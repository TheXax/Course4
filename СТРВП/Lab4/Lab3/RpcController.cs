using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

namespace Lab3
{
    [ApiController]
    [Route("rpc")]
    public class RpcController : ControllerBase
    {
        private readonly SseService _sse;

        public RpcController(SseService sse)
        {
            _sse = sse;
        }

        [HttpPost]
        public IActionResult HandleRpc([FromBody] JsonElement body)
        {
            if (body.ValueKind == JsonValueKind.Array) //проверка является ли массивом
            {
                var responses = new List<object>();
                foreach (var item in body.EnumerateArray())
                    responses.Add(ProcessRequest(item));
                return Ok(responses);
            }
            else
            {
                return Ok(ProcessRequest(body));
            }
        }

        private object ProcessRequest(JsonElement request)
        {
            var method = request.GetProperty("method").GetString();
            var id = request.TryGetProperty("id", out var idProp) ? idProp.GetInt32() : (int?)null;
            var jsonrpc = request.GetProperty("jsonrpc").GetString();

            double x = 0, y = 0;
            int xi = 0;

            try
            {
                //если параметры являются объектом
                if (request.GetProperty("params").ValueKind == JsonValueKind.Object)
                {
                    var p = request.GetProperty("params");
                    if (p.TryGetProperty("x", out var xProp)) x = xProp.GetDouble();
                    if (p.TryGetProperty("y", out var yProp)) y = yProp.GetDouble();
                    if (p.TryGetProperty("x", out var xiProp)) xi = xiProp.GetInt32();
                }
                else if (request.GetProperty("params").ValueKind == JsonValueKind.Array) //если параметры - массив
                {
                    var p = request.GetProperty("params").EnumerateArray().ToArray();
                    if (p.Length > 0) x = p[0].GetDouble();
                    if (p.Length > 1) y = p[1].GetDouble();
                    if (p.Length > 0) xi = p[0].GetInt32();
                }

                object result = method switch
                {
                    "SUM" => x + y,
                    "SUB" => x - y,
                    "MUL" => x * y,
                    "DIV" => y == 0 ? throw new Exception("Division by zero") : x / y,
                    "FACT" => Factorial(xi),
                    _ => throw new Exception("Unknown method")
                };
                //отправка sse-события
                _sse.BroadcastAsync(method, JsonSerializer.Serialize(new { result }));
                return new { jsonrpc, result, id };
            }
            catch (Exception ex)
            {
                _sse.BroadcastAsync(method, JsonSerializer.Serialize(new { error = ex.Message }));

                return new
                {
                    jsonrpc,
                    error = new { code = -32602, message = ex.Message },
                    id
                };
            }
        }

        private int Factorial(int x)
        {
            if (x < 0) throw new Exception("Negative factorial");
            long result = 1;
            for (int i = 2; i <= x; i++) result *= i;
            if (result > int.MaxValue) throw new Exception("Result exceeds int.MaxValue");
            return (int)result;
        }
    }

}
