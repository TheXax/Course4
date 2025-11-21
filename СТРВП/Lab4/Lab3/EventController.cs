using Microsoft.AspNetCore.Mvc;
using System.Runtime.Intrinsics.X86;
//позволяет клиентам подписываться на события
namespace Lab3
{
    [ApiController]
    [Route("events")]
    public class EventsController : ControllerBase //ссылка на SSE-сервис управляет подписчиками
    {
        private readonly SseService _sse; //контроллер отправляет события через сервис

        public EventsController(SseService sse) //создаём объект для работы с подписчиками
        {
            _sse = sse;
        }

        [HttpGet("subscribe")]
        public async Task Subscribe()
        {
            Response.Headers.Add("Content-Type", "text/event-stream");
            Response.Headers.Add("Cache-Control", "no-cache"); //запрет кеширования, иначе клиент не получит новые события
            _sse.AddSubscriber(Response);

            try
            {
                while (!HttpContext.RequestAborted.IsCancellationRequested) //пока соединение не разорвано клиентом, метод не завершится
                {
                    await Task.Delay(1000);
                }
            }
            finally
            {
                _sse.RemoveSubscriber(Response);
            }
        }
    }

}
