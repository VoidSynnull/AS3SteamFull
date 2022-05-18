getStaticHost();
function getStaticHost()
{
	var staticHost = window.location.host;
	if (staticHost.indexOf("www") != -1)
		staticHost = "static" + staticHost.substr(3);
	else
	{
		var dotPos = staticHost.indexOf(".")
		staticHost = staticHost.substr(0,dotPos+1) + "static" + staticHost.substr(dotPos);
	}
	staticHost = "https://" + staticHost;
	alert(staticHost);
}