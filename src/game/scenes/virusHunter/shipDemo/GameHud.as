package game.scenes.virusHunter.shipDemo
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import engine.group.UIView;
	
	public class GameHud extends UIView
	{
		public function GameHud(container:DisplayObjectContainer=null)
		{
			super(container);
			super.id = "gameHud";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "scenes/virusHunter/shipDemo/popups/hud/";
			
			// Create this groups container.
			super.init(container);
			
			// load this groups assets.
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// do the asset load, and listen for the 'assetLoadComplete' to do setup.
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("hud.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			// get the screen movieclip from the loaded assets.
			super.screen = super.getAsset("hud.swf", true) as MovieClip;
			super.groupContainer.addChild(super.screen);
			
			this.scoreDisplay = super.screen.scoreDisplay;
			this.waveDisplay = super.screen.waveDisplay;
			this.shipLevelDisplay = super.screen.shipLevelDisplay;
			
			// Call the parent classes loaded() method so it knows this Group is ready.
			super.loaded();
		}
		
		public var scoreDisplay:TextField;
		public var waveDisplay:TextField;
		public var shipLevelDisplay:TextField;
	}
}