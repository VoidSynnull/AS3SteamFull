package game.proxy
{
	import flash.net.URLVariables;

	public interface ITrackingManager
	{
		function track(event:String, platform:String = null, choice:String = null, subchoice:String = null, campaign:String = null, cluster:String = null, scene:String = null, grade:String = null, gender:String = null, numValLabel:String = null, numVal:Number = NaN, count:String = null, vars:URLVariables = null):void
		function trackPageView(island:String, scene:String):void
	}
}