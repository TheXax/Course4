namespace ResultsCollection
{
    public class ResultsOptions //отвечает за то, где и как хранится коллекция результатов (RESULTS) в файловой системе
    {
        public string StorePath { get; set; } //путь к файлу с коллекцией результатов
        public string GlobalMutexName { get; set; } = "Global\\BSTU.Results.Collection.Mutex"; //мьютекс для ограничения одновременного доступа к файлу с результатами
    }
}
