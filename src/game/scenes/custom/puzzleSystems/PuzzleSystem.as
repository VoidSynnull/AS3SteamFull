package game.scenes.custom.puzzleSystems
{
	import com.poptropica.AppConfig;
	
	import flash.display.MovieClip;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import ash.core.Node;
	
	import game.scenes.custom.PuzzleGame;
	import game.systems.GameSystem;
	
	/**
	 * system for Beat Game Popup
	 * @author uhockri
	 */
	public class PuzzleSystem extends GameSystem
	{
		// reset variables
		private var _startTime:Number = getTimer();
		private var _secs:int = 0;
		private var _segments:int = 0;
		
		// pulled from PuzzleGame
		private var _game:PuzzleGame;
		private var _gameClip:MovieClip;
		
		public function PuzzleSystem(game:PuzzleGame):void
		{
			_game = game;
			_gameClip = game.screen;
			super( Node, updateNode);
		}
		
		private function updateNode( node:Node, eTime:Number ):void
		{
			// if not waiting for end dialog
			if (!_game.doWait)
			{
				// get current time
				var currTime:Number = getTimer();
				
				// calculate seconds remaining
				var elapsedSecs:int = Math.floor((currTime - _startTime) / 1000);
				var remainingSecs:int = _game.currentTimeout - elapsedSecs;
				// if new second
				if (remainingSecs != _secs)
				{
					_secs = remainingSecs;
					
					// update timer display
					var _mins:int = Math.floor(_secs/60);
					var _leftoverSecs:int = _secs - _mins * 60;
					var display:String = String(_mins) + ":"
					if (_leftoverSecs < 10)
					{
						display += ("0" + _leftoverSecs);
					}
					else
					{
						display += _leftoverSecs;
					}
					_gameClip.timer.text = display;
					
					// if timeout, then end game
					if (_secs <= 0)
					{
						_game.endGame();
						return;
					}				
				}
				
				// check for segments if bubble text
				if (_game._hasBubble)
				{
					// calculate current segment
					var seg:int = Math.floor((_game.currentTimeout - remainingSecs) / _game._segmentTime);
					// if into new segment
					if (seg != _segments)
					{
						_segments = seg;
						// if text exists in array (both encouragement and struggle text need to have same number of elements)
						if (seg < _game._encouragementText.length + 1)
						{
							// if less pieces than calculated number based on time, then display struggle text, else show encouragement text
							if (_game.count < Math.round(_game.currentNumPieces * elapsedSecs / _game.currentTimeout))
							{
								_game.showMessage(_game._struggleText[seg-1]);
							}
							else
							{
								_game.showMessage(_game._encouragementText[seg-1]);
							}
						}
					}
				}
				
				// rollover highlights if web
				if (!AppConfig.mobile)
				{
					_game.checkRollovers();
				}
			}
		}		
	}
}