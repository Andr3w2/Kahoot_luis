using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace kahoot_proyect.Api.Models
{
    [Table("Pregunta")]
    public class Pregunta
    {
        [Key]
        [Column("id_pregunta")]
        public int IdPregunta { get; set; }

        [Column("id_cuestionario")]
        public int IdCuestionario { get; set; }

        [Column("texto")]
        public string Texto { get; set; } = string.Empty;

        [Column("tiempo_limite")]
        public string TiempoLimite { get; set; } = string.Empty;

        [ForeignKey("IdCuestionario")]
        public Cuestionario? Cuestionario { get; set; }

        public ICollection<OpcionRespuesta> OpcionesRespuesta { get; set; } = new List<OpcionRespuesta>();
        public ICollection<Respuesta> Respuestas { get; set; } = new List<Respuesta>();
    }
}