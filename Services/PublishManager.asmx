<%@ WebService Language = "C#" Class="PublishManager" %>
using System.Collections.Generic;
using System.Linq;
using System.Web.Services;
using Sitecore.Jobs;


[WebService(Namespace = "http://tempuri.org/")]
[WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
[System.ComponentModel.ToolboxItem(false)]
public class PublishManager : System.Web.Services.WebService
{
	[WebMethod(Description = "Publishes all content")]
	public bool PublishAll(string token)
	{
		if (string.IsNullOrEmpty(token))
			return false;
		if (token != "[TOKEN]")
			return false;
		var db = Sitecore.Configuration.Factory.GetDatabase("master");
		var item = db.GetRootItem();
		var publishingTargets = Sitecore.Publishing.PublishManager.GetPublishingTargets(item.Database);

		foreach (var publishingTarget in publishingTargets)
		{
			var targetDatabaseName = publishingTarget["Target database"];
			if (string.IsNullOrEmpty(targetDatabaseName))
				continue;

			var targetDatabase = Sitecore.Configuration.Factory.GetDatabase(targetDatabaseName);
			if (targetDatabase == null)
				continue;

			var publishOptions = new Sitecore.Publishing.PublishOptions(
				item.Database,
				targetDatabase,
				Sitecore.Publishing.PublishMode.Smart,
				item.Language,
				System.DateTime.Now);

			var publisher = new Sitecore.Publishing.Publisher(publishOptions);
			publisher.Options.RootItem = item;
			publisher.Options.Deep = true;
			publisher.PublishAsync();
		}
		return true;
	}
	[WebMethod(Description = "Checks index rebuild status")]
	public string[] PublishStatus()
	{
		return JobManager.GetJobs().Where(x => !x.IsDone && x.Name.StartsWith("Publish")).Select(x =>
			x.Status.Processed + " -> " + x.Name).ToArray();
	}
}