package game.scenes.virusHunter.shared.components
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class EnemySpawn extends Component
	{
		public function EnemySpawn(type:String = null, rate:Number = 1, area:Rectangle = null, target:Spatial = null)
		{
			this.type = type;
			this.rate = rate;
			this.area = area;
			this.target = target;
		}
		
		public var type:String;			   // the enemy type component to spawn from here.
		public var rate:Number = 1;        // the rate (in seconds) enemies spawn
		public var max:int = 0;         // the total number of this enemy type allowed at a time accross the entire scene.
		public var area:Rectangle;         // an optional area (usually the viewport) where an ememy should be spawned.
		public var outsideArea:Boolean = true;       // should enemies spawn outside the area rectangle.
		public var distanceFromAreaEdge:Number = 0;  // an optional distance from the edge of the area rectangle enemies should spawn.
		public var offsetAreaByCameraPosition:Boolean = true;   // should the spawn area be offset by the camera position.
		public var target:Spatial;         // an optional spatial target to aim its initial velocity
		public var createRange:Point;      // optionally specify the x,y distance from center a random starting position can be picked from.
		public var targetRange:Point;      // optionally specify a degree range that can be picked for initial velocity.  Used if a target isn't specified.
		public var targetOffset:Number = 0;// optionally set an offset from enemy directly aimed at target.
		public var maxInitialVelocity:*;  // optionally set an enemies initial velocity.  This can simply be a number if an aim target is supplied, or a point otherwise.
		public var minInitialVelocity:*;  // optionally set an enemies initial velocity.
		public var _timeSinceLastSpawn:Number = 0;  // used by the system to track time since last spawn.
		public var totalFromThisSpawn:int = 0;      // tracks the total active enemies from this spawn point.
		public var spawnCap:int = 0;      // an optional cap on this particular spawn point
		public var useSpawnCap:Boolean = false;
		public var enemyDamage:Number;    // optionally specify the damage to player from an enemy spawned from here.
		public var alwaysAquire:Boolean = false;
		public var ignoreOffScreenSleep:Boolean = false;
	}
}