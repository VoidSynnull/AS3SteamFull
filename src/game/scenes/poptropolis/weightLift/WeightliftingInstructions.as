package game.scenes.poptropolis.weightLift
{
	import ash.core.Entity;
	
	import engine.components.Interaction;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	import org.osflash.signals.Signal;
	
	public class WeightliftingInstructions extends Popup {
		
		public var startClicked:Signal
		public var practiceClicked:Signal
		
		public function WeightliftingInstructions(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			startClicked = new Signal( );
			practiceClicked = new Signal( );
			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/poptropolis/weightLift/";
			super.init(container);
			super.autoOpen = false;
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["weightliftingInstructions.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{	
			super.screen = super.getAsset("weightliftingInstructions.swf", true) as MovieClip;
			//super.layout.centerUI(super.screen.content);
			super.loaded();
			super.open();
			
			var clip:MovieClip = MovieClip(super.screen.content.btnStart);
			var _startBtn:Entity = ButtonCreator.createButtonEntity(clip, this);
			var interaction:Interaction  = Interaction(_startBtn.get(Interaction));
			interaction.upNative.add( onStartBtnUp );
			
			clip = MovieClip(super.screen.content.btnPractice);
			var _practiceBtn:Entity = ButtonCreator.createButtonEntity(clip, this);
			interaction  = Interaction(_practiceBtn.get(Interaction));
			interaction.upNative.add( onPracticeBtnUp );
		}
		
		private function onStartBtnUp (e:Event):void {
			startClicked.dispatch();
			super.close()
		}
		
		private function onPracticeBtnUp (e:Event):void {
			practiceClicked.dispatch();
			super.close()
		}
	}
}