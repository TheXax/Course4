using System.Collections.Generic;
using System.Threading.Tasks;

namespace ResultsCollection
{
    public interface IResults
    {
        Task<IReadOnlyDictionary<int, string>> GetAllAsync();
        Task<(bool found, string value)> GetAsync(int key);
        Task<(int key, string value)> AddAsync(string value);
        Task<(bool found, int key, string value)> UpdateAsync(int key, string value);
        Task<(bool found, int key, string value)> DeleteAsync(int key);
    }
}
