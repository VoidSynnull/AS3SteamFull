package game.scenes.examples.hitAreas{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.RadialCollider;
	import game.components.hit.Wall;
	import game.components.hit.Zone;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MoverHitData;
	import game.data.scene.hit.MovingHitData;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.systems.SystemPriorities;
	import game.systems.hit.HitEntityListSystem;
	import game.util.CharUtils;
	
	public class HitAreas extends PlatformerGameScene
	{
		public function HitAreas()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/hitAreas/";
			// makes hits visible for debugging.
			super.showHits = true;
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
			
			var btnClip:MovieClip;
			var labelFormat:TextFormat = new TextFormat("CreativeBlock BB", 20, 0xD5E1FF);
			
			btnClip = MovieClip(super._hitContainer).btn1;
			ButtonCreator.createButtonEntity( btnClip, this, toggleWall );
			ButtonCreator.addLabel( btnClip, "Toggle Wall", labelFormat, ButtonCreator.ORIENT_CENTERED );
			
			addCustomHits();

			configureZones();
			
			var door1:Entity = super.getEntityById("door1");
			Sleep(door1.get(Sleep)).ignoreOffscreenSleep = true;
			door1.ignoreGroupPause = true;
			Sleep(door1.get(Sleep)).sleeping = true;
			
			super.addSystem(new LastHitDisplaySystem(), SystemPriorities.moveComplete);
			
			super.player.add(new RadialCollider());
		}
		
		private function toggleWall(button:Entity):void
		{
			var wall:Entity = super.getEntityById("wall1");
			
			if(wall.get(Wall))
			{
				wall.remove(Wall);
				Display(wall.get(Display)).visible = false;
			}
			else
			{
				wall.add(new Wall());
				Display(wall.get(Display)).visible = true;
			}
		}
		
		private function addCustomHits():void
		{
			var hitCreator:HitCreator = new HitCreator();
			hitCreator.showHits = true;
			// most hit types will use default values if hitData is left out.
			
			hitCreator.createHit(super._hitContainer["dynamicHit"], HitType.PLATFORM, null, this);
			
			// you can optionally specify hit data if you need more control over a hit to configure it.  See HitCreator.addHitComponent for more
			//   details on how hitData is used.
			var moverHitData:MoverHitData = new MoverHitData();
			moverHitData.velocity = new Point(0, -600);
			var bouncyHit:Entity = hitCreator.createHit(super._hitContainer["dynamicHit2"], HitType.BOUNCE, moverHitData, this);
			hitCreator.addAudioToHit(bouncyHit, "icicle_fall_hit_01.mp3");
			
			// some hits require hitdata to function such as movers.
			moverHitData = new MoverHitData();
			moverHitData.acceleration = new Point(0, -2200);
			moverHitData.friction = new Point(600, 600);
			hitCreator.createHit(super._hitContainer["dynamicHit3"], HitType.MOVER, moverHitData, this);
			
			// moving platforms also require data to specify their path.
			var movingHitData:MovingHitData = new MovingHitData();
			movingHitData.loop = true;
			movingHitData.velocity = 200;
			movingHitData.points = [new Point(360, 420), new Point(360, 180)];
			hitCreator.createHit(super._hitContainer["dynamicHit4"], HitType.MOVING_PLATFORM, movingHitData, this);
			
			// multiple hit types can be applied to the same hit entity as well.  HitCreator.makeHit
			//  will cause the necessary components to be added to an existing entity rather than a new one created.
			movingHitData = new MovingHitData();
			movingHitData.loop = true;
			movingHitData.velocity = 50;
			movingHitData.points = [new Point(820, 140), new Point(820, 300)];
			var hitEntity:Entity = hitCreator.createHit(super._hitContainer["dynamicHit5"], HitType.MOVING_PLATFORM, movingHitData, this);
			hitCreator.makeHit(hitEntity, HitType.BOUNCE);
			
			var hazardHitData:HazardHitData = new HazardHitData();
			hazardHitData.knockBackCoolDown = .75;
			hazardHitData.knockBackVelocity = new Point(400, 400);
			hazardHitData.velocityByHitAngle = true;
			var hazHitEntity:Entity = hitCreator.createHit(super._hitContainer["dynamicHazHit"], HitType.HAZARD, hazardHitData, this);
			hitCreator.addAudioToHit(hazHitEntity, "icicle_fall_hit_01.mp3");
	
			/*
			var npc:Entity = super.getEntityById("npc");
			var charGroup:CharacterGroup = super.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			charGroup.addFSM( npc );
			// turns the npc into a hazard.  'makeHit' adds the necessary components to an existing entity with a display compononent.
			hitCreator.makeHit(npc, HitType.HAZARD, hazardHitData, this);
			
			var path:Vector.<Point> = new Vector.<Point>;
			path.push(new Point(1100, 920));
			path.push(new Point(1900, 920));

			var charMotionCtrl:CharacterMotionControl = npc.get(CharacterMotionControl);
			charMotionCtrl.maxVelocityX = 300;
			charMotionCtrl.maxAirVelocityX = 300;
			
			CharUtils.followPath(npc, path, null, false, true, new Point(30, 50));
			*/
		}
		
		private function configureZones():void
		{
			super._hitContainer["light1"].gotoAndStop("off");
			super._hitContainer["light2"].gotoAndStop("off");
			
			var entity:Entity = super.getEntityById("zone1");
			var zone:Zone = entity.get(Zone);
			zone.pointHit = true;
			
			zone.entered.add(handleZoneEntered);
			zone.exitted.add(handleZoneExitted);
			zone.inside.add(handleZoneInside);
			
			entity = super.getEntityById("zone2");
			zone = entity.get(Zone);
			zone.pointHit = true;
			
			zone.entered.add(handleZoneEntered);
			zone.exitted.add(handleZoneExitted);
			zone.inside.add(handleZoneInside);
		}
		
		private function handleZoneEntered(zoneId:String, characterId:String):void
		{			
			switch(zoneId)
			{
				case "zone1" :
					super._hitContainer["light1"].gotoAndStop("on");
				break;
				
				case "zone2" :
					super._hitContainer["light2"].gotoAndStop("on");
				break;
			}
		}
		
		private function handleZoneExitted(zoneId:String, characterId:String):void
		{
			switch(zoneId)
			{
				case "zone1" :
					super._hitContainer["light1"].gotoAndStop("off");
					break;
				
				case "zone2" :
					super._hitContainer["light2"].gotoAndStop("off");
					break;
			}
		}
		
		private function handleZoneInside(zoneId:String, characterId:String):void
		{
			switch(zoneId)
			{
				case "zone1" :
					super._hitContainer["light1"].label.text = Number(super._hitContainer["light1"].label.text) + 1;
					break;
				
				case "zone2" :
					super._hitContainer["light2"].label.text = Number(super._hitContainer["light2"].label.text) + 1;
					break;
			}
		}
	}
}