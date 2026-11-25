using Microsoft.EntityFrameworkCore;
using kahoot_proyect.Api.Models;

namespace kahoot_proyect.Api.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Usuario> Usuarios { get; set; }
        public DbSet<Cuestionario> Cuestionarios { get; set; }
        public DbSet<Pregunta> Preguntas { get; set; }
        public DbSet<OpcionRespuesta> OpcionesRespuestas { get; set; }
        public DbSet<Participacion> Participaciones { get; set; }
        public DbSet<Respuesta> Respuestas { get; set; }
        public DbSet<CodigoInvitacion> CodigosInvitacion { get; set; }
    }
}