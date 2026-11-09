using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace kahoot_proyect.Api.Models
{
    [Table("Respuesta")]
    public class Respuesta
    {
        [Key]
        [Column("id_respuesta")]
        public int IdRespuesta { get; set; }

        [Column("id_participacion")]
        public int IdParticipacion { get; set; }

        [Column("id_pregunta")]
        public int IdPregunta { get; set; }

        [Column("id_opcion")]
        public int IdOpcion { get; set; }

        [Column("es_correcta")]
        public string EsCorrecta { get; set; } = string.Empty;

        [Column("puntos_obtenidos")]
        public string PuntosObtenidos { get; set; } = string.Empty;

        [Column("tiempo_respuesta")]
        public string TiempoRespuesta { get; set; } = string.Empty;

        [ForeignKey("IdParticipacion")]
        public Participacion? Participacion { get; set; }

        [ForeignKey("IdPregunta")]
        public Pregunta? Pregunta { get; set; }
    }
}