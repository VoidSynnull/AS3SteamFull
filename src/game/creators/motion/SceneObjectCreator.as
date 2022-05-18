package game.creators.motion
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformReboundCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Platform;
	import game.components.hit.SceneObjectHit;
	import game.components.motion.Edge;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.systems.SystemPriorities;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.util.MotionUtils;

	public class SceneObjectCreator
	{
		public function SceneObjectCreator()
		{
		}
		
		/**
		 * Creates an object that can react to scene with some basic physics.
		 * If requiring interaction with a SceneObjectCollider, a SceneObjectHit will need to be added to entity. 
		 * ATTN: Add PlatformCollider to object or add PlatformReboundCollider to hits in hits.xml if collisions will require rotation.
		 * @param asset - Asset to be used, can be a DisplayObject or path to an external asset to be loaded.
		 * @param bounce - amount of bounce object will have.
		 * @param container - container of object's display
		 * @param x - x position, assumes center registration
		 * @param y - y position, assumes center registration
		 * @param motion - Motion component used by object, if undefined a default is created
		 * @param sceneObjectMotion - SceneObjectMotion component used by object, if undefined a default is created
		 * @param bounds - bounds containing object (general scene bounds) if defined used to define MotionBounds component
		 * @param group - group to add object to, necessary if asset needs to be loaded.  If defined Entity & SceneObjectMotionSystem are added to group
		 * @param callback - callback for case of loading asset
		 * @param colliders - Array of collider Classes to be add to object, if not defined given BouncePlatformCollider & SceneCollider by default. BitmapCollider & CurrentHit added regardless.
		 * @param mass - numeric mass of object, if specified a Mass component is added (standard characters have a mass of 100)
		 * @param givePlatform - is set to true, a platform hit is added to top of object based on the asset's dimensions
		 * @return 
		 */
		public function create(asset:*, bounce:Number = .7, container:DisplayObjectContainer = null, x:Number = NaN, y:Number = NaN, motion:Motion = null, sceneObjectMotion:SceneObjectMotion = null, bounds:Rectangle = null, group:Group = null, callback:Function = null, colliders:Array = null, mass:Number =  NaN, givePlatform:Boolean = false):Entity
		{
			var entity:Entity = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = x;
			spatial.y = y;
			entity.add(spatial);
			
			if(group != null)
			{
				group.addEntity(entity);
				group.addSystem(new SceneObjectMotionSystem(), SystemPriorities.moveComplete);
			}

			if(asset is DisplayObject)
			{
				entity.add(new Display(asset));
				
				if(isNaN(x) || isNaN(y))
				{
					spatial.x = asset.x;
					spatial.y = asset.y;
				}
				
				var edge:Edge = addEdge(asset, entity);
				if( givePlatform )	{ addPlatform( entity, edge ); }
			}
			else if(asset is String && group != null)
			{
				group.shellApi.loadFile(group.shellApi.assetPrefix + asset, assetLoaded, entity, container, callback, givePlatform);
			}
			
			//entity.add(new Sleep());
			
			// setup the motion component with a min / max velocity, friction and acceleration values.
			if(motion == null)
			{
				motion = new Motion();
				motion.friction 	= new Point(0, 0);
				motion.maxVelocity 	= new Point(1000, 1000);
				motion.minVelocity 	= new Point(0, 0);
				motion.acceleration = new Point(0, MotionUtils.GRAVITY);
				motion.restVelocity = 100;
			}
			entity.add(motion);

			// this is a custom component used in the new system built for this scene.  It handles simple bounding box collision reactions and rotates the ball based on its x velocity.
			if(sceneObjectMotion == null)
			{
				sceneObjectMotion = new SceneObjectMotion();
				sceneObjectMotion.rotateByPlatform = false;
				sceneObjectMotion.rotateByVelocity = true;
				sceneObjectMotion.platformFriction = 200;
			}
			entity.add(sceneObjectMotion);
			
			if( !isNaN(mass) )
			{
				entity.add( new Mass( mass ) );
			}

			if(colliders == null)
			{
				// add all standard collider components to this entity if none are specified
				var collider:PlatformReboundCollider = new PlatformReboundCollider();
				collider.bounce = -bounce;
				entity.add(collider);
				entity.add(new SceneCollider());
			}
			else
			{
				for(var n:int = 0; n < colliders.length; n++)
				{
					entity.add(new colliders[n]());
				}
			}
			
			entity.add(new BitmapCollider());
			entity.add(new CurrentHit());
			
			if(bounds != null)
			{
				entity.add(new MotionBounds(bounds.clone()));
			}
			
			return(entity);
		}

		/**
		 * 
		 * @param asset
		 * @param bounce
		 * @param container
		 * @param x
		 * @param y
		 * @param motion
		 * @param sceneObjectMotion
		 * @param bounds
		 * @param group
		 * @param callback
		 * @param colliders
		 * @param mass
		 * @param givePlatform
		 * @return 
		 * 
		 */
		public function createBox(asset:*, bounce:Number = 0, container:DisplayObjectContainer = null, x:Number = NaN, y:Number = NaN, motion:Motion = null, sceneObjectMotion:SceneObjectMotion = null, bounds:Rectangle = null, group:Group = null, callback:Function = null, colliders:Array = null, mass:Number =  NaN, givePlatform:Boolean = true):Entity
		{
			// default motion settings if none were specified
			if(sceneObjectMotion == null)
			{
				sceneObjectMotion = new SceneObjectMotion();
				sceneObjectMotion.rotateByPlatform = false;	// we assume most pushing is happening on a flat plane
				sceneObjectMotion.rotateByVelocity = false;
				sceneObjectMotion.platformFriction = 500;
			}

			var entity:Entity = this.create(asset, bounce, container, x, y, motion, sceneObjectMotion, bounds, group, callback, colliders, mass, givePlatform );
			entity.add(new SceneObjectHit( true, true ));
			return entity;
		}

		public function createCircle(asset:*, bounce:Number = .7, container:DisplayObjectContainer = null, x:Number = NaN, y:Number = NaN, motion:Motion = null, sceneObjectMotion:SceneObjectMotion = null, bounds:Rectangle = null, group:Group = null, callback:Function = null, colliders:Array = null, mass:Number =  NaN, triggerPush:Boolean = false):Entity
		{
			if(sceneObjectMotion == null)
			{
				sceneObjectMotion = new SceneObjectMotion();
				sceneObjectMotion.rotateByPlatform = false;
				sceneObjectMotion.rotateByVelocity = true;
				sceneObjectMotion.platformFriction = 200;
			}
			var entity:Entity = this.create(asset, bounce, container, x, y, motion, sceneObjectMotion, bounds, group, callback, colliders, mass, false );
			entity.add(new SceneObjectHit( true, triggerPush ));	
			return entity;
		}
		
		private function assetLoaded(asset:DisplayObjectContainer, entity:Entity, container:DisplayObjectContainer, callback:Function, givePlatform:Boolean = false):void
		{
			var edge:Edge = addEdge(container.addChild(asset), entity);
			if( givePlatform )	{ addPlatform( entity, edge ); }
			
			entity.add(new Display(asset));
			
			if(callback != null)
			{
				callback.apply(null, [entity]);
			}
		}
		
		private function addEdge(clip:DisplayObject, entity:Entity):Edge
		{
			// this component defines an edge from the registration point of this entity.  This prevents the ball from going all the way to its center point when hitting bounds.
			var bounds:Rectangle = clip.getBounds(clip);
			var edge:Edge = new Edge();
			edge.unscaled.top = -(bounds.height * .5 - 2);
			edge.unscaled.bottom = bounds.height * .5 - 2;
			edge.unscaled.left = -(bounds.width * .5 - 2);
			edge.unscaled.right = bounds.width * .5 - 2;
			entity.add(edge);
			return edge;
		}
		
		private function addPlatform(entity:Entity, edge:Edge = null):void
		{
			if( edge == null )	{ edge = entity.get(Edge); }
			
			var platformHit:Platform = new Platform();
			platformHit.top = false;
			platformHit.hitRect = new Rectangle( edge.unscaled.left - PLATFORM_BUFFER, edge.unscaled.top - PLATFORM_HEIGHT/2, edge.unscaled.width + PLATFORM_BUFFER * 2, PLATFORM_HEIGHT );
			entity.add( platformHit );
		}
		
		private const PLATFORM_HEIGHT:int = 30;
		private const PLATFORM_BUFFER:int = 12;
	}
}