package game.scenes.survival1.cave.popups
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.scenes.survival1.cave.Cave;
	import game.ui.popup.Popup;
	
	public class BearPopup extends Popup
	{
		public function BearPopup(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
			
			this.transitionIn = new TransitionData();
			this.transitionIn.duration = 0.3;
			this.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			this.transitionOut = this.transitionIn.duplicateSwitch();
			
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
			this.autoOpen 			= true;
			this.groupPrefix = "scenes/survival1/cave/bearPopup/";
			this.screenAsset = "bearPopup.swf";
			
			this.load();
		}
		
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			var display:DisplayObject = this.screen.content;
			display.x = this.shellApi.viewportWidth / 2;
			display.y = this.shellApi.viewportHeight / 2;
			
			ButtonCreator.createButtonEntity(this.screen.content.tryAgainButton, this, onTryAgainClicked, null, null, null, true, true, 2);
		}
		
		private function onTryAgainClicked(entity:Entity):void
		{
			this.shellApi.loadScene(Cave);
		}
	}
}