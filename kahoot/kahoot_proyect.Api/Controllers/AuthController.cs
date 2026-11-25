using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using kahoot_proyect.Api.Data;
using kahoot_proyect.Api.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace kahoot_proyect.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _config;
    private readonly PasswordHasher<Usuario> _hasher = new();

    public AuthController(AppDbContext context, IConfiguration config)
    {
        _context = context;
        _config = config;
    }

    public record RegistroMaestroDto(string Nombre, string Correo, string Password, string CodigoInvitacion);
    public record LoginDto(string Correo, string Password);

    [HttpPost("registro-maestro")]
    public async Task<IActionResult> RegistrarMaestro([FromBody] RegistroMaestroDto dto)
    {
        var codigoNormalizado = dto.CodigoInvitacion.Trim().ToUpper();
        var invitacion = await _context.CodigosInvitacion
            .FirstOrDefaultAsync(c => c.Codigo == codigoNormalizado);

        if (invitacion == null || invitacion.Usado || invitacion.FechaExpiracionUtc < DateTime.UtcNow)
            return BadRequest("El código de invitación no es válido, ya fue utilizado o expiró.");

        if (await _context.Usuarios.AnyAsync(u => u.Correo == dto.Correo.Trim().ToLower()))
            return BadRequest("Ese correo ya está registrado.");

        var usuario = new Usuario
        {
            Nombre = dto.Nombre.Trim(),
            Correo = dto.Correo.Trim().ToLower(),
            TipoUsuario = "Maestro",
            Activo = true
        };
        usuario.Contrasena = _hasher.HashPassword(usuario, dto.Password);

        _context.Usuarios.Add(usuario);
        await _context.SaveChangesAsync();

        invitacion.Usado = true;
        invitacion.UsadoPorUsuarioId = usuario.IdUsuario;
        await _context.SaveChangesAsync();

        return Ok(new
        {
            idUsuario = usuario.IdUsuario,
            token = GenerarToken(usuario),
            rol = usuario.TipoUsuario,
            nombre = usuario.Nombre
        });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        var usuario = await _context.Usuarios
            .FirstOrDefaultAsync(u => u.Correo == dto.Correo.Trim().ToLower());

        if (usuario == null || !usuario.Activo)
            return Unauthorized("Credenciales incorrectas o cuenta desactivada.");

        var resultado = _hasher.VerifyHashedPassword(usuario, usuario.Contrasena, dto.Password);
        if (resultado == PasswordVerificationResult.Failed)
            return Unauthorized("Credenciales incorrectas.");

        return Ok(new
        {
            idUsuario = usuario.IdUsuario,
            token = GenerarToken(usuario),
            rol = usuario.TipoUsuario,
            nombre = usuario.Nombre
        });
    }

    private string GenerarToken(Usuario usuario)
    {
        var jwtKey = _config["Jwt:Key"] ?? "ClaveSuperSecretaDeAlMenos32CaracteresParaJabsQuizz!";
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, usuario.IdUsuario.ToString()),
            new Claim(ClaimTypes.Name, usuario.Nombre),
            new Claim(ClaimTypes.Role, usuario.TipoUsuario)
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}