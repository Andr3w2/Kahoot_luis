using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace kahoot_proyect.Api.Models
{
    [Table("OpcionRespuesta")]
    public class OpcionRespuesta
    {
        [Key]
        [Column("id_opcion")]
        public int IdOpcion { get; set; }

        [Column("id_pregunta")]
        public int IdPregunta { get; set; }

        [Column("texto")]
        public string Texto { get; set; } = string.Empty;

        [Column("es_correcta")]
        public string EsCorrecta { get; set; } = string.Empty;

        [ForeignKey("IdPregunta")]
        public Pregunta? Pregunta { get; set; }
    }
}