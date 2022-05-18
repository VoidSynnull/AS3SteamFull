package game.scenes.deepDive1.shared.creators
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.group.DisplayGroup;
	
	import game.components.audio.HitAudio;
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.ItemCollider;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.MovieClipHit;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.WaveMotion;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.WaveMotionData;
	import game.scenes.deepDive1.shared.components.Sub;
	import game.scenes.deepDive1.shared.components.SubCamera;
	import game.scenes.deepDive1.shared.emitters.SubTrail;
	import game.systems.motion.RotateToTargetSystem;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.TimelineUtils;

	public class SubCreator
	{
		public function SubCreator()
		{
		}

		public function create( group:DisplayGroup, container:DisplayObjectContainer, clip:MovieClip, x:Number, y:Number, direction:String, bounds:Rectangle, particleContainer:DisplayObjectContainer, id:String = null ):Entity
		{
			var entity:Entity = new Entity();		
			var spatial:Spatial = new Spatial(x, y);
			
			if(direction == "right")
			{
				spatial.scaleX = -spatial.scale;
			}
			
			var motion:Motion = new Motion();
			motion.friction 	= new Point(0, 0);
			motion.minVelocity 	= new Point(0, 0);
			motion.maxVelocity 	= new Point(MAX_VELOCITY, MAX_VELOCITY);
			/*
			if(PlatformUtils.isMobileOS)
			{
				motion.maxVelocity 	= new Point(260, 260);
			}
			*/
			var motionControlBase:MotionControlBase = new MotionControlBase();
			motionControlBase.acceleration = 1200;
			motionControlBase.stoppingFriction = 300;//500;
			motionControlBase.accelerationFriction = 300;//200;
			//motionControlBase.maxVelocityByTargetDistance = 500;
			motionControlBase.freeMovement = true;
			
			var edge:Edge = new Edge( -EDGE_RADIUS, -EDGE_RADIUS, EDGE_RADIUS*2, EDGE_RADIUS*2);
			
			var movieClipHit:MovieClipHit = new MovieClipHit("ship");
			clip.mouseEnabled = false;
			movieClipHit.hitDisplay = clip["hit"];
			movieClipHit.hitDisplay.mouseEnabled = false;
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
			
			var display:Display = new Display(clip, container);
			var sub:Sub = new Sub();
			
			entity.add(edge);
			entity.add(spatial);
			entity.add(display);
			entity.add(motion);
			entity.add(new MotionControl());
			entity.add(new MotionTarget());
			entity.add(new Navigation());
			entity.add(new RadialCollider());
			var bitmapCollider:BitmapCollider = new BitmapCollider();
			bitmapCollider.addAccelerationToVelocityVector = true;
			entity.add(bitmapCollider);
			entity.add(new SceneCollider());
			entity.add(new ZoneCollider());
			entity.add(new HazardCollider());
			entity.add(new SpatialAddition());
			entity.add(movieClipHit);
			entity.add(new MotionBounds(bounds));
			entity.add(new Audio());
			entity.add(new HitAudio());
			entity.add(new CurrentHit());
			entity.add(new ItemCollider());
			entity.add(sub);
			entity.add(motionControlBase);
			entity.add(new Tween());
			entity.add(new Sleep(false, true));
			if(id != null) { entity.add(new Id(id)); }
			
			// optional components based on performance
			if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_LOW )
			{
				entity.add(new SpatialAddition());
				
				var waveMotionData:WaveMotionData = new WaveMotionData("y", 7, .03);
				var waveMotion:WaveMotion = new WaveMotion();
				waveMotion.add(waveMotionData);
				entity.add(waveMotion);
			}
			
			// create SubCamera Entity
			
			// manages special acions associated with filming and lights
			var subCamera:SubCamera = new SubCamera( entity, cameraDistanceMin, cameraDistanceMax, CAMERA_ANGLE );
			subCamera.originalColor = 0x535D5F;
			subCamera.lights = new Vector.<MovieClip>();
			
			// keep reference to progress lights
			var content:MovieClip = clip.content as MovieClip;
			for(var i:int = 1; i <= 6; i++)
			{
				subCamera.lights.push(content["lightBar"]["light_" + i]);
			}
			
			// create iris
			var mc:MovieClip = content["iris"];
			subCamera.iris = TimelineUtils.convertClip(mc, group);
			subCamera.iris = EntityUtils.createSpatialEntity(group, mc);
			BitmapTimelineCreator.convertToBitmapTimeline(subCamera.iris, mc); 
			EntityUtils.addParentChild( subCamera.iris, entity );

			// create top light
			mc = content["topLight"];
			subCamera.topLight = EntityUtils.createSpatialEntity(group, mc);
			BitmapTimelineCreator.convertToBitmapTimeline(subCamera.topLight, mc); 
			EntityUtils.addParentChild( subCamera.topLight, entity );
			
			// create light beams
			subCamera.lightBeamR = EntityUtils.createSpatialEntity(group, content["lightBeam_R"]);
			subCamera.lightBeamL = EntityUtils.createSpatialEntity(group, content["lightBeam_L"]);
			EntityUtils.visible( subCamera.lightBeamR, false);
			EntityUtils.visible( subCamera.lightBeamL, false);
			EntityUtils.addParentChild( subCamera.lightBeamR, entity );
			EntityUtils.addParentChild( subCamera.lightBeamL, entity );
			
			// bitmap sub layers if low quality
			var qualityFactor:Number= ( PlatformUtils.isDesktop || PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH ) ? 1.5 : 1;
			group.convertToBitmapSprite( content["front"], null, true, qualityFactor );
			group.convertToBitmapSprite( content["back"], null, true, qualityFactor );
			
			entity.add( subCamera );
			group.addSystem( new RotateToTargetSystem() );

			if(group)
			{
				if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH)
				{
					var emitter:SubTrail = new SubTrail();
					emitter.init();
					EmitterCreator.create(group, particleContainer, emitter, 0,  0, entity, "exhaust", spatial);
					sub.trail = emitter;
				}
				group.addEntity(entity);
			}
			
			return(entity);
		}
		
		private const CAMERA_ANGLE:Number = 30;
		public var cameraDistanceMin:Number = 60;
		public var cameraDistanceMax:Number = 400;
		private const EDGE_RADIUS:int = 70;
		private const MAX_VELOCITY:int = 400;
	}
}