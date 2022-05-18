package game.scenes.mocktropica.mockLoadingScreen
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Zone;
	import game.components.input.Input;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.particles.emitter.Burst;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scenes.mocktropica.mockLoadingScreen.components.PixelCollapseComponent;
	import game.scenes.mocktropica.mockLoadingScreen.systems.PixelCollapseSystem;
	import game.scenes.mocktropica.server.Server;
	import game.scenes.mocktropica.shared.AchievementGroup;
	import game.systems.SystemPriorities;
	import game.systems.hit.ZoneHitSystem;
	import game.ui.transitions.components.LoadingScreenLetterComponent;
	import game.ui.transitions.systems.LoadingScreenLetterSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class MockLoadingScreen extends PlatformerGameScene
	{
		private var _hittingHead:Boolean = false;
		private var _currentEntity:Entity;
		private var _lettersLeft:uint = 10;
		private var _mockEvents:MocktropicaEvents;
		
		public function MockLoadingScreen()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/mocktropica/mockLoadingScreen/";
			
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
			
			_mockEvents = super.events as MocktropicaEvents;
			
			//Removing this event so it will re-trigger every time I test this scene.
			super.shellApi.removeEvent(_mockEvents.ACHIEVEMENT_CLASSIC);
			
			this.addSystem(new LoadingScreenLetterSystem(), SystemPriorities.move);
			this.addSystem(new ZoneHitSystem(), SystemPriorities.checkCollisions);
			
			setupPoptropicaLogo();
			
			SceneUtil.lockInput(this, true);
			SceneUtil.addTimedEvent( this, new TimedEvent( 4, 1, enterScene ) );
			
			//putting this in so I can test the new ui loading screen on ext2
			//super.shellApi.sceneManager.loadingTransitionClass = LogoLoadingScreen;
		}
		
		private function setupPoptropicaLogo():void
		{
			for(var i:int=1; i<=16; i++)
			{
				//create hazard hits
				/*var hitCreator:HitCreator = new HitCreator();
				var hazardHitData:HazardHitData = new HazardHitData();
				hazardHitData.knockBackCoolDown = 0.75;
				hazardHitData.knockBackVelocity = new Point(0, -500);
				//hazardHitData.velocityByHitAngle = true;
				var hazHitEntity:Entity = hitCreator.createHit(super._hitContainer["l" + i], HitType.HAZARD, hazardHitData, this);
				hitCreator.addAudioToHit(hazHitEntity, "icicle_fall_hit_01.mp3");*/
				
				var do3D:Boolean = false;
				if (i < 11) {
					do3D = true;
				}
				var doWave:Boolean = true;
				if (i > 11) {
					doWave = false;
				}
				
				var entity:Entity = EntityUtils.createSpatialEntity(this, super._hitContainer["l" + i]);
				entity.add(new Id("l" + i));
				entity.add(new LoadingScreenLetterComponent(entity.get(Spatial), i, doWave, do3D, do3D));
				entity.add(shellApi.inputEntity.get(Input));
				
				if (do3D) {
					var zone:Zone = new Zone();
					entity.add(zone);
					zone.shapeHit = true;
					zone.pointHit = false;
					zone.entered.add(handleZoneEntered);
				}
			}
		}
		
		private function handleZoneEntered(zoneId:String, characterId:String):void
		{
			if (_hittingHead) {
				return;
			}
			_hittingHead = true;
			var motion:Motion = super.player.get(Motion);
			motion.velocity.y = motion.acceleration.y = motion.totalVelocity.y = 200;
			
			//if player is wearing the safety helmet
			if ( SkinUtils.getSkinPart( super.player, SkinUtils.FACIAL ).value == "mk_helmet" )
			{
				super.shellApi.triggerEvent("playBreakSound");
				
				super._hitContainer[zoneId + "Extrusion"].visible = false;
				super._hitContainer[zoneId + "Outline"].visible = false;
				var entity:Entity = super.getEntityById(zoneId);
				_currentEntity = entity;
				Display(entity.get(Display)).visible = false;
				var spatial:Spatial = entity.get(Spatial);
				createBurst(spatial.x, spatial.y, super._hitContainer);
				//super.removeEntity(entity, true); //this messes up player control for some reason
				
				SceneUtil.addTimedEvent( this, new TimedEvent( 0.5, 1, finishLetterBreak ) );
			}
			else
			{
				super.shellApi.triggerEvent("playHurtSound");
				
				Dialog(player.get(Dialog)).sayById("owMyNoggin");
				SceneUtil.addTimedEvent( this, new TimedEvent( 0.5, 1, finishHeadPain ) );
			}
			
		}
		
		private function finishHeadPain():void
		{
			_hittingHead = false;
		}
		
		private function finishLetterBreak():void
		{
			_hittingHead = false;
			_currentEntity.remove(LoadingScreenLetterComponent);
			_currentEntity.remove(Zone);
			
			_lettersLeft --;
			if (_lettersLeft <= 0)
			{
				doAchievement();
			}
		}
		
		private function createBurst(x:Number, y:Number, container:DisplayObjectContainer):void
		{
			var emitter:Burst = new Burst();
			emitter.init(8, 0xff035099, 0xffffffff, 20, 0.5, 1.5, true, false);
			
			var entity:Entity = EmitterCreator.create(this, container, emitter);
			entity.get(Spatial).x = x;
			entity.get(Spatial).y = y;
			
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			
			entity.add(sleep);
			Emitter(entity.get(Emitter)).remove = true;
		}
		
		private function enterScene():void
		{
			CharUtils.moveToTarget(super.player, 200, super.sceneData.bounds.bottom, false, makeComment);
		}
		
		private function makeComment(entity:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("cheap");
			SceneUtil.lockInput(this, false);
		}
		
		private function doAchievement():void
		{
			var achievement:AchievementGroup = new AchievementGroup( this );
			this.addChildGroup( achievement );
			achievement.completeAchievement( _mockEvents.ACHIEVEMENT_CLASSIC );
			achievement.onAchievementComplete.addOnce(startGlitching);
		}
		
		private function startGlitching():void
		{
			super.shellApi.triggerEvent("playGlitchSound");
			
			//do the glitch effect
			this.addSystem(new PixelCollapseSystem(), SystemPriorities.move);
			
			var pixelCollapseClip:MovieClip = new MovieClip();
			pixelCollapseClip.x = 0;
			pixelCollapseClip.y = 0;
			super._hitContainer.addChild(pixelCollapseClip);
			var entity:Entity = EntityUtils.createSpatialEntity(this, pixelCollapseClip);
			entity.add(new Id("pixelCollapseEntity"));
			entity.add(new PixelCollapseComponent(Display(entity.get(Display)), super.sceneData.cameraLimits.right, super.sceneData.cameraLimits.bottom, 20));
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 7, 1, loadServerScene ) );
		}
		
		private function loadServerScene():void
		{
			super.shellApi.loadScene(Server);
		}
	}
}