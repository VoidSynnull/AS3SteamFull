package game.scenes.deepDive3.outro
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.managers.SoundManager;
	
	import game.components.entity.Sleep;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.WaveMotionData;
	import game.scene.template.AudioGroup;
	import game.scene.template.CutScene;
	import game.scene.template.GameScene;
	import game.scenes.deepDive3.DeepDive3Events;
	import game.scenes.deepDive3.shared.particles.ShipParticles;
	import game.scenes.deepDive3.ship.Ship;
	import game.systems.SystemPriorities;
	import game.systems.motion.WaveMotionSystem;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class Outro extends CutScene
	{
		
		public function Outro()
		{
			super();
			configData("scenes/deepDive3/outro/", DeepDive3Events(events).FINAL_CUTSCENE);
		}
		
		override protected function sceneAssetsLoaded():void
		{
			_screen = super.getAsset(sceneData.assets[0],true) as MovieClip;
			groupContainer.addChild(_screen);
			
			addSystems();
			
			_sceneEntity = EntityUtils.createSpatialEntity(this, _screen, container);
			_sceneEntity.add( new Id( "cutscene_screen") );
			
			if(super.getData(GameScene.SOUNDS_FILE_NAME) != null)
			{
				audioGroup = new AudioGroup();
				audioGroup.setupGroup(this, super.getData(GameScene.SOUNDS_FILE_NAME));
			}
			
			var bitmapQuality:Number = PerformanceUtils.defaultBitmapQuality;
			
			var sceneClip:MovieClip = _screen["sceneWide"];
			BitmapUtils.convertContainer( sceneClip["gull"], bitmapQuality);
			BitmapUtils.convertContainer( sceneClip["shipShadow"], bitmapQuality);
			
			BitmapUtils.convertContainer( sceneClip["Ship1"], bitmapQuality);
			BitmapUtils.convertContainer( sceneClip["sky"], bitmapQuality);
			BitmapUtils.convertContainer( sceneClip["boat"], bitmapQuality);
			
			_shotWide = TimelineUtils.convertAllClips( sceneClip,_sceneEntity,this,false );
			_shotWide.add( new Display(sceneClip, null, true) );
			_shotWide.add( new Spatial());
			_shotWide.add( new Sleep(false,true) );
			
			sceneClip = _screen["sceneMedium"];
			BitmapUtils.convertContainer( sceneClip["miniScene"], bitmapQuality);
			BitmapUtils.convertContainer( sceneClip["spaceShip"], bitmapQuality);
			
			_shotMedium = TimelineUtils.convertAllClips( sceneClip,_sceneEntity,this,false );
			_shotMedium.add( new Display(sceneClip, null, false) );
			_shotMedium.add( new Spatial());
			_shotMedium.add( new Sleep(true,true) );
			
			_sky = super.getEntityById( "sky" );
			
			this.loaded();
		}
		
		// all assets ready
		override public function loaded():void
		{
			audioGroup.addAudioToEntity(_sceneEntity);
			_sceneAudio = _sceneEntity.get(Audio);
			
			var timeline:Timeline = _shotWide.get(Timeline);
			timeline.labelReached.add( onLabelReached );
			
			timeline = _shotMedium.get(Timeline);
			timeline.labelReached.add( onLabelReached );
			
			//super.setUpResolution();
			DisplayUtils.fitDisplayToScreen(this, container,CUT_SCENE_RESOLUTION);
			
			SceneUtil.lockInput( this );
			
			// TODO :: Use normal sound.xml to manage sounds. - bard
			try
			{
				soundManager.cache(SoundManager.MUSIC_PATH + "atlantis_3_ending_cutscene.mp3"); // precache music
				soundManager.cache(SoundManager.EFFECTS_PATH + "warp_zap.mp3"); // precache music
			} 
			catch(error:Error)
			{
				trace(error.getStackTrace());
			}
			
			super.childrenPlay( _shotWide );
			Timeline(_sky.get(Timeline)).playing = false;
			super.groupReady();
		}
		
		override public function onLabelReached(label:String):void
		{
			switch(label)
			{
				case "started":
					_sceneAudio.play(SoundManager.EFFECTS_PATH + "alien_ship_takeoff.mp3");
					_sceneAudio.setVolume(0.6);
					break;
				case "showMedium":
					EntityUtils.setSleep( _shotWide, true );
					EntityUtils.setSleep( _shotMedium, false );
					EntityUtils.visible( _shotWide, false);
					EntityUtils.visible( _shotMedium, true );
					super.childrenPlay( _shotMedium );
					_sceneAudio.setVolume(2);
					break;
				case "shakeCamera1":
					cameraShake(2,.9);
					break;
				case "showWide":
					EntityUtils.setSleep( _shotWide, false );
					EntityUtils.visible( _shotWide, true);
					Timeline(_shotWide.get(Timeline)).gotoAndPlay("shakeCamera2");
					super.removeEntity( _shotMedium, true );
					break;
				case "shakeCamera2":
					_sceneAudio.setVolume(1);
					_waveMotionData.magnitude = 1.4;
					_waveMotionData.rate = 1.4;
					TweenUtils.globalTo(this, _waveMotionData, 6, {magnitude:0.5});
					break;
				case "shakeCamera3":
					_waveMotionData.rate = 1;
					TweenUtils.globalTo(this, _waveMotionData, 1, {magnitude:2});
					break;
				case "shakeCamera4":
					_waveMotionData.rate = 0.1;
					_waveMotionData.magnitude = 12;
					TweenUtils.globalTo(this, _waveMotionData, 3, {magnitude:0});
					if(_particles)
					{
						_particles.sparkle(0);
						_particles.attractToSpatial(new Spatial(465,-30));
					}
					break;
				case "partClouds":
					Timeline(_sky.get(Timeline)).playing = true;
					break;
				case "powerUp":
					if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGHER) { createParticles(); }
					break;
				case "lightning1":
				case "lightning2":
				case "lightning3":
					shellApi.triggerEvent("lightning");
					break;
				case "shipShake":
					shellApi.triggerEvent("shake");
					break;
				case "woosh":
					shellApi.triggerEvent("woosh");
					shellApi.triggerEvent("warpZap");
					break;
				case "ended":
					super.shellApi.completeEvent(completeEvent);
					shellApi.loadScene( Ship, 1070, 1936, "right" );
					break;
			}
		}
		
		private function createParticles():void
		{
			_particles = new ShipParticles();
			_particlesEmitter = EmitterCreator.create(this, this.screen, _particles);
			
			Spatial(_particlesEmitter.get(Spatial)).x = 500;
			Spatial(_particlesEmitter.get(Spatial)).y = 275;
			
			_particles.init(_particlesEmitter.get(Spatial));
			
			_particles.sparkle();
		}
		
		private function cameraShake( magnitude:Number = 2, rate:Number = .5):void
		{
			var waveMotion:WaveMotion = new WaveMotion();
			
			_waveMotionData = new WaveMotionData();
			_waveMotionData.property = "y";
			_waveMotionData.magnitude = magnitude;
			_waveMotionData.rate = rate;
			_waveMotionData.radians = 90;
			waveMotion.data.push(_waveMotionData);
			
			this.sceneEntity.add(waveMotion);
			this.sceneEntity.add(new SpatialAddition());
			
			if(!super.hasSystem(WaveMotionSystem))
			{
				super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			}
		}
		
		private function stopCamShake():void
		{
			var waveMotion:WaveMotion = this.sceneEntity.get(WaveMotion);
			
			this.sceneEntity.remove(WaveMotion);
			var spatialAddition:SpatialAddition = this.sceneEntity.get(SpatialAddition);
			spatialAddition.y = 0;
		}
		
		private var _shotWide:Entity;
		private var _shotMedium:Entity;
		private var _sky:Entity;
		private var _waveMotionData:WaveMotionData;
		private var _particles:ShipParticles;
		private var _particlesEmitter:Entity;
		
		[Inject]
		public var soundManager:SoundManager;
	}
}