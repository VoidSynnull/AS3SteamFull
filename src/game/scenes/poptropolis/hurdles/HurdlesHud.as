package game.scenes.poptropolis.hurdles
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.UIView;
	import engine.managers.SoundManager;
	
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class HurdlesHud extends UIView
	{
		public var exitClicked:Signal;
		public var startGunFire:Signal;
		
		private var _exitBtn:Entity;
		private var _countClip:Entity;
		
		private var _startTimer:Timer;
		private var _countdownNum:int;
		
		public function HurdlesHud(container:DisplayObjectContainer=null)
		{
			super(container);
			super.id = "gameHud";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// set the prefix for the assets path.
			super.groupPrefix = "scenes/poptropolis/hurdles/";
			
			// Create this groups container.
			super.init(container);
			
			// load this groups assets.
			load();
			
			exitClicked = new Signal();
			startGunFire = new Signal();
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

			clip = MovieClip(super.screen.btnExitPractice);
			_exitBtn = ButtonCreator.createButtonEntity(clip, this, onExitBtnUp );
			showExitPractice( false );
			
			clip = MovieClip(super.screen.mcCountdown)
			_countClip = new Entity()
			_countClip.add(new Display(clip))
			setCountdownText ("")
			
			// Call the parent classes loaded() method so it knows this Group is ready.
			super.loaded();
		}

		/**
		 * Makes 'Exit Practice' button visible. 
		 * @param show
		 */
		public function showExitPractice (show:Boolean = true ):void 
		{
			(_exitBtn.get(Display) as Display).visible = show;
		}
		
		private function onExitBtnUp ( entity:Entity ):void 
		{
			exitClicked.dispatch();
		}

		/**
		 * Start countdown hud. 
		 */
		public function startCountdown ():void 
		{
			_countdownNum = 3;
			SceneUtil.addTimedEvent( this.parent, new TimedEvent( 1, _countdownNum, decrementCountDown ) );
			_countClip.get(Display).displayObject.visible = true;
			
			decrementCountDown();
		}
		
		private function setCountdownText ( value:String ):void 
		{
			_countClip.get(Display).displayObject.tf.text = value;
		}

		private function decrementCountDown():void 
		{	
			if (_countdownNum == 0 ) 
			{
				startGunFire.dispatch();
				setCountdownText("");
				_countClip.get(Display).displayObject.visible = false;
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "countdown_02" +".mp3");
			}
			else 
			{
				setCountdownText( String(_countdownNum) );
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "countdown_01" +".mp3");
				_countdownNum--;
			}
		}
	}
}


