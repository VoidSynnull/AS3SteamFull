package game.scenes.ftue
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.systems.MotionSystem;
	import engine.systems.TweenSystem;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.motion.Edge;
	import game.components.motion.TargetSpatial;
	import game.components.motion.Threshold;
	import game.creators.entity.EmitterCreator;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Stand;
	import game.data.display.BitmapWrapper;
	import game.scene.template.CharacterGroup;
	import game.scenes.ftue.intro.Intro;
	import game.scenes.ftue.shared.particles.SmokeParticles;
	import game.systems.SystemPriorities;
	import game.systems.input.InteractionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class AceRaceScene extends FtueScene
	{
		protected var _wrench:Entity;
		protected var _airplane1:Entity;
		protected var _airplane2:Entity;
		protected var _airplane3:Entity;
		protected var _airplane4:Entity;
		protected var _airplane5:Entity;
		public var _airplaneB:Entity;
		protected var _blimp:Entity;
		protected var _balloon:Entity;
		public var baron:Entity;
		protected var _officiate:Entity;
		protected var _pilot:Entity
		
		protected var _explosion:Entity;
		
		protected var _smokeParticles:SmokeParticles;
		protected var _smokeParticleEmitter:Entity;
		protected var _charGroup:CharacterGroup;
		
		public var titleClip:MovieClip;
		
		public const PROP_SOUND:String = SoundManager.EFFECTS_PATH + "Plane_L_loop_01_loop.mp3";
		public const PROP_SOUND_BROKE:String = SoundManager.EFFECTS_PATH + "Plane_H_loop_01_loop.mp3";
		
		private var camera:Entity;
		
		public function AceRaceScene()
		{
			super();
		}
		
		override protected function addBaseSystems():void
		{
			super.addSystem(new InteractionSystem(), SystemPriorities.update);
			super.addSystem(new MotionSystem(), SystemPriorities.move);
			super.addSystem(new TweenSystem());
			super.addSystem(new TimelineControlSystem());
			super.addSystem(new TimelineClipSystem());
			
			super.addBaseSystems();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			camera = getEntityById("camera");
			
			_charGroup = new CharacterGroup();  
			_charGroup.setupGroup(this);
			
			initBGAnimations();
			
			setupEntities();
			
			initAnimations();
			
			initSounds();
			
			SceneUtil.setCameraPoint(this, shellApi.camera.viewportWidth / 2 , shellApi.viewportHeight/2, true);
			
			this.removeSystemByClass(SpecialAbilityControlSystem);
		}
		
		protected function initSounds():void
		{
			// TODO Auto Generated method stub
			
		}
		
		protected function setupEntities():void
		{
			_airplane1 = EntityUtils.createMovingEntity(this, _hitContainer["airplane_1"], _hitContainer);
			MotionUtils.addWaveMotion(_airplane1, new WaveMotionData("y", 15, 0.02, "sin", Math.random()), this);
			MotionUtils.addWaveMotion(_airplane1, new WaveMotionData("x", 50, 0.014, "sin", Math.random()), this);
			
			_airplane2 = EntityUtils.createMovingEntity(this, _hitContainer["airplane_2"], _hitContainer);
			MotionUtils.addWaveMotion(_airplane2, new WaveMotionData("y", 15, 0.02, "sin", Math.random()), this);
			MotionUtils.addWaveMotion(_airplane2, new WaveMotionData("x", 50, 0.014, "sin", Math.random()), this);
			
			_airplane3 = EntityUtils.createMovingEntity(this, _hitContainer["airplane_3"], _hitContainer);
			MotionUtils.addWaveMotion(_airplane3, new WaveMotionData("y", 15, 0.02, "sin", Math.random()), this);
			MotionUtils.addWaveMotion(_airplane3, new WaveMotionData("x", 50, 0.014, "sin", Math.random()), this);
			
			_airplane4 = EntityUtils.createMovingEntity(this, _hitContainer["airplane_4"], _hitContainer);
			MotionUtils.addWaveMotion(_airplane4, new WaveMotionData("y", 15, 0.02, "sin", Math.random()), this);
			MotionUtils.addWaveMotion(_airplane4, new WaveMotionData("x", 50, 0.014, "sin", Math.random()), this);
			TimelineUtils.convertClip(_hitContainer["airplane_4"]["props"], this);
			
			_airplane5 = EntityUtils.createMovingEntity(this, _hitContainer["airplane_5"], _hitContainer);
			MotionUtils.addWaveMotion(_airplane5, new WaveMotionData("y", 15, 0.02, "sin", Math.random()), this);
			MotionUtils.addWaveMotion(_airplane5, new WaveMotionData("x", 50, 0.014, "sin", Math.random()), this);
			
			_airplaneB = EntityUtils.createMovingEntity(this, _hitContainer["airplane_b"], _hitContainer);
			MotionUtils.addWaveMotion(_airplaneB, new WaveMotionData("y", 15, 0.02, "sin", 0.5), this);
			MotionUtils.addWaveMotion(_airplaneB, new WaveMotionData("x", 8, 0.008, "sin", 0.5), this);
			
			TimelineUtils.convertClip(_hitContainer["airplane_b"]["prop"], this, null, null, true, 60);
			
			_balloon = EntityUtils.createMovingEntity(this, _hitContainer["balloon"], _hitContainer);
			MotionUtils.addWaveMotion(_balloon, new WaveMotionData("y", 15, 0.02, "sin", 1), this);
			MotionUtils.addWaveMotion(_balloon, new WaveMotionData("x", 8, 0.008, "sin", 1), this);
			Display(_balloon.get(Display)).visible = false;
			
			// optimize
			convertContainer(Display(_airplane1.get(Display)).displayObject);
			convertContainer(Display(_airplane2.get(Display)).displayObject);
			convertContainer(Display(_airplane3.get(Display)).displayObject);
			convertContainer(Display(_airplane4.get(Display)).displayObject);
			convertContainer(Display(_airplane5.get(Display)).displayObject);
			convertContainer(Display(_airplaneB.get(Display)).displayObject);
			
			baron = characterInPlane(this.getEntityById("baron"), _airplaneB, "baron", "right");
			
			_officiate = characterInPlane(this.getEntityById("officiate"), _balloon, "baron", "left");
			EntityUtils.removeInteraction(_officiate);
			
			EntityUtils.removeInteraction(baron);
			
			_explosion = EntityUtils.createMovingTimelineEntity(this, _hitContainer["explosion"], _hitContainer);
			MotionUtils.addWaveMotion(_explosion, new WaveMotionData("y", 15, 0.02, "sin", 1), this);
			MotionUtils.addWaveMotion(_explosion, new WaveMotionData("x", 8, 0.008, "sin", 1), this);
			
			shellApi.loadFile(shellApi.assetPrefix +"scenes/arab1/shared/particles/smoke_particle.swf", setupSmokeParticles);
			
			_wrench = EntityUtils.createSpatialEntity(this, _hitContainer["wrench"], _hitContainer);
			Display(_wrench.get(Display)).visible = false;
			
			initAnimations();
		}
		
		protected function setupSmokeParticles(clip:DisplayObjectContainer):void
		{
			
			_smokeParticles = new SmokeParticles();
			_smokeParticleEmitter = EmitterCreator.create(this, _hitContainer, _smokeParticles, -50, -30, null, null, _explosion.get(Spatial));
			_smokeParticles.init(clip);
			
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH){
				//_emberParticles = new EmberParticles();
				//_emberParticleEmitter = EmitterCreator.create(this, _hitContainer, _emberParticles, 0, 0, null, null, _explosion.get(Spatial));
				//_emberParticles.init(this);
			}
			
			//_smokeParticles.stream();
		}
		
		protected function characterInPlane(char:Entity, plane:Entity, name:String, direction:String = "right", offset:Spatial = null, stand:Boolean = true, underPlane:Boolean = true):Entity
		{
			_charGroup.removeFSM(char);
			
			char.add(new Motion()); // turn off falling 
			if(stand) CharUtils.setAnim(char, Stand);
			
			var spatial:Spatial = char.get(Spatial);
			spatial.rotation = 0;
			
			// add spatial offset if necessary
			if(offset)
			{
				spatial.x = offset.x;
				spatial.y = offset.y;
			}
			
			// remove sleep
			Sleep(char.get(Sleep)).sleeping = false;
			Sleep(char.get(Sleep)).ignoreOffscreenSleep = true;
			
			// adjust edge for dialog
			Edge(char.get(Edge)).rectangle.height = 92;
			
			// place character underneath vehicle's display index
			//if(underPlane) DisplayUtils.moveToOverUnder(Display(char.get(Display)).displayObject, Display(plane.get(Display)).displayObject, false);
			var display:Display = char.get(Display);
			display.setContainer(EntityUtils.getDisplayObject(plane));
			display.moveToBack();
			
			//Dialog(char.get(Dialog)).container = display.container;
			
			return char;
		}
		
		protected function initAnimations():void
		{
			
		}
		
		protected function initBGAnimations():void
		{
			var cloudForegroundContainer:MovieClip = new MovieClip();
			cloudForegroundContainer.y = -shellApi.viewportHeight / 2;
			cloudForegroundContainer.x = -shellApi.viewportWidth/2;
			groupContainer.addChild(cloudForegroundContainer);
			DisplayUtils.moveToOverUnder(cloudForegroundContainer, _hitContainer);
			
			var clip:MovieClip = _hitContainer["cloud"];
			var bounds:Rectangle = clip.getBounds(clip);
			
			var bitmapData:BitmapData = createBitmapData(clip,PerformanceUtils.defaultBitmapQuality);
			_hitContainer.removeChild(clip);
			
			var sprite:Sprite;
			var entity:Entity;
			var motion:Motion;
			var threshold:Threshold;
			var edge:Edge;
			
			var section:Number = shellApi.viewportWidth / 2;
			
			addSystem(new ThresholdSystem());
			
			for(var i:int = 0; i < 4; i++)
			{
				for(var z:int = 0; z < 2; z ++)
				{
					sprite = createBitmapSprite(clip, 1, null, true, 0, bitmapData, false);
					entity = EntityUtils.createSpatialEntity(this, sprite, z==0?_hitContainer:cloudForegroundContainer);
					motion = new Motion();
					motion.velocity.x = z==0?-120:-240;
					entity.add(motion);
					threshold = new Threshold("x", "<");
					threshold.entered.add(Command.create(wrapCloud, entity, z == 0));
					entity.add(threshold);
					
					edge = new Edge();
					edge.unscaled = bounds;
					
					entity.add(edge);
					
					wrapCloud(entity, z == 0);
					
					Spatial(entity.get(Spatial)).x -= section * (i - 1);
					
					if(z==0)
						DisplayUtils.moveToBack(sprite);
				}
			}
			// force title on top for intro scene
			if (this is Intro)
			{
				titleClip = MovieClip(cloudForegroundContainer.addChild(_hitContainer["title"]));
				titleClip.alpha = 0;
			}
			
			// islands and sharks
			var islandBitmapData:Vector.<BitmapWrapper> = new Vector.<BitmapWrapper>();
			for(i = 0; i < 3; i++)
			{
				clip = _hitContainer["island"+i];
				_hitContainer.removeChild(clip);
				islandBitmapData.push(convertToBitmapSprite(clip, null, false, PerformanceUtils.defaultBitmapQuality));
			}
			islandBitmapData.push(islandBitmapData[0].duplicate(true,true));
			islandBitmapData.push(islandBitmapData[0].duplicate(true,true));
			islandBitmapData.push(islandBitmapData[1].duplicate(true,true));
			
			for(i = 0; i < 4; i++)
			{
				sprite = new Sprite();
				sprite.y = 610;
				sprite.addChild(new Bitmap());
				entity = EntityUtils.createSpatialEntity(this, sprite, _hitContainer);
				motion = new Motion();
				motion.velocity.x = -30;
				entity.add(motion);
				threshold = new Threshold("x", "<");
				threshold.threshold = -100;
				threshold.entered.add(Command.create(wrapIsland, entity, islandBitmapData));
				entity.add(threshold);
				wrapIsland(entity, islandBitmapData);
				Spatial(entity.get(Spatial)).x -= section * i;
				DisplayUtils.moveToBack(sprite);
				entity.remove(Sleep);
			}
		}
		
		private function wrapCloud(entity:Entity, backGround:Boolean):void
		{
			var scale:Point = backGround? new Point(.75, 1):new Point(1, 2);
			var range:Point;
			
			var spatial:Spatial = entity.get(Spatial);
			spatial.scaleX = scale.x + (scale.y - scale.x) * Math.random();
			if(Math.random() > .5)
				spatial.scaleX *= -1;
			
			spatial.scaleY = scale.x + (scale.y - scale.x) * Math.random();
			
			var edge:Edge = entity.get(Edge);
			
			if(backGround)
				range = new Point(0, shellApi.viewportHeight * .5);
			else
			{
				var size:Number = edge.unscaled.height * spatial.scaleY;
				range = Math.random() >.5?new Point(-size + 40, -size + 80):new Point(shellApi.viewportHeight - 80, shellApi.viewportHeight - 40);
			}
			
			var cameraX:Number = shellApi.viewportWidth / 2;
			var target:Spatial = camera.get(TargetSpatial).target;
			var threshold:Threshold = entity.get(Threshold);
			
			if(backGround)
			{
				cameraX = target.x;
				threshold.target = target;
				threshold.offset = - shellApi.viewportWidth * 1.5;
			}
			else
				threshold.threshold = -edge.unscaled.width * Math.abs(spatial.scaleX);
			
			spatial.y = range.x + (range.y - range.x) * Math.random();
			spatial.x = cameraX + shellApi.viewportWidth / 2 + Math.random() * shellApi.viewportWidth + edge.unscaled.width * Math.abs(spatial.scaleX);
		}
		
		private function wrapIsland(entity:Entity, islands:Vector.<BitmapWrapper>):void
		{
			var bitmap:Bitmap = EntityUtils.getDisplayObject(entity).getChildAt(0) as Bitmap;
			
			var wrapper:BitmapWrapper = islands[Math.floor(Math.random() * islands.length)];
			
			bitmap.x = wrapper.bitmap.x;
			bitmap.y = wrapper.bitmap.y;
			bitmap.bitmapData = wrapper.bitmap.bitmapData;
			
			var spatial:Spatial = entity.get(Spatial);
			
			var threshold:Threshold = entity.get(Threshold);
			
			var cameraX:Number = shellApi.viewportWidth / 2;
			var target:Spatial = camera.get(TargetSpatial).target;
			if(target)
			{
				cameraX = target.x;
				threshold.target = target;
				threshold.offset = - shellApi.viewportWidth * 1.5;
			}
			else
				threshold.threshold = -100;
			
			spatial.x = cameraX +  shellApi.viewportWidth /2 + shellApi.viewportWidth / 2 * Math.random();
		}
	}
}