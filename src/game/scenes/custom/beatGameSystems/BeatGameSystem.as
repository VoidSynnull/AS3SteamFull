package game.scenes.custom.beatGameSystems
{
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import ash.core.Node;
	
	import game.scenes.custom.BeatGamePower;
	import game.systems.GameSystem;
	
	/**
	 * system for Beat Game Popup
	 * @author uhockri
	 */
	public class BeatGameSystem extends GameSystem
	{
		private var _threshold:Number = 640;
		private var _startTime:Number = getTimer();
		private var _secs:Number = 0;
		private var _droppers:Array = [];
		
		// pulled from BeatGamePower
		private var _game:BeatGamePower;
		private var _notes:Array;
		private var _gameClip:MovieClip;
		private var _targetY:Number;
		private var _finalY:Number;
		
		public function BeatGameSystem(game:BeatGamePower, notes:Array):void
		{
			_game = game;
			_notes = notes;
			_gameClip = game.screen;
			_targetY = game.targetY;
			_finalY = game.targetY;
			
			// setup game with any notes that need to appear initially within range of 640
			for (var i:int = notes.length -1; i != -1; i--)
			{
				var note:Array = notes[i];
				for (var j:int = note.length -1; j != -1; j--)
				{
					if (note[j] < _threshold)
					{
						createDrop(i, _targetY - note[j]);
						note.splice(j, 1);
					}
				}
			}

			super( Node, updateNode);
		}
		
		/**
		 * Creating dropping object 
		 * @param noteNum
		 * @param y
		 */
		private function createDrop(noteNum:int, y:Number):void
		{
			if (_game.playing)
			{
				var drop:Object = _game.bitmaps[noteNum];
				if (drop)
				{
					// create bitmap and add to game
					var bmp:Bitmap = new Bitmap(drop.bd);
					bmp = Bitmap(_gameClip.addChild(bmp));
					// position bitmap in game
					bmp.x = drop.x;
					bmp.y = y;
					// create dropper object with properties
					var dropper:Object = {num:noteNum, bm:bmp, startY:y, currY:y};
					// add to array
					_droppers.push(dropper);			
					// move behind black border
					_gameClip.swapChildren(bmp, _gameClip.border);
				}
			}
		}
		
		/**
		 * check if dropper is overlapping drum 
		 * @param num
		 * @param overlap
		 * @return Boolean
		 */
		public function checkDrum(num:int, overlap:Number):Boolean
		{
			for (var i:int = _droppers.length -1; i != -1; i--)
			{
				var dropper:Object = _droppers[i];
				if ((dropper.num == num) && (_finalY - dropper.currY < overlap))
				{
					_gameClip.removeChild(dropper.bm);
					_droppers.splice(i,1);
					return true;
				}
			}
			return false;
		}
		
		private function updateNode( node:Node, eTime:Number ):void
		{
			if (_game.playing)
			{
				var currTime:Number = getTimer();
				
				// fade large drop
				if (_game.largeDrop)
				{
					// scale down from button scale to 1
					var scale:Number = _game._buttonScale * (1 - ((currTime - _game.largeDrop.start) / _game.largeDrop.time));
					if (scale < 1)
						scale = 1;
					
					_game.largeDrop.scaleX = _game.largeDrop.scaleY = scale;
					_game.largeDrop.x = _game.largeDrop.centerX - _game.largeDrop.width/2;
					_game.largeDrop.y = _game.largeDrop.centerY - _game.largeDrop.height/2;

					if (scale == 1)
						_game.largeDrop = null;
				}
				
				// calculate elapsed time and seconds remaining
				var elapsedTime:Number = currTime - _startTime;
				
				// if timeout, end game
				if (elapsedTime >= _game._timeout * 1000)
				{
					_game.endGame();
					return;
				}
				
				// update bar length
				if (_gameClip.meter)
					_gameClip.meter.bar.height = _game.barLength * elapsedTime / _game._timeout / 1000;
					
				// update distance
				var distance:Number = _game._speed * elapsedTime / 1000;
				
				// look for any new notes to add to scene
				for (var i:int = _notes.length -1; i != -1; i--)
				{
					var note:Array = _notes[i];
					for (var j:int = note.length -1; j != -1; j--)
					{
						if (note[j] < _threshold)
						{
							createDrop(i, _targetY - note[j] - distance);
							note.splice(j, 1);
						}
					}
				}
				
				// update target y and threshold
				_targetY = _finalY + distance;
				_threshold = 640 + distance;
				
				// move droppers down
				for (i = _droppers.length -1; i != -1; i--)
				{
					var dropper:Object = _droppers[i];
					dropper.currY = dropper.startY + distance;
					dropper.bm.y = dropper.currY;
					// fade dropper in as it drops from 0 to 1.0
					dropper.bm.alpha = 1 - (_finalY - dropper.currY) / 640;
					
					// remove dropper if reach target
					if (dropper.currY >= _finalY)
					{
						_gameClip.removeChild(dropper.bm);
						_game.missHit();
						_droppers.splice(i,1);
					}
				}
			}
		}
	}
}