package game.scenes.poptropolis.weightLift
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.group.UIView;
	
	import game.components.ui.ToolTip;
	import game.creators.ui.ButtonCreator;
	
	import org.osflash.signals.Signal;
	
	public class WeightLiftHud extends UIView
	{
		public var exitClicked:Signal;
		private var toolTip:ToolTip;
		
		private var _exitBtn:Entity;
		
		public function WeightLiftHud(container:DisplayObjectContainer=null)
		{
			super(container);
			super.id = "gameHud";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "scenes/poptropolis/weightLift/";
			
			// Create this groups container.
			super.init(container);
			
			// load this groups assets.
			load();
			
			exitClicked = new Signal()			
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
			
			var clip:MovieClip
			var interaction:Interaction
			
			clip = MovieClip(super.screen.btnExitPractice);
			_exitBtn = ButtonCreator.createButtonEntity(clip, this);
			interaction = Interaction(_exitBtn.get(Interaction));
			interaction.upNative.add( onExitBtnUp );
			
			_exitBtn.get(Display).visible = false;
			toolTip = _exitBtn.get(ToolTip);
			_exitBtn.remove(ToolTip);
			
			// Call the parent classes loaded() method so it knows this Group is ready.
			super.loaded();
		}
		
		private function onExitBtnUp (e:Event):void {
			exitClicked.dispatch();
		}
		
		public function setupExitBtn ():void {
			_exitBtn.get(Display).visible = true;
			_exitBtn.add(toolTip);
		}
	}
}


