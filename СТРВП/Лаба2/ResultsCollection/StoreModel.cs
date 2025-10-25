using System.Collections.Generic;

namespace ResultsCollection
{
    internal class StoreModel
    {
        public int NextId { get; set; } = 1;
        public Dictionary<int, string> Items { get; set; } = new Dictionary<int, string>();
    }
}
