using Newtonsoft.Json;
using Nuke.Common;
using Nuke.Common.Tooling;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

partial class Build : NukeBuild
{
    [Parameter("GitHub repository name to look for in the retention policy")]
    readonly string GitHubRepositoryName;

    [Parameter("Azure Container Registry instance name")]
    readonly string ACRName;

    Target ExecuteRetentionPolicy => _ => _
        .Executes(async () => {               
            var allRepositoryNames = BaseRepositoryNames.Concat(XcRepositoryNames).Concat(XpRepositoryNames);

            var timeStampsInGitHubReleases = await GetTimestampsInGitHubReleases(GitHubRepositoryName);
            Console.WriteLine("Timestamps currently present as release in GitHub");
            Console.WriteLine(string.Join(Environment.NewLine, timeStampsInGitHubReleases));

            foreach (var repositoryName in allRepositoryNames)
            {
                CleanACRImages(ACRName, repositoryName, timeStampsInGitHubReleases);
            }
        });

    private void CleanACRImages(string registryName, string repositoryName, IEnumerable<string> timestamps)
    {
        var tagsInACR = GetTagsInACR(registryName, repositoryName);
        Console.WriteLine("Tags currently present in ACR:");
        Console.WriteLine(string.Join(Environment.NewLine, tagsInACR));

        var tagsToBeDeleted = tagsInACR.Where(x => !timestamps.Contains(GetTimeStamp(x)));

        foreach (var tag in tagsToBeDeleted)
        {
            Console.WriteLine($"Deleting {tag}");
            ProcessTasks.StartProcess("az", $"acr repository delete -n {registryName} --image {repositoryName}:{tag} --yes").AssertZeroExitCode();
        }
    }

    private IEnumerable<string> GetTagsInACR(string registryName, string repositoryName)
    {
        var showTagsProcess = ProcessTasks.StartProcess("az", $"acr repository show-tags -n {registryName} --repository {repositoryName}").AssertZeroExitCode();
        var textOutput = string.Join(' ', showTagsProcess.Output.Select(x => x.Text));
        var tags = JsonConvert.DeserializeObject<string[]>(textOutput);

        return tags;
    }

    private async Task<IEnumerable<string>> GetTimestampsInGitHubReleases(string gitHubRepositoryName)
    {
        using (var httpClient = new HttpClient())
        {
            httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("NUKE Retention Policy");

            var gitHubReleasesResponse = await httpClient.GetStringAsync($"https://api.github.com/repos/{gitHubRepositoryName}/releases");
            
            dynamic[] gitHubReleases = JsonConvert.DeserializeObject<dynamic[]>(gitHubReleasesResponse);

            var tags = gitHubReleases.Select(x => (string)x.tag_name);

            var timestamps = tags.Select(GetTimeStamp);

            return timestamps;
        }
    }

    private string GetTimeStamp(string tag)
    {
        return tag.Split('-').Last();
    }
}

