using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using kahoot_proyect.Api.Data;
using kahoot_proyect.Api.Models;

namespace kahoot_proyect.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RespuestasController : ControllerBase
    {
        private readonly AppDbContext _context;

        public RespuestasController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/Respuestas/participacion/5
        [HttpGet("participacion/{idParticipacion}")]
        public async Task<ActionResult<IEnumerable<Respuesta>>> GetRespuestasPorParticipacion(int idParticipacion)
        {
            var respuestas = await _context.Respuestas
                .Where(r => r.IdParticipacion == idParticipacion)
                .Include(r => r.Pregunta)
                .ToListAsync();

            return Ok(respuestas);
        }

        // POST: api/Respuestas
        [HttpPost]
        public async Task<ActionResult<Respuesta>> PostRespuesta(Respuesta respuesta)
        {
            // Si es opción múltiple (IdOpcion > 0), verificar en BD si la opción es correcta
            if (respuesta.IdOpcion > 0)
            {
                var opcion = await _context.OpcionesRespuestas.FindAsync(respuesta.IdOpcion);
                if (opcion != null)
                {
                    bool correcta = opcion.EsCorrecta.Equals("true", StringComparison.OrdinalIgnoreCase) ||
                                    opcion.EsCorrecta == "1" ||
                                    opcion.EsCorrecta.Equals("si", StringComparison.OrdinalIgnoreCase);

                    respuesta.EsCorrecta = correcta ? "true" : "false";

                    // Asignar 100 puntos por defecto si es correcta y no se enviaron puntos desde la app
                    if (string.IsNullOrWhiteSpace(respuesta.PuntosObtenidos))
                    {
                        respuesta.PuntosObtenidos = correcta ? "100" : "0";
                    }
                }
            }
            else
            {
                // Para preguntas abiertas donde la app evalúa o envía el resultado
                if (string.IsNullOrWhiteSpace(respuesta.PuntosObtenidos))
                    respuesta.PuntosObtenidos = "0";
            }

            _context.Respuestas.Add(respuesta);

            // Sumar los puntos obtenidos al total de la Participación
            var participacion = await _context.Participaciones.FindAsync(respuesta.IdParticipacion);
            if (participacion != null)
            {
                int totalActual = int.TryParse(participacion.PuntuacionTotal, out int t) ? t : 0;
                int puntosGanados = int.TryParse(respuesta.PuntosObtenidos, out int p) ? p : 0;
                participacion.PuntuacionTotal = (totalActual + puntosGanados).ToString();
            }

            await _context.SaveChangesAsync();

            return Ok(respuesta);
        }
    }
}