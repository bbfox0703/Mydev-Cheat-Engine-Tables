#r "bin/Debug/net10.0-windows/AAToggleGenerator.dll"
#r "nuget: System.Xml.Linq, 4.3.0"

using System;
using System.Linq;
using System.Xml.Linq;
using AAToggleGenerator;

var ctFilePath = @"TestData\SRWV.CT";
var xml = XDocument.Load(ctFilePath);

// Mimic the filter logic from ScriptGenerator
var entries = xml.Descendants("CheatEntry")
    .Select(e => new {
        Id = e.Element("ID")?.Value ?? string.Empty,
        Description = e.Element("Description")?.Value ?? string.Empty,
        Depth = e.Ancestors("CheatEntry").Count(),
        IsAutoAssembler = e.Element("VariableType")?.Value == "Auto Assembler Script",
        HasOptionsWithMoHideChildren = e.Element("Options")?.Attributes()
            .Any(attr => attr.Name == "moHideChildren" && attr.Value == "1") == true,
        HasChildren = e.Element("CheatEntries") != null
    })
    .Where(e =>
        (e.IsAutoAssembler || e.HasOptionsWithMoHideChildren || e.HasChildren) &&
        !string.IsNullOrEmpty(e.Id))
    .ToList();

Console.WriteLine($"Total entries: {entries.Count}");
Console.WriteLine("First 10 entries:");
foreach (var entry in entries.Take(10))
{
    Console.WriteLine($"  ID: {entry.Id}, Depth: {entry.Depth}, Desc: {entry.Description}");
}
