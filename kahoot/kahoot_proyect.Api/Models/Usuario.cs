using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace kahoot_proyect.Api.Models
{
    [Table("Usuario")]
    public class Usuario
    {
        [Key]
        [Column("id_usuario")]
        public int IdUsuario { get; set; }

        [Column("Nombre")]
        public string Nombre { get; set; } = string.Empty;

        [Column("correo")]
        public string Correo { get; set; } = string.Empty;

        [Column("Contrasena")]
        public string Contrasena { get; set; } = string.Empty;

        [Column("tipo_usuario")]
        public string TipoUsuario { get; set; } = string.Empty;

        public ICollection<Cuestionario> Cuestionarios { get; set; } = new List<Cuestionario>();
        public ICollection<Participacion> Participaciones { get; set; } = new List<Participacion>();
    }
}
