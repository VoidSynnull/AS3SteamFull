package game.scenes.map.map.groups
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.ui.popup.Popup;
	import game.ui.hud.HudPopBrowser;


	public class LegendarySwordsMembership extends Popup
	{
		public function LegendarySwordsMembership(container:DisplayObjectContainer = null)
		{
			super(container);
			
			this.id 				= "LegendarySwordsMembership";
			this.groupPrefix 		= "scenes/map/map/custom/LegendarySwordsMembership/";
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
			
			this.shellApi.track("LSNonMemberPopup");
			
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
			// setup cancel button
			ButtonCreator.createButtonEntity(this.screen["button_cancel"], this, this.close, null, null, null, true, true);
			
			// setup membership button
			ButtonCreator.createButtonEntity(this.screen["button_membership"], this, this.getMembership, null, null, null, true, true);
		}
		
		private function getMembership(entity:Entity):void
		{
			HudPopBrowser.buyMembership(this.shellApi);
		}
	}
}