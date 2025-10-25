using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Json;
using System.Threading;
using System.Threading.Tasks;

namespace ResultsCollection
{
    public class ResultsService : IResults
    {
        private readonly ResultsOptions _options;
        private readonly DataContractJsonSerializer _serializer =
            new DataContractJsonSerializer(typeof(StoreModel));
        private readonly object _inProcLock = new object();

        public ResultsService(ResultsOptions options)
        {
            _options = options ?? throw new ArgumentNullException(nameof(options));
            if (string.IsNullOrWhiteSpace(_options.StorePath))
                throw new ArgumentException("ResultsOptions.StorePath must be set.");

            var dir = Path.GetDirectoryName(_options.StorePath);
            if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                Directory.CreateDirectory(dir);

            EnsureFileExists();
        }

        public async Task<IReadOnlyDictionary<int, string>> GetAllAsync()
        {
            var store = await LoadAsync().ConfigureAwait(false);
            return new Dictionary<int, string>(store.Items);
        }

        public async Task<(bool found, string value)> GetAsync(int key)
        {
            var store = await LoadAsync().ConfigureAwait(false);
            return (store.Items.TryGetValue(key, out var value), value);
        }

        public async Task<(int key, string value)> AddAsync(string value)
        {
            if (value == null) throw new ArgumentNullException(nameof(value));
            return await WithLockAsync(async store =>
            {
                var id = store.NextId++;
                store.Items[id] = value;
                await SaveAsync(store).ConfigureAwait(false);
                return (id, value);
            });
        }

        public async Task<(bool found, int key, string value)> UpdateAsync(int key, string value)
        {
            return await WithLockAsync(async store =>
            {
                if (!store.Items.ContainsKey(key))
                    return (false, key, value);
                store.Items[key] = value;
                await SaveAsync(store).ConfigureAwait(false);
                return (true, key, value);
            });
        }

        public async Task<(bool found, int key, string value)> DeleteAsync(int key)
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
            });
        }

        private void EnsureFileExists()
        {
            lock (_inProcLock)
            {
                if (!File.Exists(_options.StorePath))
                {
                    var model = new StoreModel();
                    using (var fs = File.Open(_options.StorePath, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                    {
                        _serializer.WriteObject(fs, model);
                    }
                }
            }
        }

        private async Task<StoreModel> LoadAsync()
        {
            return await WithGlobalMutexAsync(() =>
            {
                lock (_inProcLock)
                {
                    using (var fs = File.Open(_options.StorePath, FileMode.Open, FileAccess.Read, FileShare.Read))
                    {
                        return Task.FromResult((StoreModel)_serializer.ReadObject(fs));
                    }
                }
            });
        }

        private async Task SaveAsync(StoreModel model)
        {
            await WithGlobalMutexAsync(() =>
            {
                lock (_inProcLock)
                {
                    var temp = _options.StorePath + ".tmp";
                    using (var fs = File.Open(temp, FileMode.Create, FileAccess.Write, FileShare.None))
                    {
                        _serializer.WriteObject(fs, model);
                    }
                    if (File.Exists(_options.StorePath)) File.Delete(_options.StorePath);
                    File.Move(temp, _options.StorePath);
                }
                return Task.FromResult(0);
            });
        }

        private async Task<T> WithLockAsync<T>(Func<StoreModel, Task<T>> work)
        {
            return await WithGlobalMutexAsync(async () =>
            {
                var store = await LoadAsync().ConfigureAwait(false);
                return await work(store);
            });
        }

        private async Task<T> WithGlobalMutexAsync<T>(Func<Task<T>> work)
        {
            using (var mutex = new Mutex(false, _options.GlobalMutexName))
            {
                mutex.WaitOne();
                try
                {
                    return await work();
                }
                finally
                {
                    mutex.ReleaseMutex();
                }
            }
        }
    }
}
