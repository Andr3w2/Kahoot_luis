using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace kahoot_proyect.Api.Models
{
    [Table("Cuestionario")]
    public class Cuestionario
    {
        [Key]
        [Column("id_cuestionario")]
        public int IdCuestionario { get; set; }

        [Column("titulo")]
        public string Titulo { get; set; } = string.Empty;

        [Column("descripcion")]
        public string Descripcion { get; set; } = string.Empty;

        [Column("fecha_creacion")]
        public string FechaCreacion { get; set; } = string.Empty;

        [Column("id_docente")]
        public int IdDocente { get; set; }

        [Column("codigo_acceso")]
        public string CodigoAcceso { get; set; } = string.Empty;

        [Column("estado")]
        public string Estado { get; set; } = string.Empty;

        [ForeignKey("IdDocente")]
        public Usuario? Docente { get; set; }

        public ICollection<Pregunta> Preguntas { get; set; } = new List<Pregunta>();
        public ICollection<Participacion> Participaciones { get; set; } = new List<Participacion>();
    }
}