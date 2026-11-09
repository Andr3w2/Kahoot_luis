using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace kahoot_proyect.Api.Models
{
    [Table("Participacion")]
    public class Participacion
    {
        [Key]
        [Column("id_participacion")]
        public int IdParticipacion { get; set; }

        [Column("id_usuario")]
        public int IdUsuario { get; set; }

        [Column("id_cuestionario")]
        public int IdCuestionario { get; set; }

        [Column("puntuacion_total")]
        public string PuntuacionTotal { get; set; } = string.Empty;

        [Column("fecha_inicio")]
        public string FechaInicio { get; set; } = string.Empty;

        [Column("fecha_fin")]
        public string FechaFin { get; set; } = string.Empty;

        [ForeignKey("IdUsuario")]
        public Usuario? Usuario { get; set; }

        [ForeignKey("IdCuestionario")]
        public Cuestionario? Cuestionario { get; set; }

        public ICollection<Respuesta> Respuestas { get; set; } = new List<Respuesta>();
    }
}