package game.systems.entity.character.states
{
	import game.data.animation.entity.character.Hurt;

	public class FlyingPlatformHurt extends FlyingPlatformState
	{
		public function FlyingPlatformHurt()
		{
			super.type = FlyingPlatformState.HURT;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			node.looperCollider.isHit = false;
			node.looperCollider.collisionType = null;
			
			setAnim( Hurt, false );
			node.timeline.handleLabel( "ending", returnToStand, false );
			
			// set player hit flag
			node.flyingPlatformHealth.playerHit = true;
			
			node.flyingPlatformHealth.handleFeedBack();
		}
	
		private function returnToStand():void
		{	
			if( node.flyingPlatformHealth.calculateHits())
			{
				node.flyingPlatformHealth.handleLose();
			}
			else
			{
				node.timeline.removeLabelHandler( returnToStand );
				node.fsmControl.setState( FlyingPlatformState.RIDE );
			}
		}
		
		/** 
		 * Check for collisions - always false
		 */
		override public function check():Boolean
		{
			node.fsmControl.setState( FlyingPlatformState.HURT );
			
			return true;
		}
	}
}