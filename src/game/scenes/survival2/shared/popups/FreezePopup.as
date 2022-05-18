package game.scenes.survival2.shared.popups
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.scenes.survival2.beaverDen.BeaverDen;
	import game.scenes.survival2.fishingHole.FishingHole;
	import game.scenes.survival2.trees.Trees;
	import game.scenes.survival2.unfrozenLake.UnfrozenLake;
	import game.ui.popup.Popup;
	
	public class FreezePopup extends Popup
	{
		public function FreezePopup( container:DisplayObjectContainer = null )
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
			this.groupPrefix = "scenes/survival2/shared/freezePopup/";
			this.screenAsset = "freezePopup.swf";
			
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
			switch( shellApi.sceneName )
			{
				case "FishingHole":
					shellApi.loadScene( FishingHole);
					break;
				
				case "Trees":
					shellApi.loadScene( Trees );
					break;
				
				case "UnfrozenLake":
					shellApi.loadScene( UnfrozenLake, 3646, 1410 );
					break;
				
				case "BeaverDen":
					shellApi.loadScene( BeaverDen );
					break;
			}
		}
	}
}

