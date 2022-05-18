package game.ui.hud
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import engine.components.Spatial;
	
	public class HudPopMobile extends HudPopBrowser
	{
		public function HudPopMobile(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		///////////////////////////////////////// REALMS BUTTON /////////////////////////////////////////
		// remove once realms is ready for mobile
		override protected function createRealmsButton(btnClip:MovieClip, index:int, name:String, startSpatial:Spatial):void
		{
			// realms is not active in  mobile
			// if debug is not true, then we remove the asset and don't create the button
			if( btnClip )
			{
				btnClip.parent.removeChild(btnClip);
			}
		}
		
		///////////////////////////////////////// FRIENDS BUTTON /////////////////////////////////////////
		// remove once friends is ready for mobile
		override protected function createFriendsButton( btnClip:MovieClip, index:int, name:String, startSpatial:Spatial ):void 
		{
			// friends is not active in  mobile, and is used for debug console access
			// if debug is not true, then we remove the asset and don't create the button
			// Not being used for debug console anymore. HUD has a separate button for this.
			if( btnClip )
			{
				btnClip.parent.removeChild(btnClip);
			}
		}
	}
}