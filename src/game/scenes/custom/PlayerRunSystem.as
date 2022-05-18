package game.scenes.custom
{
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	import ash.core.Node;
	
	import engine.components.Spatial;
	
	import game.scene.template.ads.RaceGame;
	import game.systems.GameSystem;
	
	public class PlayerRunSystem extends GameSystem
	{
		private var _game:RaceGame;				// reference to race game
		private var _speed:int = 0;				// speed of player
		private var _player:Spatial;			// player spatial
		private var _slowFraction:Number = 0;	// amount to slow player speed
		private var _slowTime:int = 0;			// length of time that player is slowed
		private var _startSlow:int;				// start time when player speed is slowed
		
		public function PlayerRunSystem(game:RaceGame):void
		{
			// store game reference
			_game = game;
			super( Node, updateNode, null, null );	
		}
		
		/**
		 * Set player speed
		 * @param speed
		 * @param player entity
		 */
		public function setPlayerSpeed(speed:int, player:Entity = null):void
		{
			if (player != null)
				_player = player.get(Spatial);
			_speed = speed;
		}
		
		/**
		 * Slow player temporarily
		 * @param fraction of current speed
		 * @param time in seconds until normal speed resumes
		 */
		public function slowDown(fraction:Number, time:Number):void
		{
			_slowFraction = fraction;
			_slowTime = int(time * 1000);
			_startSlow = getTimer();
		}
		
		/**
		 * Update node
		 * @param node
		 * @param eTime
		 */
		private function updateNode( node:Node, eTime:Number ):void
		{
			if (_speed == 0)
				return;
			
			var fraction:Number = 1.0;
			
			// calc slowdown if any
			if (_slowFraction != 0)
			{
				var elapsedTime:int = getTimer() - _startSlow;
				fraction = 1.0 - _slowFraction * ( 1.0 - (elapsedTime / _slowTime));
				if (elapsedTime >= _slowTime)
				{
					_slowFraction = 0;
					fraction = 1.0;
				}
			}
			_player.x += (eTime * _speed * fraction);
			// force to face right
			_player.scaleX = -Math.abs(_player.scaleX);
			
			// reduce rotation until 0
			if (_player.rotation != 0)
			{
				_player.rotation += (eTime * 0.3);
				if (_player.rotation > 0)
				{
					_player.rotation = 0;
				}
			}
		}
	}
}