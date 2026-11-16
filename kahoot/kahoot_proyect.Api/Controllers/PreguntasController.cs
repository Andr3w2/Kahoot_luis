using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using kahoot_proyect.Api.Data;
using kahoot_proyect.Api.Models;

namespace kahoot_proyect.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PreguntasController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PreguntasController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Preguntas/cuestionario/1
        [HttpGet("cuestionario/{idCuestionario}")]
        public async Task<ActionResult<IEnumerable<Pregunta>>> GetPreguntasPorCuestionario(int idCuestionario)
        {
            var preguntas = await _context.Preguntas
                .Where(p => p.IdCuestionario == idCuestionario)
                .Include(p => p.OpcionesRespuesta)
                .ToListAsync();

            return Ok(preguntas);
        }

        // GET: api/Preguntas/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Pregunta>> GetPregunta(int id)
        {
            var pregunta = await _context.Preguntas
                .Include(p => p.OpcionesRespuesta)
                .FirstOrDefaultAsync(p => p.IdPregunta == id);

            if (pregunta == null)
                return NotFound(new { mensaje = "Pregunta no encontrada." });

            return Ok(pregunta);
        }

        // POST: api/Preguntas (Permite crear la pregunta sola o con sus opciones incluidas)
        [HttpPost]
        public async Task<ActionResult<Pregunta>> PostPregunta(Pregunta pregunta)
        {
            if (string.IsNullOrWhiteSpace(pregunta.TiempoLimite))
            {
                pregunta.TiempoLimite = "30";
            }

            _context.Preguntas.Add(pregunta);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetPregunta), new { id = pregunta.IdPregunta }, pregunta);
        }

        // DELETE: api/Preguntas/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeletePregunta(int id)
        {
            var pregunta = await _context.Preguntas.FindAsync(id);
            if (pregunta == null)
                return NotFound(new { mensaje = "Pregunta no encontrada." });

            _context.Preguntas.Remove(pregunta);
            await _context.SaveChangesAsync();

            return NoContent();
        }
    }
}