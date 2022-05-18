package game.scenes.deepDive3.shared.popups {
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.scenes.deepDive1.DeepDive1Events;
	import game.ui.elements.MultiStateButton;
	import game.ui.popup.Popup;
	
	public class IntroPopup extends Popup {
		private var continueBtn:MultiStateButton;
		private var deepDive1Events:DeepDive1Events;
		public var _player:Entity;
		
		public function IntroPopup(container:DisplayObjectContainer=null) {
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
			this.groupPrefix = "scenes/deepDive3/shared/popups/";
			this.screenAsset = "introPopup.swf";
			
			this.load();
		}
		
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			ButtonCreator.createButtonEntity(this.screen.content.confirmButton, this, onConfirmClicked, null, null, null, true, true, 2);
			
			var display:DisplayObject = this.screen.content;
			display.x = this.shellApi.viewportWidth / 2;
			display.y = this.shellApi.viewportHeight / 2;			
		}
		
		private function onConfirmClicked(entity:Entity):void
		{
			super.shellApi.triggerEvent("buttonSound");
			close( false, transitionComplete );
		}
		
		private function transitionComplete():void
		{
			shellApi.triggerEvent( "triggerCloseIntro" );
			remove();
		}
	}
}


