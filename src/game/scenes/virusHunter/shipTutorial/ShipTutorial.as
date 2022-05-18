package game.scenes.virusHunter.shipTutorial
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.systems.TweenSystem;
	
	import game.components.motion.Edge;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.Zone;
	import game.creators.entity.EmitterCreator;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.KillCount;
	import game.scenes.virusHunter.shared.components.Virus;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shipTutorial.components.SceneState;
	import game.scenes.virusHunter.shipTutorial.systems.SceneManagerSystem;
	import game.scenes.virusHunter.shipTutorial.systems.SceneWeaponTargetSystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.CharacterDialogWindow;
	import game.util.TimelineUtils;
	
	public class ShipTutorial extends ShipScene
	{
		public function ShipTutorial()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/shipTutorial/";
			//super.minCameraScale = .5;
			//super.showHits = true;
			super.init(container);
			
			super.shellApi.completeEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_GOO);
			super.shellApi.completeEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_SHOCK);
			super.shellApi.completeEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_SCALPEL);
			super.shellApi.completeEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_SHIELD);
			super.shellApi.completeEvent(VirusHunterEvents(super.shellApi.islandEvents).GOT_ANTIGRAV);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			setupAnimations();
		}
		
		private function setupAnimations():void
		{
			var clips:Array = ["fat1Art", "fat2Art", "fat3Art", "bloodFlow1Art", "bloodFlow2Art", "fan"];
			var abovePlayer:Array = ["fat1Art", "fat2Art", "fat3Art", "nerve1", "nerve2", "nerve3", "nerve4"];
			var entity:Entity;
			var sleep:Sleep;
			var clipName:String;
			var timeline:Timeline;
			
			for(var n:int = 0; n < clips.length; n++)
			{
				clipName = clips[n];
				entity = TimelineUtils.convertClip(super._hitContainer[clipName]["animation"], this);
				entity.add(new Id(clipName));
				entity.add(new Spatial(super._hitContainer[clipName].x, super._hitContainer[clipName].y));
				sleep = entity.get(Sleep);
				sleep.useEdgeForBounds = true;
				
				if(clipName.indexOf("fat") > -1)
				{
					timeline = entity.get( Timeline );
					timeline.labelReached.add(handleReachedFatLabel);
				}
			}
			
			var playerDisplay:Display = super.shellApi.player.get(Display);
			var playerDepth:int = playerDisplay.container.getChildIndex(playerDisplay.displayObject);
			var nextClip:Sprite;
			
			for(n = 0; n < abovePlayer.length; n++)
			{
				nextClip = super._hitContainer[abovePlayer[n]];
				super._hitContainer.setChildIndex(nextClip, playerDepth);
			}
			
			// setup special bounds for the fan's particles.
			entity.add(new Edge(300, 100, 100, 100));
			
			var dust:FanParticles = new FanParticles();
			dust.init();
			
			sleep.ignoreOffscreenSleep = true;
			var emitterEntity:Entity = EmitterCreator.create(this, super._hitContainer, dust, 0, 0, entity);
			emitterEntity.get(Spatial).x = super._hitContainer["fan"].x - 30;
			emitterEntity.get(Spatial).y = super._hitContainer["fan"].y;
		}
		
		private function handleReachedFatLabel(label:String):void
		{
			if(label == "fatOpen")
			{
				super.shellApi.triggerEvent("fatOpen");
			}
			else if(label == "fatTear")
			{
				super.shellApi.triggerEvent("fatTear");	
			}
		}
		
		private function begin():void
		{
			_sceneState = new SceneState();
			_sceneStateEntity = new Entity();
			_sceneStateEntity.add(_sceneState);
			
			super.addEntity(_sceneStateEntity);
			
			_shipGroup = super.getGroupById("shipGroup") as ShipGroup;
			_shipGroup.createSceneWeaponTargets(super._hitContainer);
			_shipGroup.addSpawn(super.getEntityById("bloodFlow1Target"), EnemyType.RED_BLOOD_CELL, 12, new Point(80, 40), new Point(0, 40), new Point(0, 140), .5);
			_shipGroup.addSpawn(super.getEntityById("bloodFlow2Target"), EnemyType.RED_BLOOD_CELL, 12, new Point(80, 40), new Point(0, 40), new Point(0, 140), .5);
			var enemySpawn:EnemySpawn = _shipGroup.createOffscreenSpawn(EnemyType.RED_BLOOD_CELL, 6, .5, 40, 140, 5);
			//enemySpawn.max = 3;
			
			super.addSystem(new SceneWeaponTargetSystem(this), SystemPriorities.checkCollisions);
			super.addSystem(new SceneManagerSystem(this, _shipGroup.enemyCreator), SystemPriorities.lowest);
			super.addSystem(new TweenSystem(), SystemPriorities.update);
			
			setupZones();
			
			/*
			var test:Entity = new Entity();
			test.add(new Spatial());
			test.add(new Display(super._hitContainer["test"]));
			//var motion:Motion = new Motion();
			//motion.rotationVelocity = 100;
			//test.add(motion);
			var movieClipHit:MovieClipHit = new MovieClipHit(EnemyType.ENEMY_HIT, "ship", "shipMelee");
			movieClipHit.shapeHit = true;
			test.add(movieClipHit);
			test.add(new Id("test"));
			test.add(new Type(EnemyType.ENEMY_HIT));
			var hazard:Hazard = new Hazard();
			hazard.velocity = new Point(4, 4);
			hazard.damage = 0.2;
			hazard.coolDown = 1;
			test.add(hazard);
			_shipGroup.addDamageFactor(test, WeaponType.BASIC_GUN);
			_shipGroup.addDamageFactor(test, WeaponType.SHOCK);
			super.addEntity(test);
			*/
		}
		
		private function setupZones():void
		{
			var zones:Array = ["fatZone", "muscleZone", "nerveZone", "bloodZone", "fanZone", "virusZone"];
			var zone:Entity;
			
			for(var n:uint = 0; n < zones.length; n++)
			{
				zone = super.getEntityById(zones[n]);
				Zone(zone.get(Zone)).entered.addOnce(zoneEntered);
			}
		}
		
		// all assets ready
		override protected function allShipsLoaded():void
		{
			super.allShipsLoaded();
			
			var killCount:KillCount = new KillCount();
			killCount.count[EnemyType.VIRUS] = 0;
			killCount.count[EnemyType.RED_BLOOD_CELL] = 0;
			
			super.shellApi.player.add(killCount);
		}
				
		private function zoneEntered(zoneId:String, entityId:String):void
		{			
			super.playMessage(zoneId, true, null, "drLang");
			
			if(zoneId == "virusZone")
			{
				super._dialogWindow.messageComplete.add(startVirusSpawn);
			}
			
			var zone:Entity = super.getEntityById(zoneId);
			super.removeEntity(zone, true);
		}
		
		private function startVirusSpawn():void
		{
			if(super._dialogWindow.currentDialogEvent == "virusZone3")
			{
				super._dialogWindow.messageComplete.remove(startVirusSpawn);
				var virus:Virus = new Virus();
				_shipGroup.createOffscreenSpawn(EnemyType.VIRUS, 5, .5, virus.seekVelocity, virus.seekVelocity + 25);
				_sceneState.state = _sceneState.SPAWN_VIRUS;
			}
		}
		
		override protected function characterDialogWindowReady(charDialog:CharacterDialogWindow):void
		{
			super.characterDialogWindowReady(charDialog);
			
			begin();
			
			super.playMessage("intro", true, null, "drLang");
			//super.playMessage("arm_warning", false, null, "drLang");
		}
		
		override protected function messageCompleteHandler():void
		{
			if(_sceneState.state == _sceneState.FINAL_DIALOG)
			{
				_sceneState.state = _sceneState.LEAVE_TUTORIAL;
			}
		}
		
		private var _sceneState:SceneState;
		private var _sceneStateEntity:Entity;
		private var _shipGroup:ShipGroup;
	}
}