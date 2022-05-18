package game.managers.interfaces
{
	import ash.core.Entity;
	
	import engine.group.Scene;
	
	import game.data.ads.AdData;
	import game.data.ads.CampaignData;

	public interface IAdManager
	{
		// NOTE :: Had to add these to prevent errors, would like to slim this down their usage eventually. -bard
		function prepSceneForAds(scene:Scene):void;
		function checkAdScene(scene:Scene, callback:Function):Boolean;
		function convertSceneType(sceneType:String):String;
		function getAdData(adType:String, offMain:Boolean = false, save:Boolean = false, island:String = null):AdData;
		function track(campaignName:String, event:String, choice:String = null, subChoice:String = null, numValLabel:String = null, numVal:Number = NaN, count:String = null):void
		function get mainStreetType():String;
		function get blimpType():String;
		function get countryCode():String;
		function visitSponsor(campaignType:String, useBumper:Boolean = false):void;
		function doorReached(char:Entity, door:Entity):void;
		function getActiveCampaign(campaignName:String):CampaignData;
		function AddCampaignCardsToProfile(itemsArray:Array, activeCampaigns:Array ):void
	}
}