package game.scenes.shrink.carGame.states
{
	import engine.managers.SoundManager;
	
	import game.util.DisplayUtils;

	public class TopDownInCulvert extends TopDownDriverState
	{
		private var EDGE_HIT:String =		"ls_cobble_01.mp3";
		public function TopDownInCulvert()
		{
			super.type = TopDownDriverState.IN_CULVERT;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			_inCulvert = true;
			_culvertPosition = node.collider.hitSpatial;
			
			DisplayUtils.moveToOverUnder( node.display.displayObject, node.collider.hitDisplay.displayObject, false );
			super.updateStage = inCulvertMovement;
		}
		
		override public function update( time:Number ):void
		{
			super.update( time );
			super.updateStage();
		}
		
		private function inCulvertMovement():void
		{
			
			if( node.motion.y > _culvertPosition.y + 40 )
			{
				node.spatial.y = _culvertPosition.y;	
				node.motion.zeroMotion();
				
				node.audio.play( SoundManager.EFFECTS_PATH + EDGE_HIT );
			}
			
			else if( node.motion.y < _culvertPosition.y - 40 )
			{
				node.spatial.y = _culvertPosition.y;
				node.motion.zeroMotion();
				
				node.audio.play( SoundManager.EFFECTS_PATH + EDGE_HIT );
			}
			
			if( node.spatial.x > _culvertPosition.x + 1320 )
			{
				_inCulvert = false;
				_culvertPosition = null;
				DisplayUtils.moveToTop( node.display.displayObject );
				node.fsmControl.setState( DRIVE );
			}
			node.spatial.rotation = 0;
		}
	}
}