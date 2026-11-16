using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using kahoot_proyect.Api.Data;
using kahoot_proyect.Api.Models;

namespace kahoot_proyect.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CuestionariosController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CuestionariosController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Cuestionarios
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Cuestionario>>> GetCuestionarios()
        {
            return await _context.Cuestionarios
                .Include(c => c.Docente)
                .ToListAsync();
        }

        // GET: api/Cuestionarios/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Cuestionario>> GetCuestionario(int id)
        {
            var cuestionario = await _context.Cuestionarios
                .Include(c => c.Preguntas)
                .FirstOrDefaultAsync(c => c.IdCuestionario == id);

            if (cuestionario == null)
                return NotFound(new { mensaje = "Cuestionario no encontrado." });

            return cuestionario;
        }

        // GET: api/Cuestionarios/codigo/ABC123 (Pantalla "Ingreso con código")
        [HttpGet("codigo/{codigo}")]
        public async Task<ActionResult<Cuestionario>> GetCuestionarioPorCodigo(string codigo)
        {
            var cuestionario = await _context.Cuestionarios
                .Include(c => c.Preguntas)
                .FirstOrDefaultAsync(c => c.CodigoAcceso.ToUpper() == codigo.ToUpper() && c.Estado == "Activo");

            if (cuestionario == null)
                return NotFound(new { mensaje = "Código de sala inválido o el cuestionario no está activo." });

            return Ok(cuestionario);
        }

        // POST: api/Cuestionarios
        [HttpPost]
        public async Task<ActionResult<Cuestionario>> PostCuestionario(Cuestionario cuestionario)
        {
            // Generar código aleatorio de 6 caracteres si no se envió uno
            if (string.IsNullOrWhiteSpace(cuestionario.CodigoAcceso))
            {
                cuestionario.CodigoAcceso = GenerarCodigoSala();
            }

            if (string.IsNullOrWhiteSpace(cuestionario.FechaCreacion))
            {
                cuestionario.FechaCreacion = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            }

            if (string.IsNullOrWhiteSpace(cuestionario.Estado))
            {
                cuestionario.Estado = "Activo";
            }

            _context.Cuestionarios.Add(cuestionario);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetCuestionario), new { id = cuestionario.IdCuestionario }, cuestionario);
        }

        private string GenerarCodigoSala()
        {
            const string caracteres = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
            var random = new Random();
            return new string(Enumerable.Repeat(caracteres, 6)
                .Select(s => s[random.Next(s.Length)]).ToArray());
        }
    }
}