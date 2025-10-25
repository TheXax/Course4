using System.Collections.Generic;

namespace ResultsCollection
{
    internal class StoreModel //служит внутренней моделью хранения данных для коллекции RESULTS
    {
        public int NextId { get; set; } = 1;
        public Dictionary<int, string> Items { get; set; } = new Dictionary<int, string>(); //Основная коллекция, где хранятся все элементы
    }
}
