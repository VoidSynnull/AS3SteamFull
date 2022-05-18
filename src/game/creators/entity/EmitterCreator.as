package game.creators.entity
{	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.components.Emitter;
	import game.components.motion.FollowTarget;
	import game.components.entity.Parent;
	import game.components.ParticleMovement;
	import game.systems.ParticleMovementSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.ParticleSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.renderers.BitmapRenderer;
	import org.flintparticles.twoD.renderers.DisplayObjectRenderer;
	
	/**
	 * Creates emitter entities.
	 */
	public class EmitterCreator
	{		
		/**
		 * Creates an emitter entity, uses DisplayObjectRenderer where each particle is a separate class.
		 * @param	group
		 * @param	container - display object emitter is contained within
		 * @param	emitter2D - Emitter class that emitter entity will use.
		 * @param	offsetX - x offset from parentEntity's origin.
		 * @param	offsetY - y offset from parentEntity's origin.
		 * @param	parentEntity - character that emitter is associated with.
		 * @param	id - name the particular emitter, ids must be unique within parentEntity.
		 * @param	follow - if specified, the spatial that that emitter should move with ( usually a joint ) 
		 * @return
		 */
		public static function create( group:Group, container:DisplayObjectContainer, emitter2D:Emitter2D, offsetX:int=0, offsetY:int=0, parentEntity:Entity=null, id:String=null, follow:Spatial=null, start:Boolean = true, allowFlip:Boolean = false ):Entity
		{
			var emitterEntity:Entity = new Entity();
			
			// create Spatial
			emitterEntity.add(new Spatial());
			
			// create Emitter, assign it a Flint emitter.
			var emitter:Emitter = new Emitter();
			emitter.emitter = emitter2D;
			emitterEntity.add(emitter);
			
			// create Display
			// use a static display to contain the particles as the emitter display container won't move, only the emitter source within it.
			var display:Display = new Display();
			display.isStatic = true;
			// Create a Flint displayObjectRenderer as a container for the emitter's particles.
			display.displayObject = new DisplayObjectRenderer();
			// Add the emitter to the renderer (required by Flint).
			DisplayObjectRenderer(display.displayObject).addEmitter(emitter.emitter);	
			container.addChild(display.displayObject);
			emitterEntity.add(display);

			// add offset if follower is null and offsets given
			if ((follow == null) && ( offsetX != 0 || offsetY != 0 ))
			{
				var spatialOffset:SpatialOffset = new SpatialOffset();
				spatialOffset.x = offsetX;
				spatialOffset.y = offsetY;
				emitterEntity.add(spatialOffset);
			}
			
			// create Parent
			if ( parentEntity )
			{
				// set parentEntity as Parent
				EntityUtils.addParentChild(emitterEntity, parentEntity);
			}
			
			var emitterId:Id = new Id();
			emitterId.id = "emitter";
			
			// add Id
			if ( id != null )
			{
				emitterId.id = id;
			}
			
			emitterEntity.add(emitterId);
			
			// add FollowTarget if specified
			if ( follow )
			{
				var followTarget:FollowTarget = new FollowTarget();
				followTarget.target = follow;
				followTarget.rate = 1;
				// allow flip if requested
				if (allowFlip)
					followTarget.allowXFlip = true;
				// add offset if any
				if ( offsetX != 0 || offsetY != 0 )
					followTarget.offset = new Point(offsetX, offsetY);
				emitterEntity.add(followTarget);
				
				if ( !group.getSystem( FollowTargetSystem ) )
				{
					group.addSystem(new FollowTargetSystem(), SystemPriorities.move);
				}
			}
			
			emitter.start = start;
			
			// make sure ParticleSystem has been added 
			group.addSystem(new ParticleSystem());
			group.addEntity(emitterEntity);
			return emitterEntity;
		}
		
		public static function createSceneWide(scene:Scene, emitter:Emitter2D, moveParticles:Boolean = true):Entity
		{
			var emitterEntity:Entity = create(scene, scene.overlayContainer, emitter, 0, 0);
			
			if(moveParticles)
			{
				scene.addSystem(new ParticleMovementSystem(scene), SystemPriorities.lowest);
				emitterEntity.add(new ParticleMovement());
			}
			return emitterEntity;
		}
		
		/*
		public static function addToEntity(entity:Entity, emitter2D:Emitter2D, offsetX:int=0, offsetY:int=0, start:Boolean = true):Emitter
		{
			// create Emitter, assign it a Flint emitter.
			var emitter:Emitter = new Emitter();
			emitter.emitter = emitter2D;
			entity.add(emitter);
			
			return(emitter);
		}
		*/
		/**
		 * Creates an emitter entity, uses BitmapRenderer where particles are drwan ointo a Bitmap
		 */
		public static function createBitmapRenderer( group:Group, container:DisplayObjectContainer, renderer:BitmapRenderer, 
													 emitter2D:Emitter2D, offsetX:int=0, offsetY:int=0, parentEntity:Entity=null, 
													 id:String="", follow:Spatial=null, start:Boolean = true ):Entity
		{
			var emitterEntity:Entity = new Entity();
			
			// create Spatial
			emitterEntity.add(new Spatial());
			
			// create Emitter, assign it a Flint emitter.
			var emitter:Emitter = new Emitter();
			emitter.emitter = emitter2D;
			emitterEntity.add(emitter);
			
			// create Display
			// use a static display to contain the particles as the emitter display container won't move, only the emitter source within it.
			var display:Display = new Display();
			display.isStatic = true;
			// Create a Flint displayObjectRenderer as a container for the emitter's particles.
			display.displayObject = renderer;
			// Add the emitter to the renderer (required by Flint).
			BitmapRenderer(display.displayObject).addEmitter(emitter.emitter);	
			container.addChild(display.displayObject);
			emitterEntity.add(display);
			
			// add offset
			if ( offsetX != 0 || offsetY != 0 )
			{
				var spatialOffset:SpatialOffset = new SpatialOffset();
				spatialOffset.x = offsetX;
				spatialOffset.y = offsetY;
				emitterEntity.add(spatialOffset);
			}
			
			// create Parent
			if ( parentEntity )
			{
				// set parentEntity as Parent
				var parent:Parent = new Parent();
				parent.parent = parentEntity;
				emitterEntity.add(parent);
			}
			
			// add Id
			if ( id != "" )
			{
				var emitterId:Id = new Id();
				emitterId.id = id;
				emitterEntity.add(emitterId);
			}
			
			// add FollowTarget if specified
			if ( follow )
			{
				var followTarget:FollowTarget = new FollowTarget();
				followTarget.target = follow;
				followTarget.rate = 1;
				emitterEntity.add(followTarget);
				
				if ( !group.getSystem( FollowTargetSystem ) )
				{
					group.addSystem(new FollowTargetSystem(), SystemPriorities.move);
				}
			}
			
			emitter.start = start;
			
			// make sure ParticleSystem has been added 
			group.addSystem(new ParticleSystem(), SystemPriorities.update);
			group.addEntity(emitterEntity);
			return emitterEntity;
		}
	}
}
