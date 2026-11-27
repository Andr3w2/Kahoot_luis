using System.Globalization;
using Microsoft.AspNetCore.Mvc;

namespace kahoot_proyect.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AnalyticsController : ControllerBase
{
    private readonly string _dwPath;

    public AnalyticsController(IWebHostEnvironment env)
    {
        _dwPath = Path.Combine(env.ContentRootPath, "DataWarehouse");
    }

    [HttpGet("cubo")]
    public IActionResult ObtenerCuboOlap([FromQuery] int trimestre = 0, [FromQuery] string nivel = "area")
    {
        var temas = CargarTemas();
        var tiempos = CargarTiempos();
        var consultas = CargarConsultas();
        var respuestas = CargarRespuestas();

        var consultasFiltradas = consultas
            .Where(c => trimestre == 0 || (tiempos.TryGetValue(c.IdTiempo, out var t) && t.Trimestre == trimestre))
            .ToList();

        var respuestasFiltradas = respuestas
            .Where(r => trimestre == 0 || (tiempos.TryGetValue(r.IdTiempo, out var t) && t.Trimestre == trimestre))
            .ToList();

        var grupos = temas
            .GroupBy(t => nivel == "tema" ? t.Value.Tema : t.Value.UnidadArea)
            .Select(g =>
            {
                var idsTema = g.Select(x => x.Key).ToHashSet();
                var consGrupo = consultasFiltradas.Where(c => idsTema.Contains(c.IdTema)).ToList();
                var respGrupo = respuestasFiltradas.Where(r => idsTema.Contains(r.IdTema)).ToList();

                int totalCons = consGrupo.Sum(x => x.Cantidad);
                int correctas = respGrupo.Sum(x => x.Correcta);
                int incorrectas = respGrupo.Sum(x => x.Incorrecta);
                double tiempoProm = respGrupo.Count > 0
                    ? Math.Round(respGrupo.Average(x => x.TiempoSegundos), 1)
                    : 0;

                return new
                {
                    categoria = g.Key,
                    consultas = totalCons,
                    correctas,
                    incorrectas,
                    totalRespuestas = correctas + incorrectas,
                    tiempoPromedio = tiempoProm
                };
            })
            .OrderByDescending(x => x.totalRespuestas)
            .ToList();

        string[] areasOrden = ["Lenguajes", "Lectura", "Escritura", "Gramática", "Comunicación"];
        int[] trimestresOrden = [1, 2, 3];

        object ConstruirMatrizCubo(int minUser, int maxUser)
        {
            var matCorrectas = new List<int[]>();
            var matIncorrectas = new List<int[]>();
            var matConsultas = new List<int[]>();
            var matTiempos = new List<double[]>();

            foreach (int q in trimestresOrden)
            {
                var filaCorr = new int[areasOrden.Length];
                var filaInc = new int[areasOrden.Length];
                var filaCons = new int[areasOrden.Length];
                var filaTiempo = new double[areasOrden.Length];

                for (int c = 0; c < areasOrden.Length; c++)
                {
                    string area = areasOrden[c];
                    var idsArea = temas.Where(x => x.Value.UnidadArea == area).Select(x => x.Key).ToHashSet();

                    var rCelda = respuestas
                        .Where(r =>
                            r.NumUsuario >= minUser && r.NumUsuario <= maxUser &&
                            idsArea.Contains(r.IdTema) &&
                            tiempos.TryGetValue(r.IdTiempo, out var t) && t.Trimestre == q)
                        .ToList();

                    var cCelda = consultas
                        .Where(cons =>
                            cons.NumUsuario >= minUser && cons.NumUsuario <= maxUser &&
                            idsArea.Contains(cons.IdTema) &&
                            tiempos.TryGetValue(cons.IdTiempo, out var t) && t.Trimestre == q)
                        .ToList();

                    filaCorr[c] = rCelda.Sum(x => x.Correcta);
                    filaInc[c] = rCelda.Sum(x => x.Incorrecta);
                    filaCons[c] = cCelda.Sum(x => x.Cantidad);
                    filaTiempo[c] = rCelda.Count > 0 ? Math.Round(rCelda.Average(x => x.TiempoSegundos), 1) : 0;
                }

                matCorrectas.Add(filaCorr);
                matIncorrectas.Add(filaInc);
                matConsultas.Add(filaCons);
                matTiempos.Add(filaTiempo);
            }

            return new
            {
                areas = areasOrden,
                trimestres = new[] { "Q1 (Mar)", "Q2 (Abr-Jun)", "Q3 (Jul-Ago)" },
                correctas = matCorrectas,
                incorrectas = matIncorrectas,
                consultas = matConsultas,
                tiempos = matTiempos
            };
        }

        // Vista 4D: 4ª Dimensión = DIM_USUARIO dividida en 3 grupos de alumnos
        var cubos4d = new[]
        {
            new { etiquetaGrupo = "Alumnos U001–U027 (Grupo A)", datosCubo = ConstruirMatrizCubo(1, 27) },
            new { etiquetaGrupo = "Alumnos U028–U054 (Grupo B)", datosCubo = ConstruirMatrizCubo(28, 54) },
            new { etiquetaGrupo = "Alumnos U055–U080 (Grupo C)", datosCubo = ConstruirMatrizCubo(55, 80) }
        };

        int totCorrectas = respuestasFiltradas.Sum(x => x.Correcta);
        int totIncorrectas = respuestasFiltradas.Sum(x => x.Incorrecta);
        int totResp = totCorrectas + totIncorrectas;

        return Ok(new
        {
            escuela = "Escuela Fernando Montaño (Tepic, Nayarit)",
            trimestreAplicado = trimestre,
            nivelJerarquia = nivel,
            resumen = new
            {
                totalConsultas = consultasFiltradas.Sum(x => x.Cantidad),
                totalRespuestas = totResp,
                porcentajeAcierto = totResp > 0 ? Math.Round((double)totCorrectas * 100 / totResp, 1) : 0,
                tiempoPromedioGlobal = respuestasFiltradas.Count > 0
                    ? Math.Round(respuestasFiltradas.Average(x => x.TiempoSegundos), 2)
                    : 0
            },
            cubo3d = ConstruirMatrizCubo(1, 80),
            cubo4d = cubos4d,
            datos = grupos
        });
    }

    private static int ExtraerNumeroUsuario(string idUsuario)
    {
        var limpio = idUsuario.Trim().Replace("U", "").Replace("u", "");
        return int.TryParse(limpio, out int n) ? n : 0;
    }

    private Dictionary<int, (string UnidadArea, string Tema)> CargarTemas()
    {
        var dict = new Dictionary<int, (string, string)>();
        var path = Path.Combine(_dwPath, "dim_tema.csv");
        foreach (var line in System.IO.File.ReadLines(path).Skip(1))
        {
            if (string.IsNullOrWhiteSpace(line)) continue;
            var p = line.Split(',');
            dict[int.Parse(p[0])] = (p[2].Trim(), p[3].Trim());
        }
        return dict;
    }

    private Dictionary<int, (int Mes, int Trimestre)> CargarTiempos()
    {
        var dict = new Dictionary<int, (int, int)>();
        var path = Path.Combine(_dwPath, "dim_tiempo.csv");
        foreach (var line in System.IO.File.ReadLines(path).Skip(1))
        {
            if (string.IsNullOrWhiteSpace(line)) continue;
            var p = line.Split(',');
            dict[int.Parse(p[0])] = (int.Parse(p[4]), int.Parse(p[6]));
        }
        return dict;
    }

    private List<(int IdTema, int IdTiempo, int NumUsuario, int Cantidad)> CargarConsultas()
    {
        var list = new List<(int, int, int, int)>();
        var path = Path.Combine(_dwPath, "hechos_consultas.csv");
        foreach (var line in System.IO.File.ReadLines(path).Skip(1))
        {
            if (string.IsNullOrWhiteSpace(line)) continue;
            var p = line.Split(',');
            list.Add((int.Parse(p[1]), int.Parse(p[4]), ExtraerNumeroUsuario(p[5]), int.Parse(p[6])));
        }
        return list;
    }

    private List<(int IdTema, int IdTiempo, int NumUsuario, int Correcta, int Incorrecta, double TiempoSegundos)> CargarRespuestas()
    {
        var list = new List<(int, int, int, int, int, double)>();
        var path = Path.Combine(_dwPath, "hechos_respuestas.csv");
        foreach (var line in System.IO.File.ReadLines(path).Skip(1))
        {
            if (string.IsNullOrWhiteSpace(line)) continue;
            var p = line.Split(',');
            list.Add((
                int.Parse(p[1]),
                int.Parse(p[4]),
                ExtraerNumeroUsuario(p[5]),
                int.Parse(p[7]),
                int.Parse(p[8]),
                double.Parse(p[9], CultureInfo.InvariantCulture)
            ));
        }
        return list;
    }
}