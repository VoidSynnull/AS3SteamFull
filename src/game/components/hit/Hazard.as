package game.components.hit
{
	import flash.geom.Point;
	
	import ash.core.Component;
		
	public class Hazard extends Component
	{
		public function Hazard(velocityX:Number = 0, velocityY:Number = 0, active:Boolean = true)
		{
			this.velocity = new Point(velocityX, velocityY);
			this.active = active;
		}
		/**
		 *  if hit is active or not, if not active will be ignored by HazardHitSystem
		 */
		public var active:Boolean = true;
		/**
		 *  default cooldown after hitting this is one second.
		 */
		public var coolDown:Number = 1;
		/**
		 *  time interval in seconds colliding entity should remain in hazard induced state, not used by default 
		 */
		public var interval:Number = 0;
		/**
		 *  the velocity resulting from a hit with this hazard.
		 */
		public var velocity:Point; 
		/**
		 *  (optional) the damage resulting from a hit with this hazard.
		 */
		public var damage:Number;
		/**
		 *  flag set true when collision is detected, is set back to false on next update
		 */
		public var collided:Boolean;
		/**
		 *  If true, the hit with this hazard will be calculated based on the overlap of the collider and the hits position + edge
		 */
		public var boundingBoxOverlapHitTest:Boolean;
		/**
		 *  If true, the resultant hit knockback is based on the angle of impact instead of simply applying the velocity.  This is useful for
		 *    top-down or other scenarios where the player can move freely in any direction.
		 */
		public var velocityByHitAngle:Boolean;
		/**
		 *  If true, the resultant hit effect is a slip through rather than a knockback
		 */
		public var slipThrough:Boolean = false;
		/**
		 *  hit function that triggers when hazard is hit
		 */
		public var hitFunction:Function = null;
	}
}
