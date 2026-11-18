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

        // PUT: api/Cuestionarios/5/estado
        [HttpPut("{id}/estado")]
        public async Task<IActionResult> CambiarEstado(int id, [FromBody] string nuevoEstado)
        {
            var cuestionario = await _context.Cuestionarios.FindAsync(id);
            if (cuestionario == null) return NotFound();

            cuestionario.Estado = nuevoEstado;
            await _context.SaveChangesAsync();
            return Ok(cuestionario);
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

        // GET: api/Cuestionarios/codigo/ABC123
        [HttpGet("codigo/{codigo}")]
        public async Task<ActionResult<Cuestionario>> GetCuestionarioPorCodigo(string codigo)
        {
            string codigoLimpio = codigo.Trim().ToUpper();

            var cuestionario = await _context.Cuestionarios
                .FirstOrDefaultAsync(c => c.CodigoAcceso.Trim().ToUpper() == codigoLimpio);

            if (cuestionario == null)
                return NotFound(new { mensaje = "Código no encontrado." });

            if (cuestionario.Estado != "Esperando")
                return BadRequest(new { mensaje = "La sala está cerrada. Espera a que el maestro la abra." });

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