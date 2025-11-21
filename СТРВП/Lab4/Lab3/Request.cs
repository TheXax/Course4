namespace Lab3
{
    public class Request
    {
        public string Jsonrpc { get; set; }
        public string Method { get; set; }
        public object Params { get; set; }
        public int? Id { get; set; }
    }

}
