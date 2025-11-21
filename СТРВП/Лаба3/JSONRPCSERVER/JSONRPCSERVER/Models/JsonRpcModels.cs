using System.Text.Json;
using System.Text.Json.Serialization;

namespace JsonRpcServer.Models
{
    public class JsonRpcResponse
    {
        [JsonPropertyName("jsonrpc")] //при сериализации в JSON свойство должно называться "jsonrpc"
        public string Jsonrpc { get; set; } = "2.0";

        [JsonPropertyName("result")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] //поле не будет включено в итоговый JSON
        public object? Result { get; set; }

        [JsonPropertyName("error")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] //сериализуется только если есть ошибка
        public JsonRpcError? Error { get; set; }

        //id в JSON-RPC может быть числом, строкой или null
        [JsonPropertyName("id")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public JsonElement? Id { get; set; } //позволяет хранить сырое JSON-значение, без приведения к конкретному типу
    }

    public class JsonRpcError
    {
        [JsonPropertyName("code")]
        public int Code { get; set; }

        [JsonPropertyName("message")]
        public string Message { get; set; } = "";

        public static JsonRpcError From(int code, string message) => new JsonRpcError { Code = code, Message = message };
    }
}
