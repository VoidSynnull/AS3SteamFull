package game.scenes.poptropolis.poleVault
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.group.UIView;
	
	import game.creators.ui.ButtonCreator;
	
	import org.osflash.signals.Signal;
	
	public class PoleVaultHud extends UIView
	{
		public var exitClicked:Signal
		public var stopRaceClicked:Signal
		
		private var _exitBtn:Entity;
		private var _stopRaceBtn:Entity;
		
		
		public function PoleVaultHud(container:DisplayObjectContainer=null)
		{
			super(container);
			super.id = "gameHud";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "scenes/poptropolis/poleVault/";
			
			// Create this groups container.
			super.init(container);
			
			// load this groups assets.
			load();
			
			exitClicked = new Signal()
			stopRaceClicked = new Signal()
			
			
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
			
			clip = MovieClip(super.screen.btnStopRace);
			_stopRaceBtn = ButtonCreator.createButtonEntity(clip, this);
			clip.visible = false
			interaction = Interaction(_stopRaceBtn.get(Interaction));
			interaction.upNative.add( onStopRaceBtnUp );
			
			
			// Call the parent classes loaded() method so it knows this Group is ready.
			super.loaded();
		}
		
		
		private function onStopRaceBtnUp (e:Event):void {
			//trace ("[GameHud] -------------onStopRaceBtnUp")
			exitClicked.dispatch();
		}
		
		private function onExitBtnUp (e:Event):void {
			stopRaceClicked.dispatch();
		}
		
		public function setMode (s:String):void {
			trace ("[SkiingHud setMode:" + s +  "   _stopRaceBtn:" + _stopRaceBtn +   " _stopRaceBtn.get(Display):" + _stopRaceBtn.get(Display))
			if (_stopRaceBtn.get(Display)) {
				switch (s) {
					case "game":
						(_exitBtn.get(Display) as Display).visible = false;
						(_stopRaceBtn.get(Display) as Display).visible = false;
						break
					case "practice":
						(_exitBtn.get(Display) as Display).visible = true;
						(_stopRaceBtn.get(Display) as Display).visible = false;
						break
					case "clear":
						(_exitBtn.get(Display) as Display).visible = false;
						(_stopRaceBtn.get(Display) as Display).visible = false;
						break
				}
			}
		}	
		
		
		private function setVisibleFalse (mc:MovieClip):void {
			mc.visible = false
		}
		
	}
}






