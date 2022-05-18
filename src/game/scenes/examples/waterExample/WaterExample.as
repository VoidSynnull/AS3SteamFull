package game.scenes.examples.waterExample
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.SpatialAddition;
	
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.Platform;
	import game.components.motion.Edge;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.WaveMotion;
	import game.data.WaveMotionData;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.shared.ferrisWheel.components.StickyPlatform;
	import game.scenes.carnival.shared.ferrisWheel.systems.StickyPlatformSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	
	public class WaterExample extends PlatformerGameScene
	{
		public function WaterExample()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/waterExample/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();

			setupBarrels();
			
			//var entity:Entity = getEntityById( "waterHit" );
		}
		
		private function setupBarrels():void
		{
			var parent:Entity = super.getEntityById("water");
			setupBarrel(1, Math.PI / 4, parent);
			setupBarrel(2, 0, parent);
			
			super.addSystem(new WaveMotionSystem());
			super.addSystem( new SceneObjectMotionSystem() );
		}
		
		private function setupBarrel(id:int, angle:Number, parent:Entity):void
		{
			var spatialAddition:SpatialAddition = new SpatialAddition();	// this is shared by both barrel Entities 
			
			// setup barrel visual
			var entity:Entity = super.getEntityById("barrel" + id);
			if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST ) { BitmapUtils.createBitmapSprite(EntityUtils.getDisplayObject(entity)); }
			// turn offScreen sleep off
			entity.add( new Sleep(false, true));

			// setup barrel hit
			var hitEntity:Entity = super.getEntityById("barrelHit" + id);
			
			// set platform to use top of hit
			Platform(hitEntity.get(Platform)).top = true;
			
			// add water collider to allow for entity to float in water
			var waterCollider:WaterCollider = new WaterCollider();
			waterCollider.density = .3;
			waterCollider.dampener = .12;
			hitEntity.add( waterCollider );	
			
			// add wave motion if on high enough quality
			if( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGHEST )
			{
				// add wave motion
				var waveMotion:WaveMotion = new WaveMotion();
				var waveMotionData:WaveMotionData = new WaveMotionData();
				waveMotionData.property = "rotation";
				waveMotionData.magnitude = 2;
				waveMotionData.rate = .05;
				waveMotionData.radians = angle;
				waveMotion.data.push(waveMotionData);
				hitEntity.add(waveMotion);
				hitEntity.add(spatialAddition);
				entity.add(spatialAddition);
			}
			
			// add motion
			hitEntity.add( new Motion() );
			// TODO :: May want to set velocity max
			
			// add Edge 
			var edge:Edge = new Edge();
			var displayObject:DisplayObject = EntityUtils.getDisplayObject(hitEntity);
			edge.unscaled = displayObject.getBounds(displayObject);
			hitEntity.add( edge );
			
			// turn offScreen sleep off
			var sleep:Sleep = hitEntity.get( Sleep );
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;
			
			// add SceneObjectMotion, which adds gravity causing entities to fall back down if they leave the water
			hitEntity.add( new SceneObjectMotion() );

			// the barrels should stop updating if the 'parent' (the water they're sitting in) is sleeping.  This prevents them from falling through it.
			EntityUtils.addParentChild(entity, hitEntity);
			EntityUtils.addParentChild(hitEntity, parent);
			
			//DisplayUtils.cacheAsBitmap( display.displayObject );
		}
	}
}