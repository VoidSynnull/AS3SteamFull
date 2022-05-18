package game.scenes.hub.skydive
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.scenes.hub.arcade.Arcade;
	import game.ui.popup.Popup;
	import game.util.DisplayPositions;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class Start extends Popup
	{
		public function Start(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			startClicked = new Signal();
			
			super.groupPrefix = "scenes/hub/skydive/";
			super.init(container);
			load();
		}		
		
		override public function destroy():void
		{
			startClicked.removeAll();
			super.destroy();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.loadFiles(new Array("start.swf", "title.swf"), false, true, loaded);
		}
		
		// all assets ready
		override public function loaded():void
		{			
			// attach main asset
			super.screen = super.getAsset("start.swf", true) as MovieClip;
			// setup and positioning for title screen.
			_title = super.getAsset("title.swf", true) as MovieClip;
			_playButton = ButtonCreator.createButtonEntity(_title.buttonPlay, this, hideTitle);
			// the start button should always be centered and 40 px from the bottom.
			super.pinToEdge(_title.buttonPlay, DisplayPositions.BOTTOM_CENTER, 0, 40);
			// stretch the background to fit any size.
			super.fitToDimensions(_title.background, true);
			super.screen.addChild(_title);
			
			// setup and positioning for instructions screen
			super.centerWithinDimensions(super.screen.center);
			//super.fitToDimensions(super.screen.bg, true);
			ButtonCreator.createButtonEntity(super.screen.center.startButton, this, handleStartClicked);
			ButtonCreator.loadCloseButton(this, super.screen, backToArcade);
			
			super.loaded();
		}
		
		private function hideTitle(button:Entity):void
		{
			TweenUtils.globalTo(this, _title, .5, { alpha : 0, onComplete : removeTitle });
		}

		private function removeTitle():void
		{
			super.removeEntity(_playButton);
			_playButton = null;
			super.screen.removeChild(_title);
			_title = null;
		}
		
		private function backToArcade(...args):void
		{
			super.shellApi.loadScene(Arcade);
		}
		
		private function handleStartClicked(...args):void
		{
			startClicked.dispatch();
		}
		
		public var startClicked:Signal;
		private var _playButton:Entity;
		private var _title:MovieClip;
	}
}