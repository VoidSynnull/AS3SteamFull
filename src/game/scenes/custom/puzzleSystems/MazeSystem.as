package game.scenes.custom.puzzleSystems
{
	import flash.display.MovieClip;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import ash.core.Node;
	
	import engine.managers.SoundManager;
	
	import game.scenes.custom.MazeGame;
	import game.systems.GameSystem;
	import game.util.AudioUtils;
	
	/**
	 * system for Maze game
	 * @author uhockri
	 */
	public class MazeSystem extends GameSystem
	{
		private const dialogDuration:int = 1000;
		private const dialogFade:int = 1000;
		
		private var _game:MazeGame;			// reference to game
		private var healthLoss:int = 0;		// number of health losses
		private var startWalkTime:Number;	// start time when beginning to walk
		private var dialogClip:MovieClip;	// reference to dialog clip
		private var dialogTime:int;		// dialog start time
		
		// get start game time
		private var _startTime:Number = getTimer();
		
		public function MazeSystem(game:MazeGame):void
		{
			_game = game;
			super( Node, updateNode);
		}
		
		// when starting to walk to next cell
		public function startWalk():void
		{
			_game.walking = true;
			setHealthFrame("walk");
			// get current time
			startWalkTime = getTimer();
		}
		
		private function updateNode( node:Node, eTime:Number ):void
		{
			// calculate time remaining and speed up for health loss
			// a health will cut time in half
			var elapsedTime:int = getTimer() - _startTime;
			var remainingTime:int = (_game._timeout / (1 + healthLoss) - elapsedTime);
			if (remainingTime < 0)
				remainingTime = 0;
			
			// update meter
			_game.meter.width = _game.meterLength * remainingTime / _game._timeout;
			
			// walk player
			if (_game.walking)
			{
				var player:MovieClip = _game.player;
				
				// get elapsed time from start walk time
				var elapsedWTime:Number = getTimer() - startWalkTime;
				// if reached end of walk
				if (elapsedWTime >= _game._walkTime)
				{
					// turn off walking
					_game.walking = false;
					setHealthFrame("idle");
					
					// force destination
					player.x = player.destX;
					player.y = player.destY;
					
					// check states
					switch (_game.state)
					{
						case "powerdown":
							loseHealth();
							_game.state = null;
							break;
						case "powerup":
							restoreHealth();
							_game.state = null;
							break;
						case "win":
							_game.endGame(true);
							break;
					}
				}
				// is still moving
				else
				{
					// move based on elapsed time
					var fraction:Number = elapsedWTime/_game._walkTime;
					player.x = player.startX + player.distX * fraction;
					player.y = player.startY + player.distY * fraction;
				}
			}
			
			// update dialog
			if (dialogClip != null)
			{
				var elapsed:int = getTimer() - dialogTime;
				if (elapsed > dialogDuration + dialogFade)
				{
					dialogClip = null;
				}
				else if (elapsed > dialogDuration)
				{
					dialogClip.alpha = 1 - (elapsed - dialogDuration) / dialogFade;
				}
			}
			
			// if timeout, then end game
			if (remainingTime == 0)
			{
				_game.endGame();
			}			
		}
		
		// set frame name based on health loss
		private function setHealthFrame(name:String):void
		{
			var frames:Number = healthLoss;
			if (frames > _game._maxLossFrames)
				frames = _game._maxLossFrames;
			_game.player.gotoAndStop(name + frames);
		}
		
		// when lose health
		private function loseHealth():void
		{
			// play alarm sound when first time losing health
			if ((_game._alarmSound != null) && (healthLoss == 0))
				AudioUtils.play(_game.shellApi.sceneManager.currentScene, SoundManager.EFFECTS_PATH + _game._alarmSound, 1, true, null, "alarmSound");
			
			healthLoss++;
			
			// show flashing meter
			_game.meter.gotoAndStop(2);
			
			// set player idle frame based on health
			setHealthFrame("idle");
			
			// show dialog
			if (_game.loseHealthClip != null)
			{
				dialogTime = getTimer();
				dialogClip = _game.loseHealthClip;
				dialogClip.x = _game.player.x;
				dialogClip.y = _game.player.y;
				dialogClip.alpha = 1;
			}
			
			// show flashing text
			if (_game.flashingText != null)
			{
				_game.flashingText.visible = true;
			}
		}
		
		// when restore health
		private function restoreHealth():void
		{
			// if restoring health when health is down
			if (healthLoss > 0)
			{
				healthLoss--;
				
				// show dialog
				if (_game.restoreHealthClip != null)
				{
					dialogTime = getTimer();
					dialogClip = _game.restoreHealthClip;
					dialogClip.x = _game.player.x;
					dialogClip.y = _game.player.y;
					dialogClip.alpha = 1;
				}
			}
			
			// if back to normal
			if (healthLoss == 0)
			{
				// stop alarm sound
				if (_game._alarmSound != null)
					AudioUtils.stop(_game.shellApi.sceneManager.currentScene, null, "alarmSound");
				
				// restore flashing meter
				_game.meter.gotoAndStop(1);
				
				// hide flashing text
				if (_game.flashingText != null)
				{
					_game.flashingText.visible = false;
				}
			}
			// set player idle frame based on health
			setHealthFrame("idle");
		}
		
		public function endGame():void
		{
			// stop alarm sound
			if (_game._alarmSound != null)
				AudioUtils.stop(_game.shellApi.sceneManager.currentScene, null, "alarmSound");
		}
	}
}