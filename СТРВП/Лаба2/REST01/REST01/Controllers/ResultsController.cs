using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ResultsAuthenticate;
using ResultsCollection;
using System.Linq;
using System.Threading.Tasks;

namespace REST01.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ResultsController : ControllerBase //использует DI (внедрение зависимостей)
    {
        private readonly IResults _results; //сервис, который реально хранит и изменяет данные
        private readonly IAuthenticate _authenticate; //сервис, который занимается входом (логином) и созданием токенов

        public ResultsController(IResults results, IAuthenticate authenticate)
        {
            _results = results; //интерфейс для CRUD
            _authenticate = authenticate; //интерфейс для аутентификации
        }

        //АВТОРИЗАЦИЯ (ВХОД)
        // POST /api/Results/SignIn
        [HttpPost("SignIn")]
        [AllowAnonymous]
        public async Task<IActionResult> SignIn([FromBody] LoginRequest req)
        {
            if (req == null || string.IsNullOrWhiteSpace(req.Login) || string.IsNullOrWhiteSpace(req.Password))
                return BadRequest(new { error = "login and password required" });

            var jwt = await _authenticate.SignInAsync(req.Login, req.Password, null); //метод сравнивает пароль с хэшем
            if (jwt == null) return NotFound(new { error = "invalid credentials or role" });

            return Ok(new { token = jwt }); //если всё правильно, то создаёт токен
        }

        //ПОЛУЧИТЬ ВСЕ ДАННЫЕ
        // GET /api/Results
        [HttpGet]
        [Authorize(Roles = "READER,WRITER")]//проверка роли при входе
        public async Task<IActionResult> GetAll()
        {
            var dict = await _results.GetAllAsync(); //берём все данные
            if (dict == null || dict.Count == 0) return NoContent(); //если пусто, то ошибка 204
            var items = dict.Select(kv => new { key = kv.Key, value = kv.Value }); //если есть, то возвращает JSON массив
            return Ok(items);
        }

        //ПОЛУЧИТЬ ЭЛЕМЕНТ ПО КЛЮЧУ
        // GET /api/Results/{k:int}
        [HttpGet("{k:int}")]
        [Authorize(Roles = "READER,WRITER")]
        public async Task<IActionResult> Get(int k)
        {
            var (found, value) = await _results.GetAsync(k);
            if (!found) return NotFound();
            return Ok(new { key = k, value });
        }

        public class ValueDto { public string Value { get; set; } }

        //ДОБАВЛЕНИЕ НОВОГО ЭЛЕМЕНТА
        // POST /api/Results
        [HttpPost]
        [Authorize(Roles = "WRITER")]
        public async Task<IActionResult> Post([FromBody] ValueDto dto)
        {
            if (dto == null || dto.Value == null) return BadRequest(new { error = "value is required" });
            var (key, value) = await _results.AddAsync(dto.Value);
            return CreatedAtAction(nameof(Get), new { k = key }, new { key, value });
        }

        //ИЗМЕНИТЬ ЭЛЕМЕНТ
        // PUT /api/Results/{k:int}
        [HttpPut("{k:int}")]
        [Authorize(Roles = "WRITER")]
        public async Task<IActionResult> Put(int k, [FromBody] ValueDto dto)
        {
            if (dto == null || dto.Value == null) return BadRequest(new { error = "value is required" });
            var (found, key, value) = await _results.UpdateAsync(k, dto.Value);
            if (!found) return NotFound();
            return Ok(new { key, value });
        }

        //УДАЛИТЬ ЭЛЕМЕНТ
        // DELETE /api/Results/{k:int}
        [HttpDelete("{k:int}")]
        [Authorize(Roles = "WRITER")]
        public async Task<IActionResult> Delete(int k)
        {
            var (found, key, value) = await _results.DeleteAsync(k);
            if (!found) return NotFound();
            return Ok(new { key, value });
        }
    }
}
