package game.scenes.examples.bounceMasterComplete
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
	
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.hit.ProximityHit;
	import game.scenes.examples.bounceMaster.components.BounceMasterGameState;
	import game.scenes.examples.bounceMaster.components.Bouncer;

	public class BounceMasterCreator
	{
		public function BounceMasterCreator()
		{
		}
		
		public function createBouncer(asset:MovieClip, x:Number, y:Number, velX:Number, velY:Number, boundsWidth:Number, boundsHeight:Number):Entity
		{
			var entity:Entity = new Entity();
			var side:Number = asset.width * .5;
			
			// setup initial motion parameters
			var motion:Motion = new Motion();
			motion.velocity.x = velX;
			motion.velocity.y = velY;
			motion.acceleration.y = 800;
			motion.maxVelocity = new Point(800, 800);
			entity.add(motion);
			
			// this component defines an edge from the registration point of this entity.  This prevents the ball from going all the way to its center point when hitting bounds.
			var edge:Edge = new Edge();
			edge.top = side;
			edge.bottom = side;
			edge.left = side;
			edge.right = side;
			entity.add(edge);
			
			entity.add(new Bouncer());
			entity.add(new Spatial(x, y));
			entity.add(new Display(asset));
			entity.add(new ProximityHit(side, side));
			entity.add(new Id("bouncer"));
			entity.add(new MotionBounds(new Rectangle(0, 0, boundsWidth, boundsHeight)));
			
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
		
		public function createCatcher(clip:MovieClip, followSpatial:Spatial):Entity
		{
			var entity:Entity = new Entity();
			// make the 'paddle' follow input
			var follow:FollowTarget = new FollowTarget(followSpatial);
			follow.properties = new <String>["x"];
			entity.add(follow);	
			entity.add(new Display(clip));
			entity.add(new Spatial());
			
			entity.add(new Id("catcher"));
			entity.add(new ProximityHit(clip.width * .5, clip.height * .5));
			
			return(entity);
		}
		
		public function makeCatcher(entity:Entity, hitWidth:Number = 100, hitHeight:Number = 50):void
		{
			entity.add(new ProximityHit(hitWidth, hitHeight));
		}
	}
}