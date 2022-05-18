package game.scenes.deepDive1.maze.components
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.motion.FollowTarget;
	import game.components.motion.Swarmer;
	import game.components.entity.Sleep;

	public class FoodFish extends Component
	{
		public var entity:Entity;
		public var swarmer:Swarmer;
		public var originPoint:Point;
		public var originSpatial:Spatial;
		public var originRotation:Number;
		public var goingIntoMouth:Boolean = false;
		public var state:String = "resting";
				// resting = sitting at it's happy corner
				// eating = eating by the angler
				// schooling = following player
		
		public function returnToOrigin():void{

			var spatial:Spatial = entity.get(Spatial);
			var motion:Motion = entity.get(Motion);
			var display:Display = entity.get(Display);
			
			state = "resting";
			
			spatial.x = originPoint.x;
			spatial.y = originPoint.y;
			spatial.rotation = originRotation;
			
			swarmer = new Swarmer();
			swarmer.followTarget = new FollowTarget(new Spatial(originPoint.x, originPoint.y));
			swarmer.alignWeight = 8;
			swarmer.separationWeight = 7;
			swarmer.cohesionWeight = 5;
			swarmer.wanderWeight = 3;
			swarmer.tetherWeight = 10;
			swarmer.followWeight = 10;
			
			entity.add(swarmer);
			entity.add(new Sleep());
			
			motion.pause = false;
	
			goingIntoMouth = false;
			
			display.visible = true;
			
			// reset tween
			//var tween:Tween = new Tween();
			//entity.add(tween);
			
			//var tween:Tween = entity.get(Tween);
			//var bitmap:Bitmap = Sprite(Display(entity.get(Display)).displayObject).getChildAt(0) as Bitmap;
			//tween.to(bitmap, 0.4, {width:30, height:18, yoyo:true, repeat:-1});
			
			//motion.velocity = new Point(0,0);
			//motion.acceleration = new Point(0,0);
			//motion.pause = true;
		}
	}
}