package game.scenes.survival3.shared.popups
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.scenes.survival3.valleyLeft.ValleyLeft;
	import game.ui.popup.Popup;
	
	public class RavinePopup extends Popup
	{
		public function RavinePopup( container:DisplayObjectContainer = null )
		{
			super( container );
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.init(container);
			
			this.transitionIn = new TransitionData();
			this.transitionIn.duration = 0.3;
			this.transitionIn.startPos = new Point( 0, -super.shellApi.viewportHeight );
			this.transitionOut = this.transitionIn.duplicateSwitch();
			
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
			this.autoOpen 			= true;
			this.groupPrefix = "scenes/survival3/shared/popups/";
			this.screenAsset = "ravinePopup.swf";
			
			this.load();
		}
		
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			super.open();
			
			var display:DisplayObject = this.screen.content;
			display.x = this.shellApi.viewportWidth / 2;
			display.y = this.shellApi.viewportHeight / 2;
			
			ButtonCreator.createButtonEntity(this.screen.content.tryAgainButton, this, onTryAgainClicked, null, null, null, true, true, 2);
		}
		
		private function onTryAgainClicked( entity:Entity ):void
		{
			trace(shellApi.sceneName);
			switch( shellApi.sceneName )
			{
				case "ValleyLeft":
					shellApi.loadScene( ValleyLeft, 1076, 2170 );
					break;

			}
		}
	}
}

