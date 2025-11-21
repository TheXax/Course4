using System.Text;

namespace Lab3
{
    public class SseService
    {
        private readonly List<HttpResponse> _subscribers = new(); //для хранения подписчиков

        public void AddSubscriber(HttpResponse response) //вызывается в момент подписки
        {
            lock (_subscribers) //lock — для потокобезопасности, чтобы два потока не изменяли список одновременно
            {
                _subscribers.Add(response);
            }
        }

        public void RemoveSubscriber(HttpResponse response)
        {
            lock (_subscribers)
            {
                _subscribers.Remove(response);
            }
        }
        //рассылка смс
        public async Task BroadcastAsync(string eventName, string data)
        {
            var message = $"event: {eventName}\ndata: {data}\n\n";
            var buffer = Encoding.UTF8.GetBytes(message);

            List<HttpResponse> toRemove = new(); //список для удаления: если отправка в какого-то клиента падает с ошибкой — значит он отключился

            //попытка отправки смс
            lock (_subscribers)
            {
                foreach (var response in _subscribers)
                {
                    try
                    {
                        response.Body.WriteAsync(buffer, 0, buffer.Length);
                        response.Body.FlushAsync(); //гарантия немедленной отправки
                    }
                    catch
                    {
                        toRemove.Add(response); //еслм ошибка (клиент закрыт), то добавляем в список toRemove
                    }
                }
                //перебор и удаление, чтобы всегда были только активные подключения
                foreach (var r in toRemove)
                    _subscribers.Remove(r);
            }
        }
    }

}
