using Nuke.Common;
using static Nuke.Common.IO.PathConstruction;
using Nuke.CodeGeneration;

partial class Build : NukeBuild
{
    Target GenerateNukeTools => _ => _
    .Executes(() =>
    {
        AbsolutePath buildDirectory = RootDirectory / "build";
        CodeGenerator.GenerateCode(buildDirectory / "tools");
    });
}
