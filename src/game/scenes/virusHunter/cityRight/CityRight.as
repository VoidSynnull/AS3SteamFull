package game.scenes.virusHunter.cityRight{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.motion.MotionControl;
	import game.components.motion.Navigation;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.BlowingLeaves;
	import game.particles.emitter.SwarmingFlies;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class CityRight extends PlatformerGameScene
	{
		private var _leavesEntity:Entity;
		private var _fliesEntity:Entity;
		private var virusEvents:VirusHunterEvents;
		private var _falafelGuy:Entity;
		private var _animationsContainer:DisplayObjectContainer;
		
		private var _vanEntity:Entity;
		private var _vanWheel1Entity:Entity;
		private var _vanWheel2Entity:Entity;
		private var _manWithShades:Entity;
		private var _drLange:Entity;
		private var camera:CameraSystem;
		private var savedCameraRate:Number;
		private var _hungryWoman:Entity;
		private var _loiteringGuy:Entity;
		
		public function CityRight()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/cityRight/";
			
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
			
			virusEvents = super.events as VirusHunterEvents;
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			_manWithShades = super.getEntityById("manWithShades");
			_drLange = super.getEntityById("drLange");
			_hungryWoman = super.getEntityById("hungryWoman");
			_loiteringGuy = super.getEntityById("loiteringGuy");
			
			CharUtils.setDirection(_hungryWoman, true);
			CharUtils.setDirection(_loiteringGuy, true);
			
			var emitter:BlowingLeaves = new BlowingLeaves(); 
			_leavesEntity = EmitterCreator.create(this, super._hitContainer, emitter, 0, 0); 
			emitter.init( new LineZone( new Point(0,super.sceneData.cameraLimits.bottom/2), new Point(0,super.sceneData.cameraLimits.bottom) ), new Point(300,50), new RectangleZone(super.sceneData.cameraLimits.left, super.sceneData.cameraLimits.top, super.sceneData.cameraLimits.right, super.sceneData.cameraLimits.bottom) );
			
			var fliesEmitter:SwarmingFlies = new SwarmingFlies();
			_fliesEntity = EmitterCreator.create(this, super._hitContainer, fliesEmitter, 0, 0);
			fliesEmitter.init(new Point(1270, 1200));
			
			//positional flies sound
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "insect_flies_02_L.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			//entity.add(new Display(super._hitContainer["soundSource"]));
			entity.add(audio);
			entity.add(new Spatial(1270, 1200));
			entity.add(new AudioRange(500, 0, 0.4, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
			
			//birds and sign are purely visual
			var clip:MovieClip;
			for(var i:int = 1; i <= 2; i++)
			{
				clip = super.hitContainer["bird" + i];
				DisplayUtils.moveToTop(clip);
				var bird:Entity = EntityUtils.createSpatialEntity(this, clip);
				TimelineUtils.convertClip(clip, this, bird);
				
				var timeline:Timeline = bird.get(Timeline);
				timeline.handleLabel("chirp", Command.create(birdChirp, bird), false);
				
				bird.add(new Id("bird" + i));
				bird.add(new Audio());
				bird.add(new AudioRange(900));
			}
			TimelineUtils.convertClip( MovieClip(super._hitContainer).falafelSign, this );
			
			_falafelGuy = super.getEntityById("falafelGuy");
			
			if (super.shellApi.checkEvent(virusEvents.DELIVERED_FALAFEL))
			{
				super.removeEntity(_hungryWoman);
			}
			else if (super.shellApi.checkEvent(virusEvents.DELIVERING_FALAFEL))
			{
				super.removeEntity(_falafelGuy);
			}
			else if (super.shellApi.checkEvent(virusEvents.SEARCHED_MAIL))
			{
				//show delivery bag in hand
				SkinUtils.setSkinPart(_falafelGuy, SkinUtils.ITEM, "is_fbag");
			}
			
			if ( super.shellApi.checkEvent(virusEvents.SAW_VAN_ON_RIGHT) ) {
				removeVan();
			}
			else {
				setVan();
			}
		}
		
		private function birdChirp(bird:Entity):void
		{
			var audio:Audio = bird.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "bird_chirp_single_01.mp3", false, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "falafelGuyLeaves")
			{
				falafelGuyLeaves();
			}
		}
		
		private function removeVan():void
		{
			super.removeEntity(_manWithShades);
			super.removeEntity(_drLange);
			MovieClip(super._hitContainer).van.visible = false;
		}
		
		private function setVan():void
		{
			SceneUtil.lockInput(this, true);
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, panToVan ) );
			
			Sleep(_manWithShades.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(_manWithShades.get(Sleep)).sleeping = false;
			CharUtils.stateDrivenOff(_manWithShades, 99999);
			SceneInteraction(_manWithShades.get(SceneInteraction)).offsetY = 100;
			
			var vanClip:MovieClip = MovieClip(super._hitContainer).van;
			_vanEntity = EntityUtils.createMovingEntity(this, vanClip, super._hitContainer);
			
			var vanWheel1Clip:MovieClip = vanClip.wheel1;
			_vanWheel1Entity = EntityUtils.createMovingEntity(this, vanWheel1Clip, vanClip);
			var vanWheel2Clip:MovieClip = vanClip.wheel2;
			_vanWheel2Entity = EntityUtils.createMovingEntity(this, vanWheel2Clip, vanClip);
			
			super._hitContainer.setChildIndex(_vanEntity.get(Display).displayObject, 0);
			super._hitContainer.setChildIndex(_manWithShades.get(Display).displayObject, 0);
		}
		
		private function panToVan():void
		{
			/*
			camera = this.getSystem( CameraSystem ) as CameraSystem;
			camera.jumpToTarget = false;
			savedCameraRate = camera.rate;
			camera.rate = 0.05;
			camera.target = _manWithShades.get(Spatial);
			*/
			vanLeaves();
		}
		
		private function vanLeaves():void
		{			
			_manWithShades.remove(FSMControl);
			_manWithShades.remove(AnimationControl);
			_manWithShades.remove(MotionControl);
			_manWithShades.remove(Navigation);
			
			_manWithShades.add( new Motion() );
			Motion(_manWithShades.get(Motion)).velocity = new Point(0, 0);
			Motion(_manWithShades.get(Motion)).acceleration = new Point(-500, 0);
			
			Motion(_vanEntity.get(Motion)).velocity = new Point(0, 0);
			Motion(_vanEntity.get(Motion)).acceleration = new Point(-500, 0);
			
			Motion(_vanWheel1Entity.get(Motion)).rotationVelocity = 0;
			Motion(_vanWheel1Entity.get(Motion)).rotationAcceleration = -500;
			
			Motion(_vanWheel2Entity.get(Motion)).rotationVelocity = 0;
			Motion(_vanWheel2Entity.get(Motion)).rotationAcceleration = -500;
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2.2, 1, langeEntersVideoStore ) );
			
			super.shellApi.triggerEvent("playVanSound");
		}
		
		private function langeEntersVideoStore():void
		{
			//camera.rate = savedCameraRate;
			//camera.target = super.player.get(Spatial);
			
			CharUtils.moveToTarget(_drLange, 645, super.sceneData.bounds.bottom, false, finishLangeLeaves);
		}
		
		private function finishLangeLeaves(entity:Entity = null):void
		{
			super.shellApi.completeEvent(virusEvents.SAW_VAN_ON_RIGHT);
			SceneUtil.lockInput(this, false);
			SceneUtil.addTimedEvent( this, new TimedEvent( 0.3, 1, removeVan ) );
		}
		
		private function falafelGuyLeaves():void{
			CharUtils.moveToTarget(_falafelGuy, -200, super.sceneData.bounds.bottom, false, removeFalafelGuy);
			shellApi.completeEvent(virusEvents.DELIVERING_FALAFEL);
			
			Dialog(_hungryWoman.get(Dialog)).sayById("womanComplains");
		}
		
		private function removeFalafelGuy(entity:Entity):void
		{
			super.removeEntity(entity);
			super.shellApi.completeEvent(virusEvents.DELIVERING_FALAFEL);
		}
	}
}