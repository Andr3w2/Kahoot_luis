using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace kahoot_proyect.Api.Models
{
    [Table("CodigoInvitacion")]
    public class CodigoInvitacion
    {
        [Key]
        [Column("id_codigo")]
        public int IdCodigo { get; set; }

        [Column("codigo")]
        public string Codigo { get; set; } = string.Empty; // Ej. "PROF-4829"

        [Column("usado")]
        public bool Usado { get; set; } = false;

        [Column("fecha_creacion")]
        public DateTime FechaCreacionUtc { get; set; } = DateTime.UtcNow;

        [Column("fecha_expiracion")]
        public DateTime FechaExpiracionUtc { get; set; }

        [Column("usado_por_usuario_id")]
        public int? UsadoPorUsuarioId { get; set; }

        [ForeignKey(nameof(UsadoPorUsuarioId))]
        public Usuario? UsadoPorUsuario { get; set; }
    }
}