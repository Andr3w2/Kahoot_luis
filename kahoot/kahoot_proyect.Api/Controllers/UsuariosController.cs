using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using kahoot_proyect.Api.Data;
using kahoot_proyect.Api.Models;

namespace kahoot_proyect.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsuariosController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UsuariosController(AppDbContext context)
        {
            _context = context;
        }

    // POST: api/Usuarios/acceso
    [HttpPost("acceso")]
    public async Task<ActionResult<Usuario>> AccesoPerfil([FromBody] RegistroPerfilDto datos)
    {
        const string CLAVE_MAESTRO_VALIDA = "DOCENTE2026";

        if (datos.Rol == "Maestro")
        {
            if (string.IsNullOrWhiteSpace(datos.ClaveDocente) ||
                datos.ClaveDocente.Trim() != CLAVE_MAESTRO_VALIDA)
            {
                return Unauthorized(new { mensaje = "Clave de maestro incorrecta." });
            }
        }

        var usuario = new Usuario
        {
            Nombre = datos.Nombre.Trim(),
            Correo = datos.Correo,
            Contrasena = datos.Rol == "Maestro" ? CLAVE_MAESTRO_VALIDA : "123"
        };

        _context.Usuarios.Add(usuario);
        await _context.SaveChangesAsync();

        return Ok(usuario);
    }
        
        // GET: api/Usuarios
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Usuario>>> GetUsuarios()
        {
            return await _context.Usuarios.ToListAsync();
        }

        // GET: api/Usuarios/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Usuario>> GetUsuario(int id)
        {
            var usuario = await _context.Usuarios.FindAsync(id);

            if (usuario == null)
                return NotFound(new { mensaje = "Usuario no encontrado." });

            return usuario;
        }

        // POST: api/Usuarios (Registrar docente o alumno)
        [HttpPost]
        public async Task<ActionResult<Usuario>> PostUsuario(Usuario usuario)
        {
            _context.Usuarios.Add(usuario);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetUsuario), new { id = usuario.IdUsuario }, usuario);
        }

        // POST: api/Usuarios/login
        [HttpPost("login")]
        public async Task<ActionResult<Usuario>> Login([FromBody] LoginRequest request)
        {
            var usuario = await _context.Usuarios
                .FirstOrDefaultAsync(u => u.Correo == request.Correo && u.Contrasena == request.Contrasena);

            if (usuario == null)
                return Unauthorized(new { mensaje = "Correo o contraseña incorrectos." });

            return Ok(usuario);
        }
    }

    // Agrega esta propiedad auxiliar dentro o fuera del namespace de UsuariosController.cs
    public class RegistroPerfilDto
    {
        public string Nombre { get; set; } = string.Empty;
        public string Correo { get; set; } = string.Empty;
        public string Rol { get; set; } = "Alumno";
        public string? ClaveDocente { get; set; }
    }

    public class LoginRequest
    {
        public string Correo { get; set; } = string.Empty;
        public string Contrasena { get; set; } = string.Empty;
    }
}