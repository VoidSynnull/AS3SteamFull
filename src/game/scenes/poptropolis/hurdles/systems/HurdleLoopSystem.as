package game.scenes.poptropolis.hurdles.systems
{
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.hurdles.components.Hurdle;
	import game.scenes.poptropolis.hurdles.nodes.HurdleNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class HurdleLoopSystem extends GameSystem
	{
		private var _maxX:Number;
		private var _playerSpatial:Spatial;
		private var _hurdleDist:Number;
		
		public function HurdleLoopSystem()
		{
			super( HurdleNode, updateNode );
			_defaultPriority = SystemPriorities.update;
		}

		public function init ( maxX:Number, playerSpatial:Spatial, hurdleDist:Number ):void
		{
			_maxX = maxX;
			_playerSpatial = playerSpatial;
			_hurdleDist = hurdleDist
		}

		/**
		 * Reposition hurdles 
		 * @param node
		 * @param time
		 * 
		 */
		private function updateNode( node:HurdleNode, time:Number ) : void
		{
			loopHurdle( node );
		}

		// repositions hurdles once they exit screen behind player
		private function loopHurdle( node:HurdleNode ) : void
		{
			var hurdle:Hurdle = node.hurdle;
			var spatial:Spatial = node.spatial;

			if ( spatial.x < _playerSpatial.x - 1000 ) 
			{
				if (spatial.x + _hurdleDist * 2 < _maxX ) 
				{
					spatial.x += _hurdleDist * 2;
					node.timeline.gotoAndStop("stand");
				}
			}
		}
	}
}