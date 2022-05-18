package game.scenes.shrink.schoolCafetorium.HitTheDeckSystem
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	import org.osflash.signals.Signal;
	
	public class HitTheDeck extends Component
	{
		public var duckDistance:Number;
		
		public var duck:Signal;
		
		public var coastClear:Signal;
		
		public var ducking:Boolean;
		
		public var ignoreProjectile:Boolean;
		
		public var projectile:Spatial;
		
		public var offset:Point;
		
		public function HitTheDeck(projectile:Spatial = null, duckDistance:Number = 200, ignoreProjectile:Boolean = true, offset:Point = null)
		{
			this.projectile = projectile;
			this.duckDistance = duckDistance;
			ducking = false;
			this.ignoreProjectile = ignoreProjectile;
			this.offset = offset;
			duck = new Signal(Entity);
			coastClear = new Signal(Entity);
		}
	}
}