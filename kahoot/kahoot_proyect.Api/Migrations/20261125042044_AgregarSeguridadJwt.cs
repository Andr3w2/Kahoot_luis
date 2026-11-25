using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace kahoot_proyect.Api.Migrations
{
    /// <inheritdoc />
    public partial class AgregarSeguridadJwt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "activo",
                table: "Usuario",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "CodigoInvitacion",
                columns: table => new
                {
                    id_codigo = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    codigo = table.Column<string>(type: "TEXT", nullable: false),
                    usado = table.Column<bool>(type: "INTEGER", nullable: false),
                    fecha_creacion = table.Column<DateTime>(type: "TEXT", nullable: false),
                    fecha_expiracion = table.Column<DateTime>(type: "TEXT", nullable: false),
                    usado_por_usuario_id = table.Column<int>(type: "INTEGER", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CodigoInvitacion", x => x.id_codigo);
                    table.ForeignKey(
                        name: "FK_CodigoInvitacion_Usuario_usado_por_usuario_id",
                        column: x => x.usado_por_usuario_id,
                        principalTable: "Usuario",
                        principalColumn: "id_usuario");
                });

            migrationBuilder.CreateIndex(
                name: "IX_Respuesta_id_opcion",
                table: "Respuesta",
                column: "id_opcion");

            migrationBuilder.CreateIndex(
                name: "IX_CodigoInvitacion_usado_por_usuario_id",
                table: "CodigoInvitacion",
                column: "usado_por_usuario_id");

            migrationBuilder.AddForeignKey(
                name: "FK_Respuesta_OpcionRespuesta_id_opcion",
                table: "Respuesta",
                column: "id_opcion",
                principalTable: "OpcionRespuesta",
                principalColumn: "id_opcion",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Respuesta_OpcionRespuesta_id_opcion",
                table: "Respuesta");

            migrationBuilder.DropTable(
                name: "CodigoInvitacion");

            migrationBuilder.DropIndex(
                name: "IX_Respuesta_id_opcion",
                table: "Respuesta");

            migrationBuilder.DropColumn(
                name: "activo",
                table: "Usuario");
        }
    }
}
