<%@ WebService Language = "C#" Class="SearchManager" %>
using System.Collections.Generic;
using System.Linq;
using System.Web.Services;
using Sitecore.ContentSearch.Maintenance;
using Sitecore.Jobs;


[WebService(Namespace = "http://tempuri.org/")]
[WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
[System.ComponentModel.ToolboxItem(false)]
public class SearchManager : System.Web.Services.WebService
{
	[WebMethod(Description = "Rebuilds all Search Indexes")]
	public bool RebuildIndexes(string token)
	{
		if (string.IsNullOrEmpty(token))
			return false;
		if (token != "[TOKEN]")
			return false;
		IndexCustodian.RebuildAll().ForEach(x => x.Start());
		return true;
	}
	[WebMethod(Description = "Checks index rebuild status")]
	public string[] RebuildStatus()
	{
		return JobManager.GetJobs().Where(x => !x.IsDone && x.Name.StartsWith("Index_Update_Index")).Select(x =>
			$"{x.Status.Processed} -> {x.Name.Substring(23)}").ToArray();
	}
}