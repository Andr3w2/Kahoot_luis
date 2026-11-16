using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace kahoot_proyect.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Usuario",
                columns: table => new
                {
                    id_usuario = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Nombre = table.Column<string>(type: "TEXT", nullable: false),
                    correo = table.Column<string>(type: "TEXT", nullable: false),
                    Contrasena = table.Column<string>(type: "TEXT", nullable: false),
                    tipo_usuario = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Usuario", x => x.id_usuario);
                });

            migrationBuilder.CreateTable(
                name: "Cuestionario",
                columns: table => new
                {
                    id_cuestionario = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    titulo = table.Column<string>(type: "TEXT", nullable: false),
                    descripcion = table.Column<string>(type: "TEXT", nullable: false),
                    fecha_creacion = table.Column<string>(type: "TEXT", nullable: false),
                    id_docente = table.Column<int>(type: "INTEGER", nullable: false),
                    codigo_acceso = table.Column<string>(type: "TEXT", nullable: false),
                    estado = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cuestionario", x => x.id_cuestionario);
                    table.ForeignKey(
                        name: "FK_Cuestionario_Usuario_id_docente",
                        column: x => x.id_docente,
                        principalTable: "Usuario",
                        principalColumn: "id_usuario",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Participacion",
                columns: table => new
                {
                    id_participacion = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    id_usuario = table.Column<int>(type: "INTEGER", nullable: false),
                    id_cuestionario = table.Column<int>(type: "INTEGER", nullable: false),
                    puntuacion_total = table.Column<string>(type: "TEXT", nullable: false),
                    fecha_inicio = table.Column<string>(type: "TEXT", nullable: false),
                    fecha_fin = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Participacion", x => x.id_participacion);
                    table.ForeignKey(
                        name: "FK_Participacion_Cuestionario_id_cuestionario",
                        column: x => x.id_cuestionario,
                        principalTable: "Cuestionario",
                        principalColumn: "id_cuestionario",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Participacion_Usuario_id_usuario",
                        column: x => x.id_usuario,
                        principalTable: "Usuario",
                        principalColumn: "id_usuario",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Pregunta",
                columns: table => new
                {
                    id_pregunta = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    id_cuestionario = table.Column<int>(type: "INTEGER", nullable: false),
                    texto = table.Column<string>(type: "TEXT", nullable: false),
                    tiempo_limite = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Pregunta", x => x.id_pregunta);
                    table.ForeignKey(
                        name: "FK_Pregunta_Cuestionario_id_cuestionario",
                        column: x => x.id_cuestionario,
                        principalTable: "Cuestionario",
                        principalColumn: "id_cuestionario",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "OpcionRespuesta",
                columns: table => new
                {
                    id_opcion = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    id_pregunta = table.Column<int>(type: "INTEGER", nullable: false),
                    texto = table.Column<string>(type: "TEXT", nullable: false),
                    es_correcta = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OpcionRespuesta", x => x.id_opcion);
                    table.ForeignKey(
                        name: "FK_OpcionRespuesta_Pregunta_id_pregunta",
                        column: x => x.id_pregunta,
                        principalTable: "Pregunta",
                        principalColumn: "id_pregunta",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Respuesta",
                columns: table => new
                {
                    id_respuesta = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    id_participacion = table.Column<int>(type: "INTEGER", nullable: false),
                    id_pregunta = table.Column<int>(type: "INTEGER", nullable: false),
                    id_opcion = table.Column<int>(type: "INTEGER", nullable: false),
                    es_correcta = table.Column<string>(type: "TEXT", nullable: false),
                    puntos_obtenidos = table.Column<string>(type: "TEXT", nullable: false),
                    tiempo_respuesta = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Respuesta", x => x.id_respuesta);
                    table.ForeignKey(
                        name: "FK_Respuesta_Participacion_id_participacion",
                        column: x => x.id_participacion,
                        principalTable: "Participacion",
                        principalColumn: "id_participacion",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Respuesta_Pregunta_id_pregunta",
                        column: x => x.id_pregunta,
                        principalTable: "Pregunta",
                        principalColumn: "id_pregunta",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Cuestionario_id_docente",
                table: "Cuestionario",
                column: "id_docente");

            migrationBuilder.CreateIndex(
                name: "IX_OpcionRespuesta_id_pregunta",
                table: "OpcionRespuesta",
                column: "id_pregunta");

            migrationBuilder.CreateIndex(
                name: "IX_Participacion_id_cuestionario",
                table: "Participacion",
                column: "id_cuestionario");

            migrationBuilder.CreateIndex(
                name: "IX_Participacion_id_usuario",
                table: "Participacion",
                column: "id_usuario");

            migrationBuilder.CreateIndex(
                name: "IX_Pregunta_id_cuestionario",
                table: "Pregunta",
                column: "id_cuestionario");

            migrationBuilder.CreateIndex(
                name: "IX_Respuesta_id_participacion",
                table: "Respuesta",
                column: "id_participacion");

            migrationBuilder.CreateIndex(
                name: "IX_Respuesta_id_pregunta",
                table: "Respuesta",
                column: "id_pregunta");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "OpcionRespuesta");

            migrationBuilder.DropTable(
                name: "Respuesta");

            migrationBuilder.DropTable(
                name: "Participacion");

            migrationBuilder.DropTable(
                name: "Pregunta");

            migrationBuilder.DropTable(
                name: "Cuestionario");

            migrationBuilder.DropTable(
                name: "Usuario");
        }
    }
}
