package game.scenes.arab2.cells
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.Item;
	import game.components.hit.Platform;
	import game.components.hit.SceneObjectHit;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.TargetSpatial;
	import game.components.motion.Threshold;
	import game.components.render.DynamicWire;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Sleep;
	import game.data.animation.entity.character.Stomp;
	import game.data.sound.SoundModifier;
	import game.particles.FlameCreator;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.arab2.Arab2Events;
	import game.scenes.arab2.shared.MagicSandGroup;
	import game.scenes.deepDive2.predatorArea.particles.GlassParticles;
	import game.systems.SystemPriorities;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.render.DynamicWireSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class Cells extends PlatformerGameScene
	{
		private var _events:Arab2Events;
		private var _sceneObjectCreator:SceneObjectCreator;
		
		private const BREAK_ROOF:String = SoundManager.EFFECTS_PATH +"stone_break_06.mp3";
		private const BREAK_WALL:String = SoundManager.EFFECTS_PATH +"large_stone_01.mp3";
		private const HIT_ROOF:String = SoundManager.EFFECTS_PATH +"arrow_hit_rock_01.mp3";
		
		private const BREAK_BED:String = SoundManager.EFFECTS_PATH +"wood_break_01.mp3";
		private const GUARD_HIT_SOUND:String = SoundManager.EFFECTS_PATH+"big_pow_01.mp3";
		private const CAUGHT_PLAYER:String = SoundManager.EFFECTS_PATH+"event_07.mp3";
		private const CAUGHT_MUSIC:String = SoundManager.MUSIC_PATH+"caught_by_thieves.mp3";
		
		private const OPEN_CAGE:String = SoundManager.EFFECTS_PATH+"door_prison_01.mp3";
		
		
		private var magicSandGroup:MagicSandGroup;
		private var charGroup:CharacterGroup; 
		private var _flameCreator:FlameCreator;
		
		// count roof head bashes
		private var roofHits:int = 0;
		private var roofEmitter:GlassParticles;
		private var wallEmitter:GlassParticles;
		
		public function Cells()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab2/cells/";
			//showHits = true;
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
			charGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			
			setupMagicSand();
			setupDropObjects();
			setupGuards();
			//setupBed();
			setupBreakableBarriers();
			setupVizierCage();
			setupKey();
			setupFire();
			
			super.shellApi.eventTriggered.add(handleEvents);
		}
		
		private function handleEvents(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _events.PLAYER_CAUGHT_CELLS){
				showFail();
			}
			else if(event == "viz_chatted"){
				unlock();
				shellApi.completeEvent(_events.TALKED_TO_VIZIER);
				SceneUtil.addTimedEvent(this, new TimedEvent(1,1, moveViz));
			}
			if(!shellApi.checkEvent(_events.VIZIER_FOLLOWING)){
				if(event == "open_cell"){
					unlockCage();
				}
				else if(event == "use_cell_key"){
					moveToCage();
				}
			}
			
		}
		
		private function moveToCage():void
		{
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(new Point(_hitContainer["nav0"].x,_hitContainer["nav0"].y));
			path.push(new Point(_hitContainer["nav1"].x,_hitContainer["nav1"].y));
			CharUtils.followPath(player,path,delayOpen,false,false,new Point(20,100),true);
		}
		
		private function delayOpen(...p):void
		{
			SceneUtil.addTimedEvent(this,new TimedEvent(0.4,1,unlockCage));
		}
		
		private function setupVizierCage():void
		{
			// run vizeir events
			var vizier:Entity = getEntityById("vizier");
			SceneInteraction(vizier.get(SceneInteraction)).ignorePlatformTarget = false;
			if(!shellApi.checkEvent(_events.TALKED_TO_VIZIER)){	
				SceneUtil.addTimedEvent(this, new TimedEvent(1.5,1, talkToVizier));
			}else if(!shellApi.checkEvent(_events.VIZIER_FOLLOWING)){
				EntityUtils.position(vizier,1185,1455);
			}else if(!this.shellApi.checkItemEvent(_events.MEDAL)){
				EntityUtils.position(vizier,player.get(Spatial).x + 30,player.get(Spatial).y);
				CharUtils.followEntity(vizier,player,new Point(150,100));
			}else{
				this.removeEntity(vizier);
			}
			
			var clip:MovieClip = _hitContainer["gate"];
			var cage:Entity = TimelineUtils.convertClip(clip,this,null,null,false);
			if(PlatformUtils.isMobileOS)
				BitmapTimelineCreator.convertToBitmapTimeline(cage,clip);
			cage.add(new Id("gate"));
			if(shellApi.checkEvent(_events.VIZIER_FOLLOWING)){
				Timeline(cage.get(Timeline)).gotoAndStop("opened");
				removeEntity(getEntityById("cellWall"));
			}else{
				Timeline(cage.get(Timeline)).gotoAndStop("closed");
			}
		}
		
		private function unlockCage(...p):void
		{
			CharUtils.setDirection(player, false);
			var cage:Entity = getEntityById("gate");
			removeEntity(getEntityById("cellWall"));
			CharUtils.setAnim(player, Salute);
			Timeline(player.get(Timeline)).handleLabel("stop",Command.create(Timeline(cage.get(Timeline)).gotoAndPlay,"open"));
			Timeline(player.get(Timeline)).handleLabel("stop",Command.create(AudioUtils.play,this, OPEN_CAGE, 2.0));
			var vizier:Entity = getEntityById("vizier");
			Timeline(cage.get(Timeline)).handleLabel("opened",Command.create(vizFreed,vizier));
			CharUtils.followEntity(vizier,player,new Point(150,100));
			//SceneInteraction(getEntityById("door1").get(SceneInteraction)).reached.addOnce(escaped);
			shellApi.triggerEvent(_events.VIZIER_FOLLOWING,true);
		}
		
		private function vizFreed(vizier:Entity):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5,1,Command.create(Dialog(vizier.get(Dialog)).sayById,"out")));
		}
		
		//private function escaped(...p):void
		//{
		//	shellApi.triggerEvent(_events.VIZIER_RESCUED,true);
		//}
		
		private function moveViz(...p):void
		{
			var vizier:Entity = getEntityById("vizier");
			CharUtils.moveToTarget(vizier,1185,1465);
		}
		
		private function talkToVizier():void
		{
			var vizier:Entity = getEntityById("vizier");
			var dialog:Dialog = Dialog(vizier.get(Dialog));
			dialog.sayById("start");
			SceneUtil.setCameraTarget(this,vizier);
			SceneUtil.lockInput(this,true);
		}
		
		private function unlock(...p):void
		{
			SceneUtil.setCameraTarget(this,player);
			SceneUtil.lockInput(this,false);
		}
		
		private function setupBreakableBarriers():void
		{
			addSystem(new DynamicWireSystem(), SystemPriorities.update);
			var ball:Entity = getEntityById("dropper0");
			
			var roof:Entity = EntityUtils.createMovingTimelineEntity(this,_hitContainer["breakableRoofArt"],_hitContainer,false);
			var wall:Entity = EntityUtils.createMovingTimelineEntity(this, _hitContainer["breakableRockArt"],_hitContainer,false);
			if(!shellApi.checkEvent(_events.PLAYER_ESCAPED_CELL)){
				var zone:Zone = new Zone();
				zone.shapeHit = true;
				zone.pointHit = false;
				zone.entered.add(Command.create(hitRoof,roof));
				roof.add(zone);
				wall.add(new Id("bWall"))
				var chain:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["chain"]);
				chain.add(new Id("chain"));
				chain.add(new TargetSpatial(wall.get(Spatial)));
				chain.add(new DynamicWire(300,0x888888,0x333333,2,1));
				var follow:FollowTarget = new FollowTarget(ball.get(Spatial),1,false,true)
				follow.offset = new Point(0,-40);
				chain.add(follow);
				roofEmitter = new GlassParticles();
				roofEmitter.init(BitmapUtils.createBitmapData(_hitContainer["shard1"]),170,250,0,500);
				var roofEmitEnt:Entity = EmitterCreator.create(this, _hitContainer, roofEmitter, 0, 0, roof,null,roof.get(Spatial));
				wallEmitter = new GlassParticles();
				wallEmitter.init(BitmapUtils.createBitmapData(_hitContainer["shard2"]),-170,300,-170,600);
				var wallEmitEnt:Entity = EmitterCreator.create(this, _hitContainer, wallEmitter, 0, 0, wall,null,wall.get(Spatial));
				wallEmitEnt.get(Spatial).rotation = -90;
			}else{
				// smashed cell already
				Timeline(roof.get(Timeline)).gotoAndStop("broken");
				Timeline(wall.get(Timeline)).gotoAndStop("end");
				removeEntity(getEntityById("breakableWall"));
				removeEntity(getEntityById("breakableRoof"));
				var bed:Entity = getEntityById("bed");	
				bed.get(Spatial).x = 670;
				Timeline(bed.get(Timeline)).gotoAndStop("broken");
				var ballPlat:Entity = getEntityById("ballPlatform");
				Display(ballPlat.get(Display)).isStatic = false;
				follow = new FollowTarget(ball.get(Spatial),1);
				follow.offset = new Point(0,-20);
				ballPlat.add(follow);
				bed.remove(Platform);
				bed.remove(SceneObjectHit);
				ball.remove(SceneObjectHit);
				ball.remove(Threshold);
				EntityUtils.positionByEntity(ball,bed,false,false);
				ball.get(Spatial).rotation = 90;
			}
			
		}
		
		private function hitRoof(z:String,c:String,roofArt:Entity):void
		{
			if(c == "player"){
				if(roofHits < 2){
					roofHits++;
					AudioUtils.play(this,HIT_ROOF,1,false);
					roofArt.get(Timeline).gotoAndStop(roofHits);
				}else{
					AudioUtils.play(this,BREAK_ROOF,1.4,false);
					roofArt.get(Timeline).gotoAndStop("broken");
					var roof:Entity = getEntityById("breakableRoof");
					removeEntity(roof);
					//removeEntity(roofArt);
					roofArt.remove(Zone);
					explodeRoof(roofArt);
				}
			}
		}
		
		private function explodeRoof(roof:Entity):void
		{
			roofEmitter.spark(60);
		}
		
		private function setupMagicSand():void
		{
			magicSandGroup = getGroupById(MagicSandGroup.GROUP_ID) as MagicSandGroup;
			if(!magicSandGroup){
				magicSandGroup = MagicSandGroup(this.addChildGroup(new MagicSandGroup(_hitContainer)));
			}			
			magicSandGroup.setupPlatforms();
		}
		
		private function setupDropObjects():void
		{
			_sceneObjectCreator = new SceneObjectCreator();
			
			super.addSystem(new SceneObjectHitRectSystem());
			
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add( new Mass(100) );
			
			for (var g:int = 0; g < 3; g++) 
			{			
				var guard:Entity = getEntityById("guard"+g);
				if(guard){
					SceneInteraction(guard.get(SceneInteraction)).ignorePlatformTarget = false;
				}
			}
			
			var ball:Entity;
			var clip:MovieClip;
			var bounds:Rectangle;
			var zone:Zone;
			var zoneEnt:Entity;
			for (var i:int = 0; _hitContainer["dropper"+i] != null; i++) 
			{
				clip = _hitContainer["bounds"+i];
				bounds = new Rectangle(clip.x,clip.y,clip.width,clip.height);
				_hitContainer.removeChild(clip);
				clip = _hitContainer["dropper"+i] ;
				if(PlatformUtils.isMobileOS)
					convertContainer(clip);
				ball = _sceneObjectCreator.createCircle(clip,0.01,super.hitContainer,clip.x, clip.y,null,null,bounds,this,null,null,400);
				SceneObjectMotion(ball.get(SceneObjectMotion)).rotateByPlatform = false;
				if(i != 0){
					ball.remove(SceneObjectHit);
				}
				ball.add(new Id("dropper"+i));
				ball.add(new WallCollider());
				ball.add(new PlatformCollider());
				ball.add(new ZoneCollider());
				var audioGroup:AudioGroup = AudioGroup(getGroupById(AudioGroup.GROUP_ID));
				audioGroup.addAudioToEntity(ball, "dropper"+i);
				new HitCreator().addHitSoundsToEntity(ball,audioGroup.audioData,shellApi,"dropper"+i);
				zoneEnt = getEntityById("zone"+i);
				zone = zoneEnt.get(Zone);
				if(i == 0){
					setupBed();
					ball = getEntityById("bed");
					audioGroup.addAudioToEntity(ball, "bed");
					new HitCreator().addHitSoundsToEntity(ball,audioGroup.audioData,shellApi,"bed");
				}
				zone.entered.add(Command.create(enteredDropZone,ball,zoneEnt));
			}
		}
		
		private function setupGuards():void
		{
			var guardsEvent:String;
			var guard:Entity;
			if(shellApi.checkEvent(_events.CELL_GUARD_1_DOWN)){
				guard = getEntityById("guard"+0);
				knockOut(guard);
				removeEntity(getEntityById("zone"+0));			
			}
			if(shellApi.checkEvent(_events.CELL_GUARD_2_DOWN)){
				guard = getEntityById("guard"+2);
				knockOut(guard);
				removeEntity(getEntityById("zone"+2));			
			}
			if(shellApi.checkEvent(_events.CELL_JAILER_DOWN)){
				guard = getEntityById("guard"+1);
				//Don't show the knocked out jailer if you've already gotten the medallion
				if(this.shellApi.checkItemEvent(_events.MEDAL))
				{
					this.removeEntity(guard);
				}
				else
				{
					knockOut(guard);
				}
				removeEntity(getEntityById("zone"+1));	
			}
		}
		
		private function knockOut(guard:Entity, makeSound:Boolean = false):void
		{
			CharUtils.setAnim(guard, game.data.animation.entity.character.Sleep);
			SkinUtils.setSkinPart(guard, SkinUtils.EYES, "hypnotized");
			guard.get(SceneInteraction).reached.removeAll();
			guard.get(SceneInteraction).reached.add(outCold);
			if(makeSound){
				AudioUtils.play(this, GUARD_HIT_SOUND, 1, false,null,null,1.5);
			}
		}
		
		private function enteredDropZone(zoneId:String, hitId:String, dropper:Entity, zoneEnt:Entity):void
		{
			// guard that's on zone
			var target:Entity = getEntityById("guard"+zoneId.substr(zoneId.length-1));
			if(hitId == "player"){
				// fail for player
				catchPlayer(target,zoneEnt);
			}
			else if(hitId.substr(0,hitId.length-1) == "dropper" || hitId == "bed"){
				// hit guard
				hitGuard(target,zoneEnt,dropper);
			}
		}
		
		private function smashBed(...p):void
		{
			// make bed smashed, ready to drop on guard's head
			var chain:Entity = getEntityById("chain");
			removeEntity(chain);
			var ball:Entity = getEntityById("dropper0");
			var ballPlat:Entity = getEntityById("ballPlatform");
			Display(ballPlat.get(Display)).isStatic = false;
			EntityUtils.positionByEntity(ballPlat,ball,false,false);
			var follow:FollowTarget = new FollowTarget(ball.get(Spatial),1);
			follow.offset = new Point(0,-20);
			ballPlat.add(follow);
			var bed:Entity = getEntityById("bed");
			bed.remove(Platform);
			bed.remove(SceneObjectHit);
			ball.remove(SceneObjectHit);
			ball.get(Spatial).rotation = 90;
			Timeline(bed.get(Timeline)).gotoAndStop("broken");
			AudioUtils.play(this, BREAK_WALL, 1, false,null,null,1.0);
			AudioUtils.play(this, BREAK_BED, 1, false,null,null,1.0);
			removeWall();
		}
		
		private function removeWall():void
		{
			var wall:Entity = getEntityById("breakableWall");
			removeEntity(wall);
			var wallArt:Entity = getEntityById("bWall");
			Timeline(wallArt.get(Timeline)).gotoAndPlay("smash");
			shellApi.completeEvent(_events.PLAYER_ESCAPED_CELL);
			wallEmitter.spark(60);
		}
		
		// 
		private function setupBed():void
		{
			addSystem(new ThresholdSystem());
			var clip:MovieClip = _hitContainer["bedBounds"];
			var bounds:Rectangle = new Rectangle(clip.x,clip.y,clip.width,clip.height);
			_hitContainer.removeChild(clip);
			if(PlatformUtils.isMobileOS)
			{
				convertContainer(clip);
			}
			clip = _hitContainer["bed"];
			var bed:Entity = _sceneObjectCreator.createBox(clip,0.01,super.hitContainer,clip.x, clip.y,null,null,bounds,this,null,null,600);
			bed = TimelineUtils.convertClip(clip,this,bed,null,false);
			SceneObjectMotion(bed.get(SceneObjectMotion)).rotateByPlatform = false;
			bed.add(new Id("bed"));
			bed.add(new WallCollider());
			bed.add(new PlatformCollider());
			bed.add(new ZoneCollider());
			var threshHold:Threshold = new Threshold("y",">");
			threshHold.threshold = 1350;
			threshHold.entered.addOnce(smashBed);
			var ball:Entity = getEntityById("dropper0");
			ball.add(threshHold); 
		}
		
		private function hitGuard(guard:Entity, zoneEnt:Entity, dropper:Entity):void
		{
			knockOut(guard,true);
			// clear zone
			removeEntity(zoneEnt);
			var guardId:String = guard.get(Id).id;
			var dropMotion:Motion = dropper.get(Motion);
			dropMotion.velocity.y = -300;
			if(dropper.get(Id).id == "bed"){
				removeEntity(getEntityById("ballPlatform"));
			}
			if(guardId == "guard0"){
				shellApi.completeEvent(_events.CELL_GUARD_1_DOWN);
			}
			else if(guardId == "guard1"){
				dropKey(guard);
			}
			else if(guardId == "guard2"){
				shellApi.completeEvent(_events.CELL_GUARD_2_DOWN);
			}
		}
		
		private function outCold(...p):void
		{
			player.get(Dialog).sayById("outCold");
		}
		
		
		private function setupKey():void
		{
			addSystem(new ThresholdSystem());
			var key:Entity = getEntityById("cell_key");
			if(key){
				if(!shellApi.checkEvent(_events.CELL_JAILER_DOWN)){
					// hide key
					key.get(Display).alpha = 0;
					key.remove(Item);
					ToolTipCreator.removeFromEntity(key);
				}
			}
		}
		
		private function dropKey(guard:Entity):void
		{
			// launch key into air like atlantis1
			shellApi.completeEvent(_events.CELL_JAILER_DOWN);
			var key:Entity = getEntityById("cell_key");
			if(key){
				key.get(Display).alpha = 1;
				ToolTipCreator.addToEntity(key);
				var p:Point = EntityUtils.getPosition(key);
				EntityUtils.positionByEntity(key,guard);
				charGroup.addColliders(key); 
				var motion:Motion = new Motion();
				motion.velocity = new Point(100, -400);
				motion.acceleration = new Point(0, 700);
				motion.friction = new Point(0.4, 0);
				key.add(motion);
				var threshold:Threshold = new Threshold("y",">");
				threshold.threshold = p.y + 5;
				threshold.entered.addOnce(Command.create(landKey,key));
				key.add(threshold);
			}
		}
		
		private function landKey(key:Entity):void
		{
			key.remove(Motion);
			key.add(new Item());
			SceneUtil.setCameraTarget(this,key);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5,1,saySomething));
		}
		
		private function saySomething():void
		{
			unlock();
			Dialog(player.get(Dialog)).sayById("heyKey");
		}
		
		private function catchPlayer(guard:Entity, zoneEnt:Entity):void
		{
			// DIALOG
			var dialog:Dialog = Dialog(guard.get(Dialog));
			if(!checkDisguise()){
				CharUtils.setAnim(guard, Stomp);
				Timeline(guard.get(Timeline)).handleLabel("end", Command.create(sayHalt,dialog));
				SceneUtil.setCameraTarget(this,guard);
				SceneUtil.lockInput(this,true);
				AudioUtils.play(this, CAUGHT_PLAYER, 1, false,null,null,1.0);
			}			
		}		
		
		private function checkDisguise():Boolean
		{
			var wearingThiefOutfit:Boolean = true;
			
			if(!SkinUtils.hasSkinValue(player, SkinUtils.FACIAL, "an2_player"))
			{
				wearingThiefOutfit = false;
			}
			if(!SkinUtils.hasSkinValue(player, SkinUtils.OVERSHIRT, "an2_player"))
			{
				wearingThiefOutfit = false;
			}
			if(wearingThiefOutfit){
				if(!shellApi.checkEvent(_events.PLAYER_DISGUISED)){
					shellApi.triggerEvent(_events.PLAYER_DISGUISED,true);
				}
			}else{
				shellApi.removeEvent(_events.PLAYER_DISGUISED);
			}
			return wearingThiefOutfit;
		}
		
		private function sayHalt(dialog:Dialog):void
		{
			dialog.sayById("halt");
		}
		
		private function showFail(...p):void
		{
			AudioUtils.play(this, CAUGHT_MUSIC, 1, false, [SoundModifier.EFFECTS]);
			shellApi.loadScene(Cells,NaN,NaN,null,2.5,3.8);
		}
		
		private function setupFire():void
		{
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, _hitContainer[ "fire" + 0 ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var clip:MovieClip;
			var flame:Entity;
			for( var i:uint = 0; _hitContainer[ "fire" + i ] != null; i ++ )
			{
				clip = _hitContainer[ "fire" + i ];
				flame = _flameCreator.createFlame( this, clip, true );
			}
		}		
	}
}