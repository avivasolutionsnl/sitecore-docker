// Generated with Nuke.CodeGeneration version 0.18.0 (Windows,.NETStandard,Version=v2.0)

using JetBrains.Annotations;
using Newtonsoft.Json;
using Nuke.Common;
using Nuke.Common.Execution;
using Nuke.Common.Tooling;
using Nuke.Common.Tools;
using Nuke.Common.Utilities.Collections;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Linq;
using System.Text;

[PublicAPI]
[ExcludeFromCodeCoverage]
public static partial class DockerComposeTasks
{
    /// <summary>
    ///   Path to the DockerCompose executable.
    /// </summary>
    public static string DockerComposePath =>
        ToolPathResolver.TryGetEnvironmentExecutable("DOCKERCOMPOSE_EXE") ??
        ToolPathResolver.GetPathExecutable("docker-compose");
    public static Action<OutputType, string> DockerComposeLogger { get; set; } = CustomLogger;
    public static IReadOnlyCollection<Output> DockerCompose(string arguments, string workingDirectory = null, IReadOnlyDictionary<string, string> environmentVariables = null, int? timeout = null, bool? logOutput = null, bool? logInvocation = null, Func<string, string> outputFilter = null)
    {
        var process = ProcessTasks.StartProcess(DockerComposePath, arguments, workingDirectory, environmentVariables, timeout, logOutput, logInvocation, DockerComposeLogger, outputFilter);
        process.AssertZeroExitCode();
        return process.Output;
    }
}
