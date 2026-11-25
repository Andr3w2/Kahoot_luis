using System.Security.Cryptography;
using kahoot_proyect.Api.Data;
using kahoot_proyect.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace kahoot_proyect.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _context;

    public AdminController(AppDbContext context)
    {
        _context = context;
    }

    // POST: api/admin/codigos -> Genera un código único válido por 48 horas
    [HttpPost("codigos")]
    public async Task<IActionResult> GenerarCodigo()
    {
        string nuevoCodigo;
        do
        {
            int numero = RandomNumberGenerator.GetInt32(1000, 9999);
            nuevoCodigo = $"PROF-{numero}";
        } while (await _context.CodigosInvitacion.AnyAsync(c => c.Codigo == nuevoCodigo));

        var registro = new CodigoInvitacion
        {
            Codigo = nuevoCodigo,
            Usado = false,
            FechaCreacionUtc = DateTime.UtcNow,
            FechaExpiracionUtc = DateTime.UtcNow.AddHours(48)
        };

        _context.CodigosInvitacion.Add(registro);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            registro.IdCodigo,
            registro.Codigo,
            registro.FechaExpiracionUtc
        });
    }

    // GET: api/admin/codigos -> Lista todos los códigos generados
    [HttpGet("codigos")]
    public async Task<IActionResult> ObtenerCodigos()
    {
        var lista = await _context.CodigosInvitacion
            .OrderByDescending(c => c.FechaCreacionUtc)
            .ToListAsync();

        return Ok(lista);
    }

    // GET: api/admin/maestros -> Lista los maestros registrados
    [HttpGet("maestros")]
    public async Task<IActionResult> ObtenerMaestros()
    {
        var maestros = await _context.Usuarios
            .Where(u => u.TipoUsuario == "Maestro")
            .Select(u => new { u.IdUsuario, u.Nombre, u.Correo, u.Activo })
            .ToListAsync();

        return Ok(maestros);
    }

    // PATCH: api/admin/maestros/5/estado -> Activa o desactiva la cuenta de un maestro
    [HttpPatch("maestros/{id}/estado")]
    public async Task<IActionResult> CambiarEstadoMaestro(int id, [FromBody] bool activo)
    {
        var maestro = await _context.Usuarios
            .FirstOrDefaultAsync(u => u.IdUsuario == id && u.TipoUsuario == "Maestro");

        if (maestro == null) return NotFound("Maestro no encontrado.");

        maestro.Activo = activo;
        await _context.SaveChangesAsync();
        return Ok(new { maestro.IdUsuario, maestro.Nombre, maestro.Activo });
    }
}