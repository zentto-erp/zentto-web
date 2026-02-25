using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Web.Http;

namespace DatqBox.ReportServer.Controllers
{
    // ═══════════════════════════════════════════════════════════════
    // CONTROLADOR DE REPORTES CRYSTAL
    // Usa reflexión para cargar Crystal Reports dinámicamente.
    // Esto permite compilar el proyecto sin tener el runtime instalado.
    // ═══════════════════════════════════════════════════════════════
    [RoutePrefix("api/reportes")]
    public class ReportesController : ApiController
    {
        private static readonly string ReportesFolder;
        private static readonly bool CrystalAvailable;
        private static readonly string CrystalVersion;
        private static Type _reportDocumentType;

        static ReportesController()
        {
            // Buscar carpeta de reportes
            var baseDir = AppDomain.CurrentDomain.BaseDirectory;
            ReportesFolder = Path.Combine(baseDir, "Reportes");

            // Si no existe junto al exe, buscar en la ruta del agente fiscal
            if (!Directory.Exists(ReportesFolder))
            {
                var agentPath = Path.Combine(baseDir, "..", "DatqBox.LocalFiscalAgent", "Reportes");
                if (Directory.Exists(agentPath))
                    ReportesFolder = Path.GetFullPath(agentPath);
            }

            // Intentar cargar Crystal Reports dinámicamente
            try
            {
                var asm = Assembly.Load("CrystalDecisions.CrystalReports.Engine");
                _reportDocumentType = asm.GetType("CrystalDecisions.CrystalReports.Engine.ReportDocument");
                CrystalAvailable = _reportDocumentType != null;
                CrystalVersion = asm.GetName().Version?.ToString() ?? "desconocida";
            }
            catch
            {
                CrystalAvailable = false;
                CrystalVersion = "NO INSTALADO";
                _reportDocumentType = null;
            }
        }

        // ─── HEALTH CHECK ───
        [HttpGet]
        [Route("~/api/health")]
        public IHttpActionResult Health()
        {
            int reportCount = 0;
            if (Directory.Exists(ReportesFolder))
                reportCount = Directory.GetFiles(ReportesFolder, "*.rpt").Length;

            return Ok(new
            {
                service = "DatqBox Report Server",
                status = "running",
                crystalRuntime = CrystalAvailable,
                crystalVersion = CrystalVersion,
                reportesFolder = ReportesFolder,
                reportesDisponibles = reportCount,
                timestamp = DateTime.Now,
                instrucciones = !CrystalAvailable
                    ? "Instale SAP Crystal Reports Runtime SP37 x64 para habilitar el renderizado de reportes."
                    : null
            });
        }

        // ─── CATÁLOGO: Lista todos los .rpt disponibles ───
        [HttpGet]
        [Route("catalogo")]
        public IHttpActionResult Catalogo()
        {
            if (!Directory.Exists(ReportesFolder))
            {
                return Ok(new { rows = new object[0], error = "Carpeta de reportes no encontrada: " + ReportesFolder });
            }

            var reportes = Directory.GetFiles(ReportesFolder, "*.rpt")
                .Select(f =>
                {
                    var fi = new FileInfo(f);
                    return new
                    {
                        nombre = Path.GetFileNameWithoutExtension(f),
                        archivo = fi.Name,
                        tamano = fi.Length,
                        modificado = fi.LastWriteTime
                    };
                })
                .OrderBy(r => r.nombre)
                .ToList();

            return Ok(new { rows = reportes, total = reportes.Count });
        }

        // ─── PARÁMETROS: Inspecciona un .rpt y devuelve sus parámetros ───
        [HttpGet]
        [Route("parametros")]
        public IHttpActionResult Parametros([FromUri] string reporte)
        {
            if (!CrystalAvailable)
                return Content(HttpStatusCode.ServiceUnavailable, new
                {
                    error = "Crystal Reports Runtime no está instalado.",
                    instrucciones = "Instale SAP Crystal Reports Runtime SP37 x64."
                });

            if (string.IsNullOrWhiteSpace(reporte))
                return BadRequest("Debe indicar el nombre del reporte (sin extensión).");

            string rptPath = ResolverRuta(reporte);
            if (!File.Exists(rptPath))
                return NotFound();

            try
            {
                // Usar Crystal via reflexión
                dynamic doc = Activator.CreateInstance(_reportDocumentType);
                doc.Load(rptPath);

                var parametros = new List<object>();
                foreach (dynamic p in doc.DataDefinition.ParameterFields)
                {
                    string reportName = p.ReportName;
                    if (!string.IsNullOrEmpty(reportName)) continue;

                    parametros.Add(new
                    {
                        nombre = (string)p.Name,
                        tipo = p.ParameterValueType.ToString(),
                        requerido = !(bool)p.IsOptionalPrompt,
                        descripcion = (string)p.PromptText
                    });
                }

                var tablas = new List<object>();
                foreach (dynamic t in doc.Database.Tables)
                {
                    tablas.Add(new
                    {
                        nombre = (string)t.Name,
                        ubicacion = (string)t.Location
                    });
                }

                doc.Close();

                return Ok(new
                {
                    reporte,
                    parametros,
                    tablas,
                    totalParametros = parametros.Count,
                    totalTablas = tablas.Count
                });
            }
            catch (Exception ex)
            {
                return InternalServerError(
                    new Exception($"Error inspeccionando reporte '{reporte}': {ex.Message}"));
            }
        }

        // ─── RENDER: Genera PDF a partir de un .rpt + parámetros ───
        [HttpPost]
        [Route("render")]
        public HttpResponseMessage Render([FromBody] RenderRequest request)
        {
            if (!CrystalAvailable)
            {
                return Request.CreateResponse(HttpStatusCode.ServiceUnavailable, new
                {
                    error = "Crystal Reports Runtime no está instalado.",
                    instrucciones = "Instale SAP Crystal Reports Runtime SP37 x64."
                });
            }

            if (request == null || string.IsNullOrWhiteSpace(request.Reporte))
            {
                return Request.CreateResponse(HttpStatusCode.BadRequest,
                    new { error = "Debe indicar el nombre del reporte." });
            }

            string rptPath = ResolverRuta(request.Reporte);
            if (!File.Exists(rptPath))
            {
                return Request.CreateResponse(HttpStatusCode.NotFound,
                    new { error = $"Reporte '{request.Reporte}' no encontrado en {ReportesFolder}" });
            }

            try
            {
                dynamic doc = Activator.CreateInstance(_reportDocumentType);
                doc.Load(rptPath);

                // ─── Conexión a la BD ───
                if (!string.IsNullOrWhiteSpace(request.Server))
                {
                    AplicarConexionDinamica(doc, request);
                }

                // ─── Parámetros ───
                if (request.Parametros != null)
                {
                    foreach (var kvp in request.Parametros)
                    {
                        try
                        {
                            doc.SetParameterValue(kvp.Key, ConvertirParametro(kvp.Value));
                        }
                        catch (Exception ex)
                        {
                            System.Diagnostics.Debug.WriteLine(
                                $"[WARN] Parámetro '{kvp.Key}' no asignado: {ex.Message}");
                        }
                    }
                }

                // ─── Fórmula de selección ───
                if (!string.IsNullOrWhiteSpace(request.FormulaSeleccion))
                {
                    doc.RecordSelectionFormula = request.FormulaSeleccion;
                }

                // ─── Formato de exportación ───
                string formato = (request.Formato ?? "pdf").ToLowerInvariant();

                // Mapear formato a enum ordinal de ExportFormatType
                // PDF=5, Excel=4, Word=7, RichText=6, CSV=9
                int exportTypeValue;
                string contentType;
                string extension;

                switch (formato)
                {
                    case "excel":
                    case "xls":
                        exportTypeValue = 4; // ExportFormatType.Excel
                        contentType = "application/vnd.ms-excel";
                        extension = "xls";
                        break;
                    case "word":
                    case "doc":
                        exportTypeValue = 7; // ExportFormatType.WordForWindows
                        contentType = "application/msword";
                        extension = "doc";
                        break;
                    case "rtf":
                        exportTypeValue = 6; // ExportFormatType.RichText
                        contentType = "application/rtf";
                        extension = "rtf";
                        break;
                    case "csv":
                        exportTypeValue = 9; // ExportFormatType.CharacterSeparatedValues
                        contentType = "text/csv";
                        extension = "csv";
                        break;
                    default: // pdf
                        exportTypeValue = 5; // ExportFormatType.PortableDocFormat
                        contentType = "application/pdf";
                        extension = "pdf";
                        break;
                }

                // Cargar el enum ExportFormatType por reflexión
                var sharedAsm = Assembly.Load("CrystalDecisions.Shared");
                var exportFormatType = sharedAsm.GetType("CrystalDecisions.Shared.ExportFormatType");
                var exportEnum = Enum.ToObject(exportFormatType, exportTypeValue);

                // ExportToStream(ExportFormatType)
                Stream stream = doc.ExportToStream(exportEnum);

                var memStream = new MemoryStream();
                stream.CopyTo(memStream);
                memStream.Position = 0;

                var response = new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StreamContent(memStream)
                };
                response.Content.Headers.ContentType =
                    new MediaTypeHeaderValue(contentType);
                response.Content.Headers.ContentDisposition =
                    new ContentDispositionHeaderValue("inline")
                    {
                        FileName = $"{request.Reporte}.{extension}"
                    };

                doc.Close();
                return response;
            }
            catch (Exception ex)
            {
                return Request.CreateResponse(HttpStatusCode.InternalServerError,
                    new
                    {
                        error = $"Error renderizando reporte '{request.Reporte}'",
                        detalle = ex.Message,
                        inner = ex.InnerException?.Message,
                        tipo = ex.GetType().Name
                    });
            }
        }

        // ═══════════════════════════════════════════════════════════
        // HELPERS
        // ═══════════════════════════════════════════════════════════

        private string ResolverRuta(string nombre)
        {
            if (!nombre.EndsWith(".rpt", StringComparison.OrdinalIgnoreCase))
                nombre += ".rpt";
            return Path.Combine(ReportesFolder, nombre);
        }

        private void AplicarConexionDinamica(dynamic doc, RenderRequest req)
        {
            // Construir ConnectionInfo via reflexión
            var sharedAsm = Assembly.Load("CrystalDecisions.Shared");
            var connInfoType = sharedAsm.GetType("CrystalDecisions.Shared.ConnectionInfo");
            dynamic connInfo = Activator.CreateInstance(connInfoType);
            connInfo.ServerName = req.Server;
            connInfo.DatabaseName = req.Database ?? "sasdatqbox";
            connInfo.UserID = req.User ?? "sa";
            connInfo.Password = req.Password ?? "";

            foreach (dynamic table in doc.Database.Tables)
            {
                dynamic logonInfo = table.LogOnInfo;
                logonInfo.ConnectionInfo = connInfo;
                table.ApplyLogOnInfo(logonInfo);
            }

            // Sub-reportes
            try
            {
                foreach (dynamic sub in doc.Subreports)
                {
                    foreach (dynamic table in sub.Database.Tables)
                    {
                        dynamic logonInfo = table.LogOnInfo;
                        logonInfo.ConnectionInfo = connInfo;
                        table.ApplyLogOnInfo(logonInfo);
                    }
                }
            }
            catch { /* Puede no tener sub-reportes */ }
        }

        private object ConvertirParametro(object valor)
        {
            if (valor == null) return null;
            string str = valor.ToString();

            if (DateTime.TryParse(str, out DateTime dt)) return dt;
            if (decimal.TryParse(str, out decimal dec)) return dec;
            if (bool.TryParse(str, out bool b)) return b;

            return str;
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // MODELO DE REQUEST
    // ═══════════════════════════════════════════════════════════════
    public class RenderRequest
    {
        /// <summary>Nombre del reporte (ej: "Facturas", "Inventario")</summary>
        public string Reporte { get; set; }

        /// <summary>Formato: pdf, excel, word, csv (default: pdf)</summary>
        public string Formato { get; set; }

        /// <summary>Parámetros: { "Desde": "2026-01-01", "ClienteId": "C001" }</summary>
        public Dictionary<string, object> Parametros { get; set; }

        /// <summary>Fórmula Crystal (WHERE): "{Facturas.Fecha} >= #2026-01-01#"</summary>
        public string FormulaSeleccion { get; set; }

        // ─── Conexión BD (sobreescribe la del .rpt) ───
        public string Server { get; set; }
        public string Database { get; set; }
        public string User { get; set; }
        public string Password { get; set; }
    }
}
