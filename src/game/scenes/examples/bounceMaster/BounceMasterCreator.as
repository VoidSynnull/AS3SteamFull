package game.scenes.examples.bounceMaster
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.hit.ProximityHit;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.SceneObjectMotion;
	import game.scenes.examples.bounceMaster.components.BounceMasterGameState;
	import game.scenes.examples.bounceMaster.components.Bouncer;
	import game.util.EntityUtils;
	import game.util.MotionUtils;

	public class BounceMasterCreator
	{
		public var bricks:Array;
		
		public function BounceMasterCreator()
		{
		}
		
		public function createCatcher(clip:MovieClip, followSpatial:Spatial):Entity
		{
			var entity:Entity = new Entity();
			
			var follow:FollowTarget = new FollowTarget(followSpatial);
			follow.properties = new <String>["x"];
			entity.add(follow);
			entity.add(new Display(clip));
			entity.add(new Spatial());
			entity.add(new Id("catcher"));
			entity.add(new ProximityHit(clip.width * .5, clip.height * .5));
			
			return(entity);
		}
		
		public function makeCatcher(entity:Entity, hitWidth:Number, hitHeight:Number):void
		{
			entity.add(new ProximityHit(hitWidth, hitHeight));
		}
		
		public function createBouncer(clip:MovieClip, x:Number, y:Number, velX:Number, velY:Number,
									  bounds:Rectangle):Entity
		{
			var entity:Entity = new Entity();
			var side:Number = clip.width * .5;
			
			var motion:Motion = new Motion();
			
			motion.velocity.x = velX;
			motion.velocity.y = velY;
			//motion.acceleration.y = 800;
			motion.maxVelocity = new Point(800, 800);
			entity.add(motion);
			
			var edge:Edge = new Edge();
			edge.unscaled.setTo(-side, -side, side * 2, side * 2);
			entity.add(edge);
			
			entity.add(new Bouncer());
			entity.add(new Spatial(x, y));
			entity.add(new Display(clip));
			entity.add(new ProximityHit(side, side));
			entity.add(new Id("bouncer"));
			entity.add(new MotionBounds(bounds));
			
			return(entity);
		}
		
		public function createGameState(hud:DisplayObjectContainer, id:String):Entity
		{
			var entity:Entity = new Entity();
			
			entity.add(new BounceMasterGameState());
			entity.add(new Display(hud));
			entity.add(new Id(id));
			
			return(entity);
		}
	}
}