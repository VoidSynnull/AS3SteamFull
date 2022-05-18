package game.scenes.custom
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.scene.template.ads.RaceGame;
	import game.systems.GameSystem;
	
	public class RaceGameSystem extends GameSystem
	{
		private var _game:RaceGame;			// reference to race game
		private var _player:Entity;			// reference to player
		private var _progress:MovieClip;	// progress bar
		private var _dist:Number;
		private var _length:Number;			// initial length of progress bar
		
		public function RaceGameSystem(game:RaceGame, player:Entity, progress:MovieClip, dist:Number):void
		{
			// store game reference
			_game = game;
			_player = player;
			_progress = progress;
			_dist = dist;
			// get length of progress bar
			_length = progress.width;
			// set length to zero
			progress.width = 0;
			super( Node, updateNode, null, null );	
		}
		
		/**
		 * Update node
		 * @param node
		 * @param eTime
		 */
		private function updateNode( node:Node, eTime:Number ):void
		{
			_progress.width = _player.get(Spatial).x / _dist * _length;
		}
	}
}