package game.scenes.hub.skydive
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import game.components.Timer;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.scenes.hub.chooseGame.ChooseGame;
	import game.ui.popup.Popup;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class Result extends Popup
	{
		private var message:TextField;
		private const seconds:int = 5;
		private var countdown:int = seconds;
		
		public function Result(result:String, container:DisplayObjectContainer=null)
		{
			super(container);
			
			_result = result;
		}
		
		override public function destroy():void
		{
			clearTimer();
			playAgainClicked.removeAll();
			doneCountdown.removeAll();
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			playAgainClicked = new Signal();
			doneCountdown = new Signal();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/hub/skydive/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.loadFiles(new Array("result.swf"), false, true, loaded);
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset("result.swf", true) as MovieClip;

			super.screen.center.resultText.text = _result;
			message = super.screen.center.message;

			super.centerWithinDimensions(super.screen.center);
			
			super.fitToDimensions(super.screen.bg, true);

			super.screen.center.playAgainButton.mouseChildren = false;
			ButtonCreator.createButtonEntity(super.screen.center.playAgainButton, this, handlePlayAgainClicked);
			ButtonCreator.createButtonEntity(super.screen.center.leaveGameButton, this, backToChooser);
			ButtonCreator.loadCloseButton(this, super.screen, backToChooser);
			
			var timedEvent:TimedEvent = new TimedEvent(1, seconds, updateTime);
			SceneUtil.addTimedEvent(this, timedEvent, "countdown");
			
			super.loaded();
		}
		
		private function clearTimer():void
		{
			var timer:Timer = SceneUtil.getTimer(this, "countdown");
			if (timer != null)
			{
				timer.timedEvents = new Vector.<TimedEvent>();
			}
		}

		private function updateTime():void
		{
			countdown--;
			message.text = String(countdown) + " seconds until game is closed";
			if (countdown == 0)
			{
				doneCountdown.dispatch();
				clearTimer();
			}
		}
				
		private function handlePlayAgainClicked(buttonEntity:Entity):void
		{
			clearTimer();
			playAgainClicked.dispatch(countdown);
		}
		
		private function backToChooser(buttonEntity:Entity):void
		{
			clearTimer();
			// go to choose game
			shellApi.loadScene(ChooseGame);
		}
		
		public var doneCountdown:Signal;
		public var playAgainClicked:Signal;
		private var _result:String;
	}
}