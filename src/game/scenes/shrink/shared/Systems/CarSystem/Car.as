package game.scenes.shrink.shared.Systems.CarSystem
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Motion;
	import engine.group.Group;
	
	import game.util.EntityUtils;
	
	public class Car extends Component
	{
		public var body:Entity;
		public var wheels:Vector.<Motion>;
		public var maxLean:Number;
		public var maxSpeed:Number;
		public var leanScale:Number;
		public var wheelRadius:Number;
		public function Car(car:MovieClip, group:Group, maxLean:Number = 5, maxSpeed:Number = 500, leanScale:Number = .02, numWheels:int = 2)
		{
			this.maxLean = maxLean;
			this.maxSpeed = maxSpeed;
			leanScale = maxLean / maxSpeed;
			this.leanScale = leanScale;
			body = EntityUtils.createSpatialEntity(group, car.body,car);
			wheels = new Vector.<Motion>();
			for(var i:int = 1; i<= numWheels; i++)
			{
				var clip:MovieClip = car["wheel"+i];
				var entity:Entity = EntityUtils.createMovingEntity(group, clip,car);
				wheels.push(entity.get(Motion));
				wheelRadius = clip.height / 2;
			}
		}
	}
}