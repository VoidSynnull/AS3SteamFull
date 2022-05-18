package game.scenes.examples.cameraControl{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	
	import game.components.entity.Sleep;
	import game.components.hit.Zone;
	import game.components.motion.TargetSpatial;
	import game.components.motion.WaveMotion;
	import game.creators.ui.ButtonCreator;
	import game.data.WaveMotionData;
	import game.data.display.BitmapWrapper;
	import game.scene.template.CameraGroup;
	import game.scene.template.PlatformerGameScene;
	import game.systems.SystemPriorities;
	import game.systems.motion.WaveMotionSystem;
	
	public class CameraControl extends PlatformerGameScene
	{
		public function CameraControl()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/cameraControl/";
			// This will override a scene's default scale of '1'.  The layers will be bitmapped at this resolution for memory savings and a sharper image.
			super.initialScale = 1;
			super.init(container);
		}
				
		// all assets ready
		override public function loaded():void
		{
			super.loaded();

			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			
			// store some defaults for resetting
			_defaultCameraZoom = camera.scaleTarget;
			_defaultPanRate = camera.rate;
			
			// a Motion target is only needed if we want to zoom the camera based on velocity.  It will zoom out when velocity > 0, and zoom in otherwise.
			camera.scaleMotionTarget = super.player.get(Motion);
			camera.scaleRate = .01;   // .025 is default
			
			configureZones();
			
			createButtons();
			
			setupWindmill();
			
			// this Spatial component will simply be used to set a new camera target.
			_customTarget = new Spatial(1600, 1500);
		}
		
		public function cycleZoom():void
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			
			if(camera.scaleTarget == .5)
			{
				camera.scaleTarget = 2;
			}
			else if(camera.scaleTarget == 2)
			{
				camera.scaleTarget = 1;
			}
			else
			{
				camera.scaleTarget = .5;
			}
		}
		
		public function cameraShake():Boolean
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var waveMotion:WaveMotion = cameraEntity.get(WaveMotion);
			
			if(waveMotion != null)
			{
				cameraEntity.remove(WaveMotion);
				var spatialAddition:SpatialAddition = cameraEntity.get(SpatialAddition);
				spatialAddition.y = 0;
				return(false);
			}
			else
			{
				waveMotion = new WaveMotion();
			}
			
			var waveMotionData:WaveMotionData = new WaveMotionData();
			waveMotionData.property = "y";
			waveMotionData.magnitude = 3;
			waveMotionData.rate = .5;
			waveMotionData.radians = 0;
			waveMotion.data.push(waveMotionData);
			cameraEntity.add(waveMotion);
			cameraEntity.add(new SpatialAddition());
			
			if(!super.hasSystem(WaveMotionSystem))
			{
				super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			}
			
			return(true);
		}
		
		private function configureZones():void
		{
			var entity:Entity = super.getEntityById("zoomOutZone");
			var zone:Zone = entity.get(Zone);
			zone.pointHit = true;
			
			zone.entered.add(handleZoneEntered);
			zone.exitted.add(handleZoneExitted);
			
			entity = super.getEntityById("zoomInZone");
			zone = entity.get(Zone);
			zone.pointHit = true;
			
			zone.entered.add(handleZoneEntered);
			zone.exitted.add(handleZoneExitted);
			
			entity = super.getEntityById("panZone");
			zone = entity.get(Zone);
			zone.pointHit = true;
			
			zone.entered.add(handleZoneEntered);
			zone.exitted.add(handleZoneExitted);
		}
		
		private function handleZoneEntered(zoneId:String, characterId:String):void
		{			
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			var cameraTarget:TargetSpatial = cameraEntity.get(TargetSpatial);
			
			if(camera.scaleByMotion)
			{
				handleMotionZoomToggle();
			}
			// set the 'scale' of a zoom.  Lower scales are further zoomed out.
			switch(zoneId)
			{
				case "zoomOutZone" :
					if(camera.scaleTarget != .5)
					{
						camera.scaleTarget = .5;
					}
					break;
				
				case "zoomInZone" :
					if(camera.scaleTarget != 2)
					{
						camera.scaleTarget = 2;
					}
					break;
				
				case "panZone" :
					
					if(cameraTarget.target != _customTarget)
					{
						cameraTarget.target = _customTarget;
						camera.rate = .01;
						camera.scaleTarget = .75;
					}
					break;
			}
		}
		
		private function handleZoneExitted(zoneId:String, characterId:String):void
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			var cameraTarget:TargetSpatial = cameraEntity.get(TargetSpatial);
			
			if(camera.scaleTarget != _defaultCameraZoom)
			{
				camera.scaleTarget = _defaultCameraZoom;
			}
			
			if(zoneId == "panZone")
			{
				if(cameraTarget.target != super.player.get(Spatial))
				{
					cameraTarget.target = super.player.get(Spatial);
					camera.rate = _defaultPanRate;
				}
			}
		}
		
		private function createButtons():void
		{
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 14, 0xD5E1FF);
			
			ButtonCreator.createButtonEntity( MovieClip(super.hitContainer).motionZoomToggle, this, handleMotionZoomToggle );
			ButtonCreator.addLabel( MovieClip(super.hitContainer).motionZoomToggle, "Toggle Motion Zoom", labelFormat, ButtonCreator.ORIENT_CENTERED);
			MovieClip(super.hitContainer).motionZoomToggleLight.gotoAndStop("off");
			
			ButtonCreator.createButtonEntity( MovieClip(super.hitContainer).cameraShakeToggle, this, handleCameraShakeToggle );
			ButtonCreator.addLabel( MovieClip(super.hitContainer).cameraShakeToggle, "Toggle Camera Shake", labelFormat, ButtonCreator.ORIENT_CENTERED);
			MovieClip(super.hitContainer).cameraShakeToggleLight.gotoAndStop("off");
		}
		
		private function setupWindmill():void
		{
			var background:Entity = super.getEntityById("windmill");
			
			if(background != null)
			{
				var display:Display = background.get(Display);
				var clip:MovieClip = display.displayObject["windmillBlades"];
				var windmill:Entity = new Entity();
				var motion:Motion = new Motion();
				motion.rotationVelocity = 40;
				
				var wrapper:BitmapWrapper = super.convertToBitmapSprite(clip);
				super.convertToBitmapSprite(display.displayObject["windmillBase"]);
				
				windmill.add(motion);
				windmill.add(new Spatial());
				windmill.add(new Sleep());
				windmill.add(new Display(wrapper.sprite));
				clip.mouseEnabled = false;
				clip.mouseChildren = false;
				super.addEntity(windmill);
			}
		}
		
		private function handleCameraShakeToggle(...args):void
		{
			if(cameraShake())
			{
				MovieClip(super._hitContainer).cameraShakeToggleLight.gotoAndStop("on");
			}
			else
			{
				MovieClip(super._hitContainer).cameraShakeToggleLight.gotoAndStop("off");
			}
		}
		
		private function handleMotionZoomToggle(...args):void
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			
			camera.scaleByMotion = !camera.scaleByMotion;
			
			if(camera.scaleByMotion)
			{
				MovieClip(super._hitContainer).motionZoomToggleLight.gotoAndStop("on");
			}
			else
			{
				camera.scaleTarget = _defaultCameraZoom;
				MovieClip(super._hitContainer).motionZoomToggleLight.gotoAndStop("off");
			}
		}
		
		private var _defaultCameraZoom:Number;
		private var _defaultPanRate:Number;
		private var _customTarget:Spatial;
	}
}