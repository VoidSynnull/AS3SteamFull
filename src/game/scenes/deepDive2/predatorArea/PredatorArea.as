package game.scenes.deepDive2.predatorArea
{
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	import com.poptropica.AppConfig;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;
	import game.components.entity.Sleep;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Wall;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Swarmer;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitDataComponent;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.RadialHitData;
	import game.data.sound.SoundModifier;
	import game.scenes.deepDive1.maze.components.FoodFish;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive1.shared.components.Filmable;
	import game.scenes.deepDive1.shared.components.SubCamera;
	import game.scenes.deepDive1.shared.groups.SubGroup;
	import game.scenes.deepDive2.DeepDive2Events;
	import game.scenes.deepDive2.predatorArea.components.FishSwim;
	import game.scenes.deepDive2.predatorArea.components.Shark;
	import game.scenes.deepDive2.predatorArea.nodes.SharkNode;
	import game.scenes.deepDive2.predatorArea.particles.GlassParticles;
	import game.scenes.deepDive2.predatorArea.sharkStates.SharkAttackState;
	import game.scenes.deepDive2.predatorArea.sharkStates.SharkChewState;
	import game.scenes.deepDive2.predatorArea.sharkStates.SharkIdleState;
	import game.scenes.deepDive2.predatorArea.sharkStates.SharkSwimState;
	import game.scenes.deepDive2.predatorArea.systems.FishSwimSystem;
	import game.scenes.deepDive2.shared.components.Breakable;
	import game.scenes.deepDive2.shared.systems.BreakableSystem;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.scenes.myth.shared.systems.ElectrifySystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.SwarmSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.util.Utils;
	
	public class PredatorArea extends SubScene
	{
		
		public function PredatorArea()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive2/predatorArea/";
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
			_predatorAreaEvents = DeepDive2Events(events);
			super.loaded();
			
			super.shellApi.eventTriggered.add( eventTriggers );
			
			setupShark();
			setupHazards();
			setupZones();
			setupGlass();
			setupPuzzlePieces();
			schoolFish();
			setupMachine();
			setupParticles();
			setupInteractables();
			
			electrifyEffect = new Entity;
			electrifySystem = addSystem( new ElectrifySystem(2), SystemPriorities.render );
			setupElectrifyEffect(electrifyEffect, "electrifySub");
			
			super.addLight(super.shellApi.player, 400, .6, true, false, 0x000033, 0x000033);
			
			if(!super.shellApi.checkEvent(_predatorAreaEvents.TRAPPED_SHARK)){
				SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, playPredMsg));
			}
		}
		
		private function setupPuzzlePieces():void
		{
			setupPuzzlePiece(super._hitContainer["puzzlePiece2"], _predatorAreaEvents.GOT_PUZZLE_PIECE_+2);
			setupPuzzlePiece(super._hitContainer["puzzlePiece6"], _predatorAreaEvents.GOT_PUZZLE_PIECE_+6);
		}
		
		private function setupInteractables():void
		{
			
			_glyph = EntityUtils.createSpatialEntity(this, _hitContainer["glyph"]);
			_glyph.add(new Id("glyph_5"));
			var isCaptured:Boolean = super.shellApi.checkEvent(_predatorAreaEvents.GLYPH_ + 5);
			makeFilmable(_glyph, handleFilmed, 300, 3, true, true, isCaptured);
			
			_glyph2 = EntityUtils.createSpatialEntity(this, _hitContainer["glyph2"]);
			_glyph2.add(new Id("glyph_3"));
			isCaptured = super.shellApi.checkEvent(_predatorAreaEvents.GLYPH_ + 3);
			makeFilmable(_glyph2, handleFilmed, 300, 3, true, true, isCaptured);
			
			var subCamera:SubCamera = super.shellApi.player.get(SubCamera);
			subCamera.angle = 120;
			subCamera.distanceMax = 500;
			subCamera.distanceMin = 0;
		}
		
		private function handleFilmed(glyph:Entity):void
		{
			var id:String = glyph.get(Id).id;
			var filmable:Filmable = glyph.get(Filmable);
			
			if(id == "glyph_5"){
				handleFilmStates(glyph.get(Filmable), _predatorAreaEvents.GLYPH_ + 5);
			} else if(id == "glyph_3"){
				handleFilmStates(glyph.get(Filmable), _predatorAreaEvents.GLYPH_ + 3);
			}
		}
		
		private function handleFilmStates( filmable:Filmable, sucessEvent:String):void
		{
			var camMessage:String = "alreadyFilmed";
			if(!shellApi.checkEvent(sucessEvent))
			{
				switch( filmable.state )
				{
					case filmable.FILMING_OUT_OF_RANGE:
					{
						camMessage = "filmTooFar";
						break;
					}
					case filmable.FILMING_BLOCK:
					{
						camMessage = "failedFilm";
						break;
					}
					case filmable.FILMING_START:
					{
						camMessage = "startFilm";
						break;
					}
					case filmable.FILMING_STOP:
					{
						camMessage = "failedFilm";
						break;
					}
					case filmable.FILMING_COMPLETE:
					{
						camMessage = "sucessFilm";;
						logFish( sucessEvent );
						break;
					}
					default:
					{
						trace( "invalid state: " + filmable.state );
						break;
					}
				}
			}
			
			playMessage(camMessage);
		}
		
		private function filmed($entity:Entity):void{
			var filmable:Filmable = $entity.get(Filmable);
			switch( filmable.state )
			{
				case filmable.FILMING_OUT_OF_RANGE:
				{
					// need to get closer
					//super.playMessage( "tooFar" );
					break;
				}
				case filmable.FILMING_BLOCK:
				{
					// explain why
					//super.playMessage( "notFilmable" );
					break;
				}
				case filmable.FILMING_START:
				{
					// listen for complete
					//super.playMessage( "filmStart" );
					break;
				}
				case filmable.FILMING_STOP:
				{
					// listen for complete
					//super.playMessage( "filmStart" );
					break;
				}
				case filmable.FILMING_COMPLETE:
				{
					if($entity == _glyph){
						super.logFish(_predatorAreaEvents.GLYPH_ + 5);
						_glyph.remove(Filmable);
					} else {
						super.logFish(_predatorAreaEvents.GLYPH_ + 3);
						_glyph2.remove(Filmable);
					}
					break;
				}
				default:
				{
					trace( "invalid state: " + filmable.state );
					break;
				}
			}
		}
		
		private function playPredMsg():void{
			super.playMessage("predatorScene");
		}
		
		private function setupParticles():void
		{
			_shardsEmitter = new GlassParticles();
			_shardsEmitter.init(BitmapUtils.createBitmapData(_hitContainer["shard2"]));
			_shardsEntity = EmitterCreator.create(this, _hitContainer, _shardsEmitter, 0, 0);
		}
		
		private function setupHazards():void
		{
			var hazardHitData:HazardHitData = new HazardHitData();
			hazardHitData.knockBackCoolDown = 5;
			hazardHitData.knockBackVelocity = new Point(400, 400);
			hazardHitData.velocityByHitAngle = true;
			
			_biteHazard = new Entity();
			_biteHazard.add(new Display(this._hitContainer["biteHazard"]));
			_biteHazard.add(new Spatial());
			
			this.addEntity(_biteHazard);
			
			var hitCreator:HitCreator = new HitCreator();
			hitCreator.makeHit(_biteHazard, HitType.HAZARD, hazardHitData, this);
		}
		
		private function setupMachine():void
		{
			convertContainer(this._hitContainer["sharkContainer"]);
			
			BitmapUtils.convertContainer(this._hitContainer["containerGlass"]);
			
			_machine = TimelineUtils.convertClip(this._hitContainer["containerGlass"], this, null, null, false);
			
			_powerTube = EntityUtils.createSpatialEntity(this,_hitContainer["powerTube"]["orange"]);
			_powerTube.add(new Id("tankWire"));
			_powerTube.get(Display).visible = false;
			
			if(!super.shellApi.checkEvent(_predatorAreaEvents.TRAPPED_SHARK)){
				var entity:Entity = super.getEntityById("zoneMachine");
				var zone:Zone = entity.get(Zone);
				zone.pointHit = true;
				
				zone.entered.add(handleMachineEntered);
			} else {
				// close glass
				Timeline(_machine.get(Timeline)).gotoAndStop("closed");
				turnOnTankLine();
				//Timeline(_powerTube.get(Timeline)).gotoAndStop("on");
			}
		}
		
		private function turnOnTankLine():void{
			var disp:Display = _powerTube.get(Display);
			disp.visible = true;
			disp.alpha = 0;
			fadeIn(_powerTube);
		}
		
		private function fadeIn(ent:Entity):void
		{
			if(ent.get(Display).visible){
				TweenUtils.globalTo(this, ent.get(Display), 0.9, {alpha:1.0 ,onComplete:fadeOut, onCompleteParams:[ent]}, "pipeGlow",0.1);
			}
		}
		
		private function fadeOut(ent:Entity):void
		{
			if(ent.get(Display).visible){
				TweenUtils.globalTo(this, ent.get(Display), 0.9, {alpha:0.7 ,onComplete:fadeIn, onCompleteParams:[ent]}, "pipeGlow",0.1);
			}
		}
		
		
		private function handleMachineEntered(zoneId:String, characterid:String):void{
			if(_sharkRevealed && !_overrideShark && !_playerHit){
				_inMachine = true;
				
				// lock controls
				//CharUtils.lockControls(super.shellApi.player, true);
				SceneUtil.lockInput(this, true);
				
				var tween:Tween = new Tween();
				var spatial:Spatial = super.shellApi.player.get(Spatial);
				super.shellApi.player.add(tween);
				
				tween.to(spatial, 1, {x:800,y:3500, onComplete:faceRight});
				
				// override shark behavior
				_overrideShark = true;
				
				// move camera to shark
				SceneUtil.setCameraTarget(this, _shark);
				
				// have shark charge at the point inside machine
				var shark:Shark = _shark.get(Shark)
				shark.targetEntity = null;
				
				shark.targetEntity = super.getEntityById("zoneMachine");
				
				//shark.attackPoint = new Point(1170,3535);
				FSMControl(_shark.get(FSMControl)).setState("attack");
				
				super.shellApi.triggerEvent("sharkCharge");
				
				// once shark "chomps" -- close glass and shut off shark
				shark.bite.addOnce(insideMachine);
			}
		}
		
		private function faceRight():void{
			CharUtils.setDirection(super.shellApi.player, true);
		}
		
		private function insideMachine():void
		{
			super.shellApi.triggerEvent("sharkTrapped");
			
			Shark(_shark.get(Shark)).attackPoint = null;
			Shark(_shark.get(Shark)).targetEntity = null;
			FSMControl(_shark.get(FSMControl)).setState("idle");
			
			// correct orientation of shark
			Spatial(_shark.get(Spatial)).scaleY = -1;
			Spatial(_shark.get(Spatial)).rotation = -182;
			
			// close machine glass
			Timeline(_machine.get(Timeline)).gotoAndPlay("close");
			
			// turn on power tube
			turnOnTankLine();
			//Timeline(_powerTube.get(Timeline)).gotoAndStop("on");
			
			// center shark
			Tween(_shark.get(Tween)).to(_shark.get(Spatial), 1, {x:1145, y:3535});
			
			// release controls and camera
			releaseToPlayer()
			resetCamera();
			
			// turn on sound
			
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "alien_gen_uw.mp3", true, [SoundModifier.POSITION])
			entity.add(audio);
			entity.add(new Spatial(Spatial(_shark.get(Spatial)).x, Spatial(_shark.get(Spatial)).y));
			entity.add(new AudioRange(950, 1.4, 2, Quad.easeIn));
			entity.add(new Id("soundSource1"));
			this.addEntity(entity);
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, playSharkMsg));
			
			// correct depths
			
			// complete event
			super.shellApi.triggerEvent(_predatorAreaEvents.TRAPPED_SHARK, true);
		}
		
		private function playSharkMsg():void{
			super.playMessage("trapShark", playSharkMsg2);
		}
		
		private function playSharkMsg2():void{
			super.playMessage("trapShark2", playSharkMsg3);
		}
		
		private function playSharkMsg3():void{
			super.playerSay("trapShark3");
		}
		
		private function setupGlass():void
		{
			var hitCreator:HitCreator = new HitCreator();
			var hitData:HitDataComponent = new HitDataComponent();
			
			var radialData:RadialHitData = new RadialHitData();
			radialData.rebound = 3;
			
			for(var c:int = 1; c <= 9; c++)
			{
				var glassEntity:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["glass"+c], this._hitContainer);
				BitmapTimelineCreator.convertToBitmapTimeline(glassEntity);
				glassEntity.add(new Breakable());
				glassEntity.add(new MovieClipHit("glass"+c,"ship"));
				hitCreator.makeHit(glassEntity, HitType.WALL, hitData, this);
				//hitCreator.makeHit(glassEntity, HitType.RADIAL, radialData, this);
				
				Breakable(glassEntity.get(Breakable)).wallHit.add(hitGlass);
			}
			
			super.addSystem(new BreakableSystem(), SystemPriorities.resolveCollisions);
			
			// shark glass
			convertContainer(this._hitContainer["glassS"]);
			_sharkGlass = EntityUtils.createSpatialEntity(this, this._hitContainer["glassS"], this._hitContainer);
			_sharkGlass.add(new Breakable());
			BitmapTimelineCreator.convertToBitmapTimeline(_sharkGlass);
			hitCreator.makeHit(_sharkGlass, HitType.WALL, hitData, this);
			
			if(super.shellApi.checkEvent(_predatorAreaEvents.TRAPPED_SHARK)){
				_sharkGlass.add(new MovieClipHit("glassS","ship"));
				Breakable(_sharkGlass.get(Breakable)).wallHit.add(hitGlass);
			}
			
		}
		
		private function hitGlass($entity:Entity):void{
			var particleSpatial:Spatial = _shardsEntity.get(Spatial);
			var glassSpatial:Spatial = $entity.get(Spatial);
			
			particleSpatial.x = glassSpatial.x;
			particleSpatial.y = glassSpatial.y;
			
			_shardsEmitter.spark();
			
			if(Breakable($entity.get(Breakable)).strength > 1){
				super.shellApi.triggerEvent("glassHit");
			} else {
				super.shellApi.triggerEvent("glassBreak");
			}
			
			// rebound player	
			var motion:Motion = super.shellApi.player.get(Motion);
			motion.velocity.x *= -1;
		}
		
		private function schoolFish():void
		{
			_swarmer = new Swarmer();
			_swarmer.alignWeight = 7;
			_swarmer.separationWeight = 6;
			_swarmer.cohesionWeight = 6;
			_swarmer.wanderWeight =2;
			_swarmer.tetherWeight = 6;
			_swarmer.followWeight = 40;
			
			_swarmer.wanderDist = 50;
			_swarmer.wanderMax = 30;
			
			_swarmer.followTarget = new FollowTarget(shellApi.player.get(Spatial));
			
			var group:SubGroup = super.getGroupById(SubGroup.GROUP_ID) as SubGroup;
			
			var fishAsset:String = "scenes/deepDive2/predatorArea/schoolFish.swf";
			loadSchoolFish(6, 640, new Point(Spatial(super.shellApi.player.get(Spatial)).x,Spatial(super.shellApi.player.get(Spatial)).y), fishAsset, _swarmer, formatFish);
		}
		
		private function formatFish(entities:Vector.<Entity>):void
		{
			
			this.addSystem(new SwarmSystem(), SystemPriorities.update);
			
			// position and remove swarm component (temporarily)
			
			// create scared fish
			_scaredFish = TimelineUtils.convertClip(this._hitContainer["scaredFish"], this, null, null, false);
			
			// format fish
			for(var c:uint = 0; c < entities.length; c++)
			{
				var fish:Entity = entities[c];
				var spatial:Spatial = fish.get(Spatial);
				var motion:Motion = fish.get(Motion);
				var foodFish:FoodFish = new FoodFish();
				fish.add(new Id("lfish"+(c+1)));
				fish.add(foodFish);
				fish.add(new FishSwim());
				
				fish.remove(Swarmer);
				
				motion.velocity = new Point(0,0);
				
				// have them mull around in their space
				
				spatial.x = super._hitContainer["lfish"+(c+1)].x;
				spatial.y = super._hitContainer["lfish"+(c+1)].y;
				
				// store orig references
				foodFish.entity = fish;
				foodFish.originPoint = new Point(spatial.x, spatial.y);
				foodFish.originRotation = spatial.rotation;
				foodFish.originSpatial = new Spatial(super._hitContainer["lfish"+(c+1)].x, super._hitContainer["lfish"+(c+1)].y);
				foodFish.swarmer = _swarmer;
				//foodFish.returnToOrigin();
				
				// animate fish
				var tween:Tween = fish.get(Tween);
				var bitmap:Bitmap = Sprite(Display(fish.get(Display)).displayObject).getChildAt(0) as Bitmap;
				tween.to(Display(fish.get(Display)).displayObject, 0, {tint:0x294758});
				//tween.to(bitmap, 0.3, {width:30, height:18, yoyo:true, repeat:-1});
				
				if(c+1 == 6){
					_hiddenFishDisplay = fish.get(Display);
					_hiddenFishDisplay.visible = false;
				}
				
				super._hitContainer["lfish"+(c+1)].visible = false;
				
				tween.to(spatial, 1.4, {y:spatial.y - 7, yoyo:true, repeat:-1, ease:Sine.easeInOut});
			}
			
			// add FishSwarm system
			super.addSystem(new FishSwimSystem(), SystemPriorities.animate);
		}
		
		public function pickupFish($fish:Entity):void
		{
			if($fish != null){
				if(FoodFish($fish.get(FoodFish)).state != "schooling"){
					Shark(_shark.get(Shark)).foodFish.push($fish);
					super.shellApi.triggerEvent("getFish");
					
					$fish.add(new Tween());
					$fish.add(_swarmer);
					$fish.remove(Sleep);
					
					$fish.add(new Tween());
					
					var tween:Tween = $fish.get(Tween);
					tween.to(Display($fish.get(Display)).displayObject, 0, {tint:null});
					
					var bitmap:Bitmap = Sprite(Display($fish.get(Display)).displayObject).getChildAt(0) as Bitmap;
					tween.to(bitmap, 0.2, {width:34, yoyo:true, repeat:-1});
					
					Motion($fish.get(Motion)).pause = false;
					FoodFish($fish.get(FoodFish)).state = "schooling";
					
					if(_numFishCollected == 0 && !super.shellApi.checkEvent(_predatorAreaEvents.TRAPPED_SHARK)){
						super.playMessage("getFish");
					}
					
					_numFishCollected++;
				}
			}
		}
		
		private function setupShark():void
		{
			if(PlatformUtils.isMobileOS)
			{
				this.convertContainer(_hitContainer["shark"]);
			}
			
			if(PlatformUtils.isMobileOS || _events2.TRAPPED_SHARK) convertContainer(_hitContainer["shark"], 1);

			// create shark entity
			_shark = EntityUtils.createSpatialEntity(this, _hitContainer["shark"], _hitContainer);
			TimelineUtils.convertAllClips(_hitContainer["shark"], _shark, this, false);
			_shark.add(new Tween());
			_shark.add(new Shark());
			_shark.add(new Motion());
			
			
			
			// setup FSM for shark
			var stateCreator:FSMStateCreator = new FSMStateCreator();
			
			var fsmControl:FSMControl = new FSMControl(super.shellApi);
			_shark.add(fsmControl);
			_shark.add(new FSMMaster());
			
			stateCreator.createStateSet(new <Class>[SharkIdleState, SharkSwimState, SharkAttackState, SharkChewState], _shark, SharkNode);
			
			fsmControl.setState("idle");
			
			var spatial:Spatial = _shark.get(Spatial);
			
			if(super.shellApi.checkEvent(_predatorAreaEvents.TRAPPED_SHARK)){
				spatial.x = 1145;
				spatial.y = 3535;
				spatial.scaleY = -1;
				spatial.rotation = -182;
				
				var entity:Entity = new Entity();
				var audio:Audio = new Audio();
				audio.play(SoundManager.EFFECTS_PATH + "alien_gen_uw.mp3", true, [SoundModifier.POSITION])
				entity.add(audio);
				entity.add(new Spatial(Spatial(_shark.get(Spatial)).x, Spatial(_shark.get(Spatial)).y));
				entity.add(new AudioRange(950, 1.4, 2, Quad.easeIn));
				entity.add(new Id("soundSource1"));
				this.addEntity(entity);
				
			} else {
				// dim shark
				Tween(_shark.get(Tween)).to(Display(_shark.get(Display)).displayObject, 0, {tint:0x294758});
			}
			
			var tween:Tween = _shark.get(Tween);
			
			tween.to(spatial, 1.4, {y:spatial.y - 7, yoyo:true, repeat:-1, ease:Sine.easeInOut});
		}
		
		public function revealShark():void{
			if(!_sharkRevealed){
				// dramatic reveal of shark
				// brighten shark
				
				_shark.add(new Tween());
				
				Tween(_shark.get(Tween)).to(Display(_shark.get(Display)).displayObject, 1, {tint:null});
				
				// play scary reveal sound and music
				shellApi.triggerEvent("revealShark");
				
				// pan to shark
				SceneUtil.lockInput(this);
				//CharUtils.lockControls(this.shellApi.player);
				SceneUtil.setCameraTarget(this, _shark);
				SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, resetCamera));
				
				_sharkRevealed = true;
				
				SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, sharkAttackGlass));
			}
		}
		
		private function sharkAttackGlass():void{
			// shark charges for glass threateningly cracking the glass initially, eventually busting through and chasing the player
			var shark:Shark = _shark.get(Shark);
			shark.bite.addOnce(biteGlass);
			shark.attackPoint = new Point(1315, 906);
		}
		
		private function biteGlass():void{
			var breakable:Breakable = _sharkGlass.get(Breakable);
			breakable.strength--;
			var timeline:Timeline = _sharkGlass.get(Timeline);
			timeline.nextFrame();
			timeline.gotoAndStop(timeline.nextIndex);
			
			if(breakable.strength <= 0){
				// remove wall component
				_sharkGlass.remove(Wall);
				// persue player
				if(Shark(_shark.get(Shark)).foodFish.length <= 0){
					Shark(_shark.get(Shark)).targetEntity = super.shellApi.player;
				} else {
					Shark(_shark.get(Shark)).targetEntity = Shark(_shark.get(Shark)).foodFish.pop();
				}
				SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, sharkAttack));
				
				super.shellApi.triggerEvent("glassBreak");
				
			} else {
				// attack glass again
				
				var motion:Motion = _shark.get(Motion);
				motion.acceleration.x = -100;
				SceneUtil.addTimedEvent( this, new TimedEvent( 1.7, 1, sharkAttackGlass));
				
				super.shellApi.triggerEvent("glassCrush");
				
				cameraShake();
				
			}
			
			// emit particles
			
			var glassSpatial:Spatial = _sharkGlass.get(Spatial);
			var particleSpatial:Spatial = _shardsEntity.get(Spatial);
			
			particleSpatial.x = glassSpatial.x;
			particleSpatial.y =  glassSpatial.y;
			
			_shardsEmitter.spark();
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, stopCamShake));
		}
		
		private function sharkAttack():void{
			if(!_overrideShark){
				super.shellApi.triggerEvent("sharkCharge");
				FSMControl(_shark.get(FSMControl)).setState("attack");
				if(PlatformUtils.isMobileOS){
					SceneUtil.addTimedEvent( this, new TimedEvent( 4, 1, sharkAttack));
				} else {
					SceneUtil.addTimedEvent( this, new TimedEvent( 3.4, 1, sharkAttack));
				}
				if(Shark(_shark.get(Shark)).targetEntity == super.shellApi.player){
					Shark(_shark.get(Shark)).bite.addOnce(hitPlayer);
				} else {
					Shark(_shark.get(Shark)).bite.addOnce(hitFish);
				}
			}
		}
		
		private function hitFish():void{
			shellApi.triggerEvent("sharkChomp");
		}
		
		private function hitPlayer():void{
			if(!_inMachine){
				_playerHit = true;
				
				// create biteHazard right in path of shark bite
				var sharkSpatial:Spatial = _shark.get(Spatial);
				var playerSpatial:Spatial = super.shellApi.player.get(Spatial);
				
				var dY:Number = sharkSpatial.y - playerSpatial.y;
				var dX:Number = sharkSpatial.x - playerSpatial.x;
				
				var angle:Number = Math.atan2(dY,dX);
				
				var hX:Number = playerSpatial.x + (10*Math.cos(angle));
				var hY:Number = playerSpatial.y + (10*Math.sin(angle));
				
				// update hazard coordinates
				var hazardSpatial:Spatial = _biteHazard.get(Spatial);
				hazardSpatial.x = hX;
				hazardSpatial.y = hY;
				
				//CharUtils.lockControls(super.shellApi.player, true);
				//shellApi.player.remove(MotionControl);
				
				frySub();
				//shellApi.player.get(Tween).to(shellApi.player.get(Spatial), 10, { onUpdate:shakeSub });
				
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, showPopup, true));
				
				shellApi.triggerEvent("sharkChomp");
			}
		}
		
		public function shakeSub():void {
			shellApi.player.get(SpatialAddition).rotation = Utils.randNumInRange(5, 8);
		}
		
		private function setupElectrifyEffect(e:Entity, clipName:String):void {
			
			var electrify:ElectrifyComponent;
			var display:Display;
			var number:int;
			var sprite:Sprite;
			var startX:Number;
			var startY:Number;
			
			electrify = new ElectrifyComponent();
			electrify.on = false;
			
			var clip:MovieClip = _hitContainer[clipName];
			
			var foregroundId:String = ( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGHEST ) ? "foreground" : "foreground_mobile";
			var container:DisplayObjectContainer = super.getEntityById(foregroundId).get(Display).displayObject;
			container.addChild(clip);
			
			e.add(new Spatial(clip.x, clip.y));
			e.add(new Display(clip));
			
			e.add( electrify );
			
			super.addEntity(e);
			
			display = e.get( Display );
			
			for( number = 0; number < 10; number ++ )
			{
				sprite = new Sprite();
				startX = Math.random() * 60 - 60;
				startY = Math.random() * 60 - 60;				
				sprite.graphics.lineStyle( 1, 0xFFFFFF );
				sprite.graphics.moveTo( startX, startY );
				electrify.sparks.push( sprite );
				electrify.lastX.push( startX );
				electrify.lastY.push( startY );
				electrify.childNum.push( display.displayObject.numChildren );
				display.displayObject.addChildAt( sprite, display.displayObject.numChildren );
				if(!AppConfig.mobile)
				{
					sprite.filters = new Array( colorFill);
				}
			}	
			
			if(!AppConfig.mobile)
			{
				e.get(Display).displayObject.filters = new Array(  colorGlow );
			}
		}
		
		private function frySub():void {
			var follow:FollowTarget = new FollowTarget(Spatial(shellApi.player.get(Spatial)));
			follow.properties = new <String>["x","y","rotation"];
			electrifyEffect.add(follow);
			electrifyEffect.get(ElectrifyComponent).on = true;
		}
		
		private function resetCamera():void{
			SceneUtil.setCameraTarget(this, this.shellApi.player);
			releaseToPlayer();
		}
		
		private function releaseToPlayer():void{
			SceneUtil.lockInput(this, false);
			//CharUtils.lockControls(this.shellApi.player, false);
		}
		
		private function setupZones():void
		{
			
			if(!super.shellApi.checkEvent(_predatorAreaEvents.TRAPPED_SHARK)){
				var entity:Entity = super.getEntityById("zoneShark");
				var zone:Zone = entity.get(Zone);
				zone.pointHit = true;
				
				//zone.inside.add(handleZoneInside);
				zone.entered.add(handleZoneEntered);
			}
			
			for(var c:uint = 1; c <= 6; c++){
				entity = super.getEntityById("zoneFish"+c);
				zone = entity.get(Zone);
				zone.pointHit = true;
				
				zone.entered.add(handleZoneEntered);
			}
			
			entity = super.getEntityById("zoneScared");
			zone = entity.get(Zone);
			zone.pointHit = true;
			
			zone.entered.add(scareFish);
		}
		
		private function scareFish(zoneId:String, characterId:String):void{
			var timeline:Timeline = _scaredFish.get(Timeline);
			timeline.handleLabel("hidden", fishHidden, true);
			timeline.play();
			
			this.removeEntity(super.getEntityById("zoneScared"));
		}
		
		private function fishHidden():void{
			_hiddenFishDisplay.visible = true;
		}
		
		private function handleZoneEntered(zoneId:String, characterId:String):void
		{
			if(zoneId == "zoneShark"){
				revealShark();
			} else {
				pickupFish(this.getEntityById("lfish"+zoneId.substr(8)));
				
				// show swarmer component properties
				
			}
		}
		
		public function zoomOut():void{
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			camera.scaleTarget = .5;
		}
		
		public function resetZoom():void{
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			camera.scaleTarget = 1;
		}
		
		private function showPopup():void {
			SceneUtil.lockInput(this, false);
			var popup:SharkPopup = super.addChildGroup( new SharkPopup( super.overlayContainer )) as SharkPopup;
			popup.id = "sharkPopup";
		}
		
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if( event == "triggerFadeOut" ){
				SceneUtil.lockInput( this );
				fadeToBlack();
			}
		}
		
		private function fadeToBlack():void
		{
			shellApi.loadScene(PredatorArea , 350, 3900, null, NaN, 1 );
		}
		
		private function cameraShake():void
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var waveMotion:WaveMotion = new WaveMotion();
			
			var waveMotionData:WaveMotionData = new WaveMotionData();
			waveMotionData.property = "y";
			waveMotionData.magnitude = 2;
			waveMotionData.rate = .5;
			waveMotionData.radians = 90;
			waveMotion.data.push(waveMotionData);
			cameraEntity.add(waveMotion);
			cameraEntity.add(new SpatialAddition());
			
			if(!super.hasSystem(WaveMotionSystem))
			{
				super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			}
		}
		
		private function stopCamShake():void{
			var cameraEntity:Entity = super.getEntityById("camera");
			var waveMotion:WaveMotion = cameraEntity.get(WaveMotion);
			
			cameraEntity.remove(WaveMotion);
			var spatialAddition:SpatialAddition = cameraEntity.get(SpatialAddition);
			spatialAddition.y = 0;
		}
		
		private var electrifyEffect:Entity;
		private var electrifySystem:System;
		public var colorFill:GlowFilter = new GlowFilter( 0xFF0000, 1, 20, 20, 10, 1, true );
		public var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1, 1 );	
		
		private var _shardsEmitter:GlassParticles;
		private var _shardsEntity:Entity;
		
		private var _glyph:Entity;
		private var _glyph2:Entity;
		
		private var _sharkRevealed:Boolean = false;
		private var _shark:Entity;
		private var _sharkGlass:Entity;
		
		private var _overrideShark:Boolean = false;
		
		private var _container:Entity;
		private var _machine:Entity;
		private var _powerTube:Entity;
		
		private var _predatorAreaEvents:DeepDive2Events;
		//private var _bitmaps:Object;
		
		private var _swarmer:Swarmer;
		private var _mazeFishManager:Entity;
		private var _numFishCollected:int;
		private var _biteHazard:Entity;
		
		private var _scaredFish:Entity;
		private var _hiddenFishDisplay:Display;
		
		private var _inMachine:Boolean = false;
		private var _playerHit:Boolean = false;
		
		private var _gotFish:Boolean = false;
		
		
	}
}