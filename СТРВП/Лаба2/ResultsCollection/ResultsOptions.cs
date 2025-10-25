namespace ResultsCollection
{
    public class ResultsOptions
    {
        public string StorePath { get; set; }
        public string GlobalMutexName { get; set; } = "Global\\BSTU.Results.Collection.Mutex";
    }
}
