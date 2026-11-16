using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using kahoot_proyect.Api.Data;
using kahoot_proyect.Api.Models;

namespace kahoot_proyect.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ParticipacionesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ParticipacionesController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Participaciones/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Participacion>> GetParticipacion(int id)
        {
            var participacion = await _context.Participaciones
                .Include(p => p.Usuario)
                .Include(p => p.Respuestas)
                .FirstOrDefaultAsync(p => p.IdParticipacion == id);

            if (participacion == null)
                return NotFound(new { mensaje = "Participación no encontrada." });

            return Ok(participacion);
        }

        // GET: api/Participaciones/ranking/1 (Pantalla "Resultados finales")
        [HttpGet("ranking/{idCuestionario}")]
        public async Task<ActionResult<IEnumerable<object>>> GetRankingPorCuestionario(int idCuestionario)
        {
            var participaciones = await _context.Participaciones
                .Where(p => p.IdCuestionario == idCuestionario)
                .Include(p => p.Usuario)
                .ToListAsync();

            // Ordenar de mayor a menor convirtiendo PuntuacionTotal a número
            var ranking = participaciones
                .Select(p => new
                {
                    p.IdParticipacion,
                    p.IdUsuario,
                    NombreAlumno = p.Usuario != null ? p.Usuario.Nombre : "Alumno",
                    PuntuacionTotal = int.TryParse(p.PuntuacionTotal, out int pts) ? pts : 0,
                    p.FechaInicio,
                    p.FechaFin
                })
                .OrderByDescending(r => r.PuntuacionTotal)
                .ToList();

            return Ok(ranking);
        }

        // POST: api/Participaciones (Cuando el alumno entra a la sala)
        [HttpPost]
        public async Task<ActionResult<Participacion>> PostParticipacion(Participacion participacion)
        {
            participacion.PuntuacionTotal = "0";

            if (string.IsNullOrWhiteSpace(participacion.FechaInicio))
            {
                participacion.FechaInicio = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            }

            _context.Participaciones.Add(participacion);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetParticipacion), new { id = participacion.IdParticipacion }, participacion);
        }

        // PUT: api/Participaciones/5/finalizar (Marca el fin de la partida)
        [HttpPut("{id}/finalizar")]
        public async Task<IActionResult> FinalizarParticipacion(int id)
        {
            var participacion = await _context.Participaciones.FindAsync(id);
            if (participacion == null)
                return NotFound(new { mensaje = "Participación no encontrada." });

            participacion.FechaFin = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            await _context.SaveChangesAsync();

            return Ok(participacion);
        }
    }
}