/**
 * Data class for hazard hits.
 */

package game.data.scene.hit 
{
	import flash.geom.Point;

	public class HazardHitData extends HitDataComponent
	{
		public var knockBackVelocity:Point;
		public var knockBackCoolDown:Number;
		public var knockBackInterval:Number;
		public var velocityByHitAngle:Boolean;
		public var slipThrough:Boolean = false;
	}
}