using Nuke.Common;
using Nuke.Common.Tooling;

/* 
 * Because docker-compose puts warnings on the error output, warnings from docker-compose are reported as errors by NUKE.
 * Because we specified "customLogger": true in DockerCompose.json, we can intercept the logging
 * and log the outputs which start with "warning" as warnings.
 *  
 * If the output does not start with "warning", the default logger can handle it.
 */

public static partial class DockerComposeTasks
{
    public static void CustomLogger(OutputType type, string output)
    {
        if (type == OutputType.Err &&
            (
                (output.StartsWith("Creating") || output.StartsWith("Starting") || output.StartsWith("Stopping") || output.StartsWith("Removing")) && 
                !output.EndsWith("failed")))
        {
            Logger.Info(output);
        }
        else
        {
            ProcessTasks.DefaultLogger(type, output);
        }
    }
}
