using System.Collections.Generic;
using System.Threading.Tasks;

namespace ResultsCollection
{
    public interface IResults //определяет контракт (набор обязательных методов) для сервиса, который управляет коллекцией "RESULTS"
    {
        //Используется для GET /api/Results
        Task<IReadOnlyDictionary<int, string>> GetAllAsync(); //Возвращает всю коллекцию результатов
        //Используется для GET /api/Results/{key}
        Task<(bool found, string value)> GetAsync(int key); //Возвращает элемент по его ключу
        //Используется для POST /api/Results
        Task<(int key, string value)> AddAsync(string value); //Добавляет новый элемент в коллекцию.
        //Используется для PUT /api/Results/{key}
        Task<(bool found, int key, string value)> UpdateAsync(int key, string value); //Изменяет существующий элемент
        //Используется для DELETE /api/Results/{key}
        Task<(bool found, int key, string value)> DeleteAsync(int key); //Удаляет элемент по ключу
    }
}
