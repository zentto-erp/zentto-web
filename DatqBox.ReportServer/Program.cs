using System;
using System.Web.Http;
using Microsoft.Owin.Hosting;
using Owin;
using Microsoft.Owin.Cors;

namespace DatqBox.ReportServer
{
    class Program
    {
        // Puerto por defecto del servidor de reportes
        const int DEFAULT_PORT = 5060;
        const string SERVICE_NAME = "DatqBox Report Server";

        static void Main(string[] args)
        {
            int port = DEFAULT_PORT;

            // Permite sobreescribir el puerto con --port 5061
            for (int i = 0; i < args.Length - 1; i++)
            {
                if (args[i] == "--port" && int.TryParse(args[i + 1], out int p))
                    port = p;
            }

            string baseUrl = $"http://localhost:{port}";

            try
            {
                using (WebApp.Start<Startup>(baseUrl))
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine($@"
╔══════════════════════════════════════════════════════╗
║         {SERVICE_NAME}                      ║
║   Crystal Reports .NET Framework 4.8 Runtime        ║
╠══════════════════════════════════════════════════════╣
║   URL:  http://localhost:{port}                      ║
║                                                      ║
║   Endpoints:                                         ║
║     GET  /api/reportes/catalogo                      ║
║     POST /api/reportes/render                        ║
║     GET  /api/reportes/parametros?reporte=X          ║
║     GET  /api/health                                 ║
╚══════════════════════════════════════════════════════╝
");
                    Console.ResetColor();
                    Console.WriteLine("Presione ENTER para detener el servidor...");
                    Console.ReadLine();
                }
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"[ERROR] No se pudo iniciar en {baseUrl}: {ex.Message}");
                Console.WriteLine();
                Console.WriteLine("Si el error es 'Access Denied', ejecute como Administrador o use:");
                Console.WriteLine($"  netsh http add urlacl url=http://+:{port}/ user=TODOS");
                Console.ResetColor();
                Console.ReadLine();
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // OWIN STARTUP — Configura WebAPI + CORS
    // ═══════════════════════════════════════════════════════════════
    public class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            // CORS abierto para desarrollo (luego se puede restringir)
            app.UseCors(CorsOptions.AllowAll);

            var config = new HttpConfiguration();

            // Rutas por atributo [Route]
            config.MapHttpAttributeRoutes();

            // Fallback
            config.Routes.MapHttpRoute(
                name: "DefaultApi",
                routeTemplate: "api/{controller}/{action}/{id}",
                defaults: new { id = RouteParameter.Optional }
            );

            // JSON por defecto
            config.Formatters.Remove(config.Formatters.XmlFormatter);
            var json = config.Formatters.JsonFormatter;
            json.SerializerSettings.NullValueHandling = Newtonsoft.Json.NullValueHandling.Ignore;

            app.UseWebApi(config);
        }
    }
}
