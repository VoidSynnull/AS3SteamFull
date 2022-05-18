package game.data {
	import com.poptropica.AppConfig;
	

	import flash.utils.Dictionary;
	
	import game.util.DataUtils;
	import game.util.ProxyUtils;

/**
 * CommunicationData should be initialized before <code>Shell</code> runs <code>create()</code>.
 * @author Rich Martin
 */
public class CommunicationData
{

	public var gameHost:String;
	public var fileHost : String;
	public var staticHost : String;
	public var sfsHost : String;
	public var sfsDevHost : String;

	private var _phpURLDict:Dictionary = new Dictionary()

	public function CommunicationData( commConfigXML:XML=null )
	{
		parseCommConfigXML( commConfigXML );
	}

	public function parseCommConfigXML( commConfigXML:XML ):void
	{
		if( commConfigXML != null )
		{
			setupPHPDict( commConfigXML );
			assignHostConfig( commConfigXML );
		}
	}

	/**
	 * Assign host values specified in comfig XML.
	 * This method is generally replaced within the CreateConnection build step
	 * @param commConfigXML
	 */
	public function assignHostConfig( commConfigXML:XML ):void
	{
		trace("CommunicationData :: assignHostConfig : is production: " + AppConfig.production);
		if(AppConfig.production)
		{
			gameHost = DataUtils.getString(commConfigXML.host);
			fileHost = DataUtils.getString(commConfigXML.staticHost);
			staticHost = DataUtils.getString(commConfigXML.staticHost);
			sfsHost = DataUtils.getString(commConfigXML.sfs);
		}
		else
		{
			gameHost = DataUtils.getString(commConfigXML.testHost);
			fileHost = DataUtils.getString(commConfigXML.testHost);
			staticHost = DataUtils.getString(commConfigXML.testHost);
			sfsHost = DataUtils.getString(commConfigXML.sfsTest);
		}
		sfsDevHost = DataUtils.getString(commConfigXML.sfsTest);
		trace("CommunicationData :: assignHostConfig : set gameURL() gameHost:", gameHost, "fileHost:", fileHost, "staticHost:", staticHost);
	}

	/**
	 * For use in browser, derive the host from the application url
	 * @param commnData
	 * @param commConfigXML
	 */
	public function deriveBrowserHost():void
	{
		var applicationUrl:String = "https://";
		gameHost = ProxyUtils.getBrowserHostFromLoaderUrl( applicationUrl );
	}

	/**
	 * Creates Dictionary holding urls of php scripts.
	 * @param commConfigXML
	 */
	public function setupPHPDict( commConfigXML:XML ):void
	{
		var phpUrls:XMLList = commConfigXML.elements("url");

		var urlXML:XML;
		var numUrls:int = phpUrls.length();
		for (var i:int = 0; i < numUrls; i++)
		{
			urlXML = phpUrls[i] as XML;
			if( urlXML != null )
			{
				_phpURLDict[ DataUtils.getString(urlXML.attribute("id")) ] = DataUtils.getString( urlXML );
			}
		}
	}

	public function get baseURL():String 				{ return _phpURLDict["base"]; }
	public function get trackerURL():String 			{ return _phpURLDict["tracker"]; }
	public function get AMFPHPGatewayURL():String 		{ return _phpURLDict["amfphp"]; }
	public function get startedIslandsURL():String 		{ return _phpURLDict["started_islands"]; }
	public function get memberStatusURL():String 		{ return _phpURLDict["getMemberStatus"]; }
	public function get embedInfoURL():String 			{ return _phpURLDict["getEmbedInfo"]; }
	public function get changeLookURL():String 			{ return _phpURLDict["changeLook"]; }
	public function get visitSceneURL():String 			{ return _phpURLDict["visitScene"]; }
	public function get takePhotoURL():String 			{ return _phpURLDict["takePhoto"]; }
	public function get saveFeedItemURL():String 		{ return _phpURLDict["saveFeedItem"]; }
	public function get partialRegistrationURL():String { return _phpURLDict["partialRegistration"]; }
	public function get getClosetLooksURL():String 		{ return _phpURLDict["getClosetLooks"]; }
	public function get saveClosetLookURL():String 		{ return _phpURLDict["saveLookToCloset"]; }
	public function get deleteClosetLookURL():String 	{ return _phpURLDict["deleteLookFromCloset"]; }
	public function get surveyURL():String 				{ return _phpURLDict["survey"]; }
	public function get saveBinaryFileURL():String 		{ return _phpURLDict["saveBinaryFile"]; }
	public function get loginURL():String 		        { return _phpURLDict["login"]; }
	public function get changePasswordURL():String		{ return _phpURLDict["changePassword"]; }
	public function get parentalEmailURL():String		{ return _phpURLDict["parentalEmail"]; }
	public function get playerCreditsURL():String       { return _phpURLDict["getCredits"]; }
	public function get highScoreURL():String			{ return _phpURLDict["highScore"]; }
	public function get getQuidgetsURL():String			{ return _phpURLDict['getQuidgets']; }
	public function get getCompletionsURL():String		{ return _phpURLDict['getCompletions']; }
	public function get cancelMembership():String		{ return _phpURLDict['cancelMembership']; }
	public function get grantMeAccess():String			{ return _phpURLDict['grantMeAccess']; }

	/**
	 * This is not essential, but could be useful if it becomes necessary to defend
	 * against spoofed data.
	*/
	/*
	// NOT CURRENTLY IN USE
	public function get validIslandAS2Names():Vector.<String>
	{
		var result:Vector.<String> = new <String>[];
		for each (var islandAS2Name:XML in _commDataXML.islandAS2Name) {
			result.push(islandAS2Name.text());
		}
		return result;
	}
	*/

	// Helper function, not in use.
	/*
	private function firstListValue(list:XMLList):String
	{
		if (list) {
			if (list.length())
			{
				return list[0];
			}
		}
		return '';
	}
	*/

	/*
	private function deStaticizeHostname(name:String):String {
		var hostParts:Array = name.split('.');
		var hostname:String = '';
		for (var i:int=0; i<hostParts.length; i++) {
			if ('static' != hostParts[i]) {
				hostname += hostParts[i];
				if (i != hostParts.length-1) {
					hostname += '.';
				}
			}
		}
		return hostname;
	}
	*/

}

}
