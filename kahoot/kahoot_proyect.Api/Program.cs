using System.Text;
using kahoot_proyect.Api.Data;
using kahoot_proyect.Api.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// 1. Controladores
builder.Services.AddControllers();

// 2. Base de datos SQLite
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? "Data Source=kahoot.db";
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(connectionString));

// 3. CORS (permite conexiones desde Flutter en Android, Windows o Web)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// 4. Autenticación con JWT
var jwtKey = builder.Configuration["Jwt:Key"] ?? "ClaveSuperSecretaDeAlMenos32CaracteresParaJabsQuizz!";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

// 5. Crea automáticamente la cuenta del Administrador inicial si no existe
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    context.Database.Migrate();

    if (!context.Usuarios.Any(u => u.TipoUsuario == "Admin"))
    {
        var hasher = new PasswordHasher<Usuario>();
        var admin = new Usuario
        {
            Nombre = "Administrador",
            Correo = "admin@jabsquizz.com",
            TipoUsuario = "Admin",
            Activo = true
        };
        admin.Contrasena = hasher.HashPassword(admin, "Admin1234!");
        context.Usuarios.Add(admin);
        context.SaveChanges();
    }
}

// 6. Pipeline HTTP (el orden es importante)
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();