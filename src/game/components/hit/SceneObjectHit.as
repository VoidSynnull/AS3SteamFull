package game.components.hit
{
	import ash.core.Component;
	
	/**
	 * Allows for collision detection against enitities with SceneObjectColliders.
	 */
	public class SceneObjectHit extends Component
	{
		public function SceneObjectHit(active:Boolean = true, triggerPush:Boolean = false )
		{
			this.active = active;
			this.triggerPush = triggerPush;
		}
		
		
		public var active:Boolean = true;//ignores horizontal collision
		public var anchored:Boolean = false;//can run into like a wall but can't push
		public var minImpulseVelocity:Number = 0;
		public var triggerPush:Boolean = false;		// determines if object should cause a 'push' reaction in the collider
	}
}