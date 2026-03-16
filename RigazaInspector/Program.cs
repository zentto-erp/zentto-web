using System;
using System.Reflection;

namespace RigazaInspector
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                var asm = Assembly.LoadFile(@"C:\Users\Dell\Dropbox\DatqBox Administrativo ADO SQL\Spooler Fiscal HKA .NET DatqBox\library\rigazsaNetsoft.dll");
                foreach (var t in asm.GetTypes())
                {
                    if (t.IsPublic)
                    {
                        Console.WriteLine("CLASS: " + t.FullName);
                        foreach (var m in t.GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static | BindingFlags.DeclaredOnly))
                        {
                            Console.WriteLine("  METHOD: " + m.Name + " returns " + m.ReturnType.Name);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }
    }
}
