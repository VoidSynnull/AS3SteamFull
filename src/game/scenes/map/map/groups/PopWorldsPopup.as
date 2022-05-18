package game.scenes.map.map.groups
{
	
	import flash.display.DisplayObjectContainer;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.ui.popup.Popup;


	public class PopWorldsPopup extends Popup
	{
		public function PopWorldsPopup(placementName:String, container:DisplayObjectContainer = null)
		{
			super(container);
			
			this.id 				= "PlacementPopup";
			this.groupPrefix 		= "scenes/map/map/custom/"+placementName+"/";
			this.screenAsset 		= "popup.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			positionPopup();
			setupButtons();
		}
		
		private function positionPopup():void
		{
			var width:Number 	= this.shellApi.viewportWidth;
			var height:Number 	= this.shellApi.viewportHeight;
			
			this.screen.x = width / 2;
			this.screen.y = height / 2;
		}
		
		private function setupButtons():void
		{
			// setup stay button
			ButtonCreator.createButtonEntity(this.screen["button_stay"], this, this.close, null, null, null, true, true);
			
			// setup play button
			ButtonCreator.createButtonEntity(this.screen["button_play"], this, this.gotoPopWorlds, null, null, null, true, true);
			
		}
		
		private function gotoPopWorlds(entity:Entity):void
		{
			
			var req:URLRequest = new URLRequest( "https://go.onelink.me/aNyo?pid=Poptropica1&c=Map&af_web_dp=https%3A%2F%2Fwww.poptropica.com%2Fworlds%2Fplay%2F" );
			navigateToURL(req, '_self');
		}
	}
}