package game.scenes.deepDive3.shared
{
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.CircularCollider;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.SceneObjectHit;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.TargetSpatial;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.display.BitmapWrapper;
	import game.data.ui.ToolTipType;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive3.shared.components.MemoryParticlesComponent;
	import game.scenes.deepDive3.shared.components.Orb;
	import game.scenes.deepDive3.shared.particles.MemoryParticles;
	import game.scenes.deepDive3.shared.particles.ModuleParticles;
	import game.scenes.deepDive3.shared.popups.TeleImagesPopup;
	import game.scenes.deepDive3.shared.systems.MemoryParticlesSystem;
	import game.scenes.deepDive3.shared.systems.OrbCollisionSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.SceneObjectHitCircleSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class MemoryModuleGroup extends Group
	{

		// in-scene clip ids, need to be the same on all scenes
		public const ORB_ID:String 		= "memoryOrb";
		public const SPAWNER_ID:String 	= "orbSpawner";
		public const BUTTON_ID:String 	= "spawnButton";
		public const SLOT_ID:String 	= "memorySlot"; // also used with a 'Zone' tag added to the id 
		public const WALL_ID:String 	= "securityBarrier"; // add number for each wall 0,1,2...etc
		
		public var systemOnSound:String = SoundManager.EFFECTS_PATH+"alien_module.mp3";
		public var orbGlowSound:String = SoundManager.EFFECTS_PATH+"electric_hum_01_loop.mp3";
		public var heavyOrbHitSound:String = SoundManager.EFFECTS_PATH+"electric_zap_01.mp3";

		private var _container:DisplayObjectContainer;
		private var _scene:SubScene;
		private var _sceneObjectCreator:SceneObjectCreator;
		
		private var _systemOnEvent:String;
		
		private var _spawnButton:Entity;
		private var _spawner:Entity;
		private var _goal:Entity;
		private var _goalZone:Entity;
		private var _orbGlow:Entity;
		private var _orb:Entity;
		public function get memoryOrb():Entity{return _orb;}
		
		private var _securityWalls:Vector.<Entity>;
		private var _lowQuality:Boolean;
		
		private var _memoryParticleEmitter:MemoryParticles;
		private var _emitterEntity:Entity;
		
		private var _inMemory:Boolean = false;
		
		private var _moduleParticleEmitter:ModuleParticles;
		private var _moduleParticlesEmitter:Entity;
		
		public var finishedMemory:Signal;
		public var startMemory:Signal;

		public function MemoryModuleGroup(scene:SubScene, container:DisplayObjectContainer, orbColectedEvent:String)
		{
			_container = container;
			_scene = scene;
			_systemOnEvent = orbColectedEvent;
			finishedMemory = new Signal();
			startMemory = new Signal();
		}
		
		override public function destroy():void
		{
			_container = null;
			_scene = null;
			_sceneObjectCreator = null;
			_securityWalls = null;
			_spawnButton = null;
			_spawner = null;
			_goal = null;
			_goalZone = null;
			_orbGlow = null;
			_orb = null;
			_emitterEntity = null;
			_moduleParticlesEmitter = null;
			if( finishedMemory )
			{
				finishedMemory.removeAll();
				finishedMemory = null;
			}
			if( startMemory )
			{
				startMemory.removeAll();
				startMemory = null;
			}
			super.destroy();
		}
		
		override public function added():void
		{
			_sceneObjectCreator = new SceneObjectCreator();
			
			if(PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH){
				_lowQuality = true;	
			}
			else{
				_lowQuality = false;
			}
			
			addSystem(new SceneObjectHitCircleSystem());
			
			var sceneObjectCollider:SceneObjectCollider = new SceneObjectCollider();
			
			shellApi.player.add(sceneObjectCollider);
			shellApi.player.add(new CircularCollider());
			shellApi.player.add(new Mass(100));
			
			setupButton();
			
			createModuleSpawner(_spawnButton);
			
			createModuleSlot(_spawner);
			
			createSecurityWalls();
		}
		
		private function createModuleParticles():void
		{
			_moduleParticleEmitter = new ModuleParticles();
			_moduleParticlesEmitter = EmitterCreator.create(_scene, _container, _moduleParticleEmitter,0,0,null,null,_orb.get(Spatial));
			_moduleParticleEmitter.init();
			_moduleParticleEmitter.sparkle();
		}
		
		private function setupButton():void
		{
			var clip:MovieClip = _container[BUTTON_ID];
			BitmapUtils.convertContainer(clip, 1);
			_spawnButton = EntityUtils.createSpatialEntity(this,clip);
			TimelineUtils.convertClip(clip, this, _spawnButton, null, false);

			var inter:Interaction = InteractionCreator.addToEntity(_spawnButton,[InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.autoSwitchOffsets = false;
			sceneInter.offsetY = -60;
			sceneInter.minTargetDelta.y = 30;
			sceneInter.minTargetDelta.x = 30;
			sceneInter.reached.add(pushButton);
			_spawnButton.add(sceneInter);
			ToolTipCreator.addToEntity(_spawnButton);
		}
		
		private function pushButton(player:Entity, button:Entity):void
		{
			shellApi.triggerEvent("switchHit");
			Timeline(_spawnButton.get(Timeline)).gotoAndPlay("up");
			TweenUtils.globalTo(this,shellApi.player.get(Spatial),0.9,{y:shellApi.player.get(Spatial).y+50, onComplete:buttonPressed},"button_go");
		}
		
		private function buttonPressed():void
		{
			if(!shellApi.checkEvent(_systemOnEvent))
			{
				if(!_orb){
					createMemoryModule();	// create ord and glow entities
				}else{
					fadeOrb();				// already have orb, need to transition out old one first
				}
			}
			else
			{
				Timeline(_spawnButton.get(Timeline)).gotoAndPlay("down");
			}
		}

		/**
		 * init memory orb, add componenets and such
		 */
		private function createMemoryModule():void
		{	
			var spawnerSpatial:Spatial = _spawner.get(Spatial);
			_orb = createBall(spawnerSpatial.x,spawnerSpatial.y, _orb);
			MotionUtils.addWaveMotion(_orb,new WaveMotionData("y",4,.08),this);
			_orb.add(new Sleep(false,true));
			
			var bitmapWrapper:BitmapWrapper = _scene.convertToBitmapSprite(_container["orbGlow"], null, true, PerformanceUtils.defaultBitmapQuality * 2);
			_orbGlow = EntityUtils.createSpatialEntity(this, bitmapWrapper.sprite);
			_orbGlow.add(new Id("glow"));
			_orbGlow.add(new FollowTarget(_orb.get(Spatial)));
			
			this.addSystem(new OrbCollisionSystem(this), SystemPriorities.checkCollisions); // for sound effects on collision

			spawnMemoryModule();
		}
		
		private function createBall(targetX:Number, targetY:Number, orbEntity:Entity = null):Entity
		{
			var motion:Motion;
			var sceneObjectMotion:SceneObjectMotion;
			
			if(orbEntity != null)
			{
				Display(_orbGlow.get(Display)).alpha = 1;
				Display(_orbGlow.get(Display)).visible = true;
				
				motion = orbEntity.get(Motion);
				motion.zeroMotion();
				motion.x = targetX;
				motion.y = targetY;
				
				(orbEntity.get(SceneObjectHit) as SceneObjectHit).active = true;
			}
			else
			{
				sceneObjectMotion = new SceneObjectMotion();
				sceneObjectMotion.rotateByPlatform = false;
				sceneObjectMotion.rotateByVelocity = true;
				sceneObjectMotion.platformFriction = 0;
				sceneObjectMotion.applyGravity = false;
				
				motion = new Motion();
				motion.friction 	= new Point(400, 400);
				motion.maxVelocity 	= new Point(400, 400);
				motion.minVelocity 	= new Point(0, 0);
				motion.acceleration = new Point(0, 0);
				motion.restVelocity = 100;
				
				var bitmapWrapper:BitmapWrapper = _scene.convertToBitmapSprite(_container[ORB_ID], null, true, PerformanceUtils.defaultBitmapQuality * 2);
				orbEntity = _sceneObjectCreator.create(bitmapWrapper.sprite,0.9,_container,targetX, targetY, motion, sceneObjectMotion, _scene.sceneData.bounds, this, null, [RadialCollider]);
				
				var radialCollider:RadialCollider = orbEntity.get(RadialCollider);
				radialCollider.rebound = .5;  // add additional rebound
				
				var bitmapCollider:BitmapCollider = orbEntity.get(BitmapCollider);
				bitmapCollider.useEdge = true;
				
				orbEntity.add(new SceneObjectHit());
				orbEntity.add(new Id("memoryOrb"));
				orbEntity.add(new ZoneCollider());
				orbEntity.add(new Mass(50));
				orbEntity.add(new SceneCollider()); 
				orbEntity.add(new Orb(super.shellApi.player));
			}
			
			return orbEntity;
		}
		
		/**
		 * fades out and disables the memory orb
		 * @param	reset : whenther to respawn the orb on fade complete
		 */		
		public function fadeOrb(reset:Boolean = true, instant:Boolean = false):void
		{
			if(_moduleParticleEmitter)
				_moduleParticleEmitter.sparkle(0);
			
			if(_orb)
				_orb.get(SceneObjectHit).active = false;
			
			var handler:Function;
			if(reset)
			{
				handler = spawnMemoryModule;
			}
			else
			{
				if(_orb)
					MotionUtils.zeroMotion(_orb);
			}
			
			if(!instant)
			{
				if(_orb){
					TweenUtils.entityTo(_orb, Display, 1, {alpha:0});
					TweenUtils.entityTo(_orbGlow, Display, 1.1, {alpha:0, onComplete:handler});
					shellApi.triggerEvent("fizzleOrb");
				}
			} 
			else 
			{
				if(_orb){
					EntityUtils.getDisplay(_orb).alpha = 0;
					EntityUtils.getDisplay(_orbGlow).alpha = 0;
				}
				
				if( handler != null )	{ handler(); }
			}
		}

		/**
		 * make memory orb at spawner
		 */
		public function spawnMemoryModule():void
		{
			if(!shellApi.checkEvent(_systemOnEvent))
			{
				_orb.get(SceneObjectHit).active = true;
				
				EntityUtils.getDisplay(_orb).alpha = 1;
				EntityUtils.getDisplay(_orbGlow).alpha = 1;

				EntityUtils.positionByEntity(_orb,_spawner);
				
				TweenUtils.entityTo(_orb, Spatial,0.5,{y:_orb.get(Spatial).y-180, ease:Sine.easeOut, onComplete:closeSpawner},"orbtwn",0.5);
				
				Timeline(_spawner.get(Timeline)).gotoAndPlay("start");
				Timeline(_spawnButton.get(Timeline)).gotoAndPlay("down");
				shellApi.triggerEvent("openDoor");
				Timeline(_spawner.get(Timeline)).handleLabel("open", Command.create(shellApi.triggerEvent,"launchOrb"));
				
				AudioUtils.playSoundFromEntity(_orb,orbGlowSound, 400, 0.1, 1.2, Quad.easeInOut);

				// create particles for memory orb is quality is high
				if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH)	{ createModuleParticles(); }
			}
			else
			{
				// indicate that orb is already used
				shellApi.triggerEvent("spawnFail");
			}
		}
		
		private function closeSpawner():void
		{
			Timeline(_spawner.get(Timeline)).gotoAndPlay("open");
		}
		
		/**
		 * make memory orb spawner
		 * only one orb will be active on each scene, kills old orb whenever activated
		 */
		public function createModuleSpawner(button:Entity):void
		{
			var clip:MovieClip = _container[SPAWNER_ID];
			BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			_spawner = EntityUtils.createMovingTimelineEntity(this,clip,null,false);
		}
		
		/**
		 * make memory slot, goal area
		 */
		public function createModuleSlot(moduleSpawner:Entity):void
		{
			var wrapper:BitmapWrapper = _scene.convertToBitmapSprite(_container[SLOT_ID]);
			_goal = EntityUtils.createSpatialEntity(this, wrapper.sprite);
			_goalZone = _scene.getEntityById(SLOT_ID+"Zone");
			
			if(shellApi.checkEvent(_systemOnEvent))
			{
				// center orb on goal slot
				createMemoryModule();
				EntityUtils.positionByEntity(_orb,_goalZone, true);
				EntityUtils.visible(_goal, true);
				
				_orb.remove(WaveMotion);
				_orb.remove(SceneObjectMotion);
				_orb.remove(SceneObjectHit);
				_orb.remove(SceneObjectCollider);
				_orb.remove(MotionBounds);
				if(!_lowQuality){
					_orb.get(Motion).rotationVelocity = 200;
				}
				// allow memory images to be viewed via orb click
				makeOrbClickable();
				
				createParticles();
				
				AudioUtils.playSoundFromEntity(_orb,orbGlowSound, 400, 0.1, 1.2, Quad.easeInOut);
				AudioUtils.playSoundFromEntity(_goal,systemOnSound,500,0,1.0,Quad.easeInOut);						
			}
			else
			{
				// enable orb collection
				EntityUtils.visible(_goal, false, true);
				var zone:Zone = _goalZone.get(Zone);
				zone.entered.add(captureOrb);
			}
		}
		
		private function captureOrb(zoneId:String, id:String):void
		{
			if(zoneId == SLOT_ID + "Zone")
			{
				if(id == ORB_ID)
				{
					var targ:Spatial = _goalZone.get(Spatial);
					var motion:Motion = _orb.get(Motion);
					motion.zeroMotion();
					_orb.remove(WaveMotion);
					_orb.remove(SceneObjectMotion);
					_orb.remove(SceneObjectHit);
					_orb.remove(SceneObjectCollider);
					_orb.remove(MotionBounds);
					_orb.get(Motion).rotationVelocity = 200;
					TweenUtils.entityTo(_orb,Spatial,1,{x:targ.x, y:targ.y, onComplete:orbCaptured},"orbcap");
				}
			}
		}
		
		private function orbCaptured():void
		{
			EntityUtils.positionByEntity(_orb,_goalZone,false,false);
			
			if(_moduleParticleEmitter){
				_moduleParticleEmitter.sparkle(0);
			}
			
			createParticles();
			
			var sLightingGroup:SubsceneLightingGroup = _scene.getGroupById("subsceneLightingGroup") as SubsceneLightingGroup;
			sLightingGroup.activateMemoryModule();
			
			EntityUtils.visible(_goal, true);
			SceneUtil.addTimedEvent(this,new TimedEvent(1.1,1,lockInOrb));
		}
		
		private function lockInOrb(...p):void
		{
			//SceneUtil.lockInput(this, true);	// NOTE :: lock input once scene interaction has been reached
			makeOrbClickable();
			
			var sceneInter:SceneInteraction = _orb.get(SceneInteraction);
			sceneInter.activated = true;
			
			shellApi.completeEvent( _systemOnEvent );
			AudioUtils.playSoundFromEntity(_goal, systemOnSound,500,0,1.0,Quad.easeInOut);
		}
		
		private function makeOrbClickable():void
		{
			var inter:Interaction = InteractionCreator.addToEntity(_orb,[InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.minTargetDelta.x = sceneInter.minTargetDelta.y = 170;
			sceneInter.reached.add(activateMemory);
			
			ToolTipCreator.addToEntity(_orb, ToolTipType.CLICK);
			
			_orb.add(sceneInter);
			_orb.add(new ToolTip());
		}
		
		private function createParticles():void
		{
			_memoryParticleEmitter = new MemoryParticles();
			_emitterEntity = EmitterCreator.create(_scene, _container, _memoryParticleEmitter);
			_emitterEntity.add(new MemoryParticlesComponent(_memoryParticleEmitter));
			_emitterEntity.add(new TargetSpatial(_scene.shellApi.player.get(Spatial)));
			
			var spatialP:Spatial = _emitterEntity.get(Spatial);
			var spatialO:Spatial = _orb.get(Spatial);
			
			spatialP.x = spatialO.x;
			spatialP.y = spatialO.y;
			
			_memoryParticleEmitter.init(spatialO);
			
			if(_lowQuality){
				_memoryParticleEmitter.sparkle(5);
			} else {
				_memoryParticleEmitter.sparkle();
			}
			
			this.addSystem(new MemoryParticlesSystem(), SystemPriorities.render);
		}
		
		public function activateMemory(...p):void
		{
			if(!_inMemory)
			{
				_inMemory = true;
				shellApi.triggerEvent("alienMemory");
				startMemory.dispatch();

				_orb.get(Motion).rotationVelocity = 400; 		// spin orb faster
				EntityUtils.positionByEntity( _orbGlow, _orb );	// position glow to orb
				
				var glowDisplay:Display = _orbGlow.get(Display);
				glowDisplay.alpha = 1;
				glowDisplay.visible = true;
	
				// tween color of clips
				var glowMC:DisplayObject = glowDisplay.displayObject;
				var goalMC:DisplayObject = EntityUtils.getDisplayObject(_goal);
				var orbMC:DisplayObject = EntityUtils.getDisplayObject(_orb);
				
				var tween:Tween = this.groupEntity.get(Tween);
				if(!tween){
					tween = new Tween();
					this.groupEntity.add(tween);
				}
				
				// NOTE :: May need to remove these on mobile.
				//Drew - Filters can't happen on mobile! Commenting out.
				//tween.to(orbMC, 2, {colorMatrixFilter:{colorize:0xFFCCFF, contrast:2, amount:1}});
				//tween.to(glowMC, 2, {colorMatrixFilter:{colorize:0xFFCCFF, amount:1}});
				//tween.to(goalMC, 2, {colorMatrixFilter:{colorize:0xFFCCFF, contrast:2, amount:1}});
				//tween.to(glowSpatial, 2, {scaleX:7, scaleY:7, onComplete:dizzyPlayer});	// NOTE :: This scaling was the performance issue
	
				if(_lowQuality){
					_memoryParticleEmitter.activateMemory(10);
				} else {
					_memoryParticleEmitter.activateMemory();
				}
				
				SceneUtil.lockInput(this, true);
				SceneUtil.delay( _scene, 2, dizzyPlayer );
			}
		}
		
		private function dizzyPlayer():void
		{
			var sLightingGroup:SubsceneLightingGroup = _scene.getGroupById("subsceneLightingGroup") as SubsceneLightingGroup;
			sLightingGroup.activateMemory();
			
			makePlayerDizzy();
			
			var cameraEntity:Entity = _scene.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			camera.scaleTarget = 1.2;	//TODO  :: Ideally we trigger playMemory once camera has finished zoom. -bard
			
			// after a bit, playMemory
			SceneUtil.delay(this, 2.3, playMemory );
		}
		
		private function makePlayerDizzy(reverse:Boolean = false):void
		{
			if(!reverse){
				SkinUtils.setSkinPart( _scene.playerDummy, SkinUtils.MOUTH, "distressedMom" );
				SkinUtils.setSkinPart( _scene.playerDummy, SkinUtils.EYES, "hypnotized" );
			} else {
				SkinUtils.setSkinPart( _scene.playerDummy, SkinUtils.MOUTH, 1 ); // temporary
				SkinUtils.setSkinPart( _scene.playerDummy, SkinUtils.EYES, "eyes" ); // temporary
			}
		}
		
		// open memory popup
		private function playMemory():void
		{
			shellApi.triggerEvent("alienImage");
			var popup:TeleImagesPopup = _scene.addChildGroup( new TeleImagesPopup( _scene.overlayContainer )) as TeleImagesPopup;
			popup.id = "teleImagesPopup";
			popup.popupRemoved.addOnce(deactivateMemory);
		}
		
		private function deactivateMemory(...p):void
		{	
			var sLightingGroup:SubsceneLightingGroup = _scene.getGroupById("subsceneLightingGroup") as SubsceneLightingGroup;
			sLightingGroup.restoreDefaultLighting();

			_orb.get(Motion).rotationVelocity = 200;
			
			var glowDisplay:Display = _orbGlow.get(Display);
			glowDisplay.alpha = 1;
			glowDisplay.visible = true;
			
			// tween color of clips
			var glowMC:DisplayObject = glowDisplay.displayObject;
			var goalMC:DisplayObject = EntityUtils.getDisplayObject(_goal);
			var orbMC:DisplayObject = EntityUtils.getDisplayObject(_orb);
			
			var tween:Tween = this.groupEntity.get(Tween);
			
			//Drew - Filters can't happen on mobile! Commenting out.
			//tween.to(orbMC, 2, {colorMatrixFilter:{}});
			//tween.to(glowMC, 2, {colorMatrixFilter:{}});
			//tween.to(goalMC, 2, {colorMatrixFilter:{}});
			//tween.to(glowSpatial, 2, {scaleX:1, scaleY:1});	// NOTE :: this was the performance issue.

			_memoryParticleEmitter.deactivateMemory();
			SceneUtil.delay(this, 2, comeTo );
		}
		
		private function comeTo():void
		{
			var cameraEntity:Entity = _scene.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			camera.scaleTarget = 1;
			
			this.makePlayerDizzy(true);
			SceneUtil.lockInput(this, false);

			SceneUtil.delay(this, 1, finishMemory );
		}
		
		private function finishMemory():void
		{
			_inMemory = false;
			finishedMemory.dispatch();
		}
		
		public function createSecurityWalls():void
		{
			_securityWalls = new Vector.<Entity>();
			
			var wall:Entity;
			var zone:Zone;
			// finds every orb melting wall and loads them
			for (var i:int = 0; _container[WALL_ID+i] != null; i++) 
			{
				wall = EntityUtils.createSpatialEntity(this,_container[WALL_ID + i]);	// NOTE :: basic vector, doesn't need to be bitmapped
				wall.add(new Id(WALL_ID+i));
				EntityUtils.visible(wall, false,true);

				zone = new Zone();
				zone.entered.add(destroyOrb);
				zone.pointHit = true;
				wall.add(zone);
				wall.add(new Sleep(false,true));
				_securityWalls.push(wall);
			}
		}
		
		private function destroyOrb(zoneId:String, id:String):void
		{
			if(id == ORB_ID)
			{
				// make beam visible
				var wall:Entity = getEntityById(zoneId);
				EntityUtils.visible(wall, true);
				SceneUtil.addTimedEvent(this, new TimedEvent(1,1,Command.create(EntityUtils.visible,wall,false)));
				
				// hide orb
				fadeOrb(false);
			}
		}
	}
}