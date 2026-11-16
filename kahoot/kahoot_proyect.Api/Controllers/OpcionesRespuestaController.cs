using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using kahoot_proyect.Api.Data;
using kahoot_proyect.Api.Models;

namespace kahoot_proyect.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OpcionesRespuestaController : ControllerBase
    {
        private readonly AppDbContext _context;

        public OpcionesRespuestaController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/OpcionesRespuesta/pregunta/1
        [HttpGet("pregunta/{idPregunta}")]
        public async Task<ActionResult<IEnumerable<OpcionRespuesta>>> GetOpcionesPorPregunta(int idPregunta)
        {
            var opciones = await _context.OpcionesRespuestas
                .Where(o => o.IdPregunta == idPregunta)
                .ToListAsync();

            return Ok(opciones);
        }

        // POST: api/OpcionesRespuesta
        [HttpPost]
        public async Task<ActionResult<OpcionRespuesta>> PostOpcionRespuesta(OpcionRespuesta opcion)
        {
            _context.OpcionesRespuestas.Add(opcion);
            await _context.SaveChangesAsync();

            return Ok(opcion);
        }
    }
}