using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace ResultsCollection
{
    public class ResultsService : IResults //обеспечивает потокобезопасный доступ к JSON-файлу и все CRUD-операции
    {
        private readonly ResultsOptions _options; //Хранит путь к файлу
        private static readonly JsonSerializerOptions JsonOpts = new JsonSerializerOptions { WriteIndented = false };
        private readonly object _inProcLock = new object(); //внутренний локальный замок, чтобы потоки внутри одного процесса не обращались к файлу одновременно

        public ResultsService(ResultsOptions options) //Конструктор: сохраняет опции и проверяет, что StorePath задан
        {
            _options = options ?? throw new ArgumentNullException(nameof(options));
            if (string.IsNullOrWhiteSpace(_options.StorePath))
                throw new ArgumentException("ResultsOptions.StorePath must be set.");

            var dir = Path.GetDirectoryName(_options.StorePath); //наличие каталога и возврат пути
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                Directory.CreateDirectory(dir);

            EnsureFileExists(); //чтобы создать пустой JSON-файл, если он отсутствует
        }

        public async Task<IReadOnlyDictionary<int, string>> GetAllAsync() //асинхронная загрузка данных из файла
        {
            var store = await LoadAsync().ConfigureAwait(false);//загрузка происходит здесь
            return new Dictionary<int, string>(store.Items); //возврат копии словаря для защиты внутреннего состояния от внешних изменений
        }

        public async Task<(bool found, string value)> GetAsync(int key) //загружает хранилище и пытается получить значение по ключу
        {
            var store = await LoadAsync().ConfigureAwait(false);
            return (store.Items.TryGetValue(key, out var value), value);
        }

        public async Task<(int key, string value)> AddAsync(string value) //добавляем запись
        {
            if (value == null) throw new ArgumentNullException(nameof(value));
            return await WithLockAsync(async store => //Вызывает WithLockAsync, передавая функцию work, которая получает StoreModel (в памяти)
            {
                var id = store.NextId++; //берём текущий индекс и увеличиваем его
                store.Items[id] = value; //сохраняем значение в Items
                await SaveAsync(store).ConfigureAwait(false); //запись изменений в файл
                return (id, value); //возвращение значений
            }).ConfigureAwait(false);
        }

        public async Task<(bool found, int key, string value)> UpdateAsync(int key, string value) //обновление значения по ключу
        {
            if (value == null) throw new ArgumentNullException(nameof(value));
            return await WithLockAsync(async store =>
            {
                if (!store.Items.ContainsKey(key)) return (false, key, value);
                store.Items[key] = value;
                await SaveAsync(store).ConfigureAwait(false);
                return (true, key, value);
            }).ConfigureAwait(false);
        }

        public async Task<(bool found, int key, string value)> DeleteAsync(int key) //удаление значения
        {
            return await WithLockAsync(async store =>
            {
                var found = store.Items.TryGetValue(key, out var removed);
                if (found)
                {
                    store.Items.Remove(key);
                    await SaveAsync(store).ConfigureAwait(false);
                    return (true, key, removed);
                }
                return (false, key, null);
            }).ConfigureAwait(false);
        }

        private void EnsureFileExists() //синхронно гарантирует существование файла
        {
            lock (_inProcLock) //защита от одновременного создания файла в одном процессе
            {
                if (!File.Exists(_options.StorePath)) //если файла нет, то создаёт и записывает
                {
                    var json = JsonSerializer.Serialize(new StoreModel(), JsonOpts);
                    File.WriteAllText(_options.StorePath, json);
                }
            }
        }

        private async Task<StoreModel> LoadAsync() //загружает StoreModel из файла
        {
            return await WithGlobalMutexAsync(async () => //перед чтением берётся глобальный именованный мьютекс (межпроцессный), чтобы предотвратить одновременное чтение/запись другим процессом
            {
                lock (_inProcLock) //защита от параллельных потоков в том же процессе
                {
                    var json = File.ReadAllText(_options.StorePath); //считывание файла
                    var model = JsonSerializer.Deserialize<StoreModel>(json, JsonOpts);
                    return model ?? new StoreModel();
                }
            }).ConfigureAwait(false);
        }

        private async Task SaveAsync(StoreModel model) //сохраняет StoreModel в файл безопаснее
        {
            await WithGlobalMutexAsync(async () =>
            {
                lock (_inProcLock)
                {
                    var temp = _options.StorePath + ".tmp";
                    var json = JsonSerializer.Serialize(model, JsonOpts);
                    File.WriteAllText(temp, json);
                    if (File.Exists(_options.StorePath)) File.Delete(_options.StorePath);
                    File.Move(temp, _options.StorePath); //Если исходный файл существует — удаляет его, затем перемещает временный файл на место основного
                }
                return 0;
            }).ConfigureAwait(false);
        }

        private async Task<T> WithLockAsync<T>(Func<StoreModel, Task<T>> work) //использует я мьютекс и передаёт в него действие (чтение, добавление, удаление)
        {
            return await WithGlobalMutexAsync(async () => //Берёт глобальный мьютекс
            {
                var store = await LoadAsync().ConfigureAwait(false); //Загружает StoreModel
                return await work(store).ConfigureAwait(false); //Выполняет переданную функцию work(store)
            }).ConfigureAwait(false); //Возвращает значение
        }

        private async Task<T> WithGlobalMutexAsync<T>(Func<Task<T>> work) //ставит глобальный замок (межпроцессный, работает даже между разными приложениями)
        {
            using (var mutex = new Mutex(false, _options.GlobalMutexName)) //создание мьютекса
            {
                mutex.WaitOne(); //блокирующий вызов, ожидающий освобождения мьютекса
                try { return await work().ConfigureAwait(false); }
                finally { mutex.ReleaseMutex(); }
            }
        }
    }
}
