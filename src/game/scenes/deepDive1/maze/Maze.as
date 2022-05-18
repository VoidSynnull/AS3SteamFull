package game.scenes.deepDive1.maze
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Cubic;
	import com.greensock.easing.Quad;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Sleep;
	import game.components.hit.Mover;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionTarget;
	import game.components.motion.RotateControl;
	import game.components.motion.Swarmer;
	import game.components.motion.TargetSpatial;
	import game.components.timeline.Timeline;
	import game.creators.scene.HitCreator;
	import game.data.display.BitmapWrapper;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MoverHitData;
	import game.data.sound.SoundModifier;
	import game.scene.template.CharacterGroup;
	import game.scenes.deepDive1.DeepDive1Events;
	import game.scenes.deepDive1.maze.components.FoodFish;
	import game.scenes.deepDive1.maze.components.MazeFish;
	import game.scenes.deepDive1.maze.components.UrchinHazards;
	import game.scenes.deepDive1.maze.systems.MazeFishSystem;
	import game.scenes.deepDive1.maze.systems.UrchinHazardsSystem;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive1.shared.components.Angler;
	import game.scenes.deepDive1.shared.components.Filmable;
	import game.scenes.deepDive1.shared.components.Geyser;
	import game.scenes.deepDive1.shared.components.SubCamera;
	import game.scenes.deepDive1.shared.creators.BubblesCreator;
	import game.scenes.deepDive1.shared.creators.GeyserCreator;
	import game.scenes.deepDive1.shared.data.BubbleGraphics;
	import game.scenes.deepDive1.shared.fishStates.Angler.AnglerEatIdleState;
	import game.scenes.deepDive1.shared.fishStates.Angler.AnglerEatState;
	import game.scenes.deepDive1.shared.fishStates.Angler.AnglerIdleState;
	import game.scenes.deepDive1.shared.fishStates.Angler.AnglerRetreatState;
	import game.scenes.deepDive1.shared.fishStates.Angler.AnglerSwimState;
	import game.scenes.deepDive1.shared.groups.SubGroup;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.systems.hit.HazardHitSystem;
	import game.systems.motion.SwarmSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Maze extends SubScene
	{
		public function Maze()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive1/maze/";
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
			_events = DeepDive1Events(events);
			
			super.loaded();
			
			//group.fishCreator.createOffscreenSpawn("fish", fishData, this, 10, .5, super.shellApi.camera.target);
			schoolFish();
			setupUrchins();
			setupJets();
			
			if(PlatformUtils.isDesktop && PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH)
			{
				setupBubbles();
			}
			
			setupZones();
			
			if(!super.shellApi.checkEvent(_events.ANGLER_CAPTURED)){
				super.playMessage("anglerScene");
			}
			
			if( ( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH ) )
			{
				super.addLight(super.shellApi.player, 400, .4, true, true, 0x000033, 0x000033);
			}
		}
		
		private function initSounds():void{
			
		}
		
		private function setupJets():void
		{
			var hitCreator:HitCreator = new HitCreator();
			var bubbleBitmapData:BitmapData = BitmapUtils.createBitmapData(_hitContainer["bubbleA"]);	// BitmapData or particles shared by all emitters
			
			for(var c:int = 0; c < 5; c++){
				
				//bitmap the base of the geyser
				var clip:MovieClip = this._hitContainer["jet"+c];
				if(PlatformUtils.isMobileOS)
				{
					this.convertContainer(clip);
				}
				
				var jetEntity:Entity = TimelineUtils.convertClip(clip, this);
				jetEntity.add(new Spatial(clip.x, clip.y));
				GeyserCreator.create(jetEntity, clip["bubblePt"], bubbleBitmapData, this, false, true);
				var geyser:Geyser = jetEntity.get(Geyser);
				geyser.turnOn();
				var timeline:Timeline = jetEntity.get(Timeline);
				
				timeline.handleLabel("turnOn", Command.create(turnOnGeyser, jetEntity), false);
				timeline.handleLabel("turnOff", Command.create(turnOffGeyser, jetEntity), false);
				
				var moverHitData:MoverHitData = new MoverHitData();
				
				switch(c){
					case 0:
						moverHitData.acceleration = new Point(1500, 0);
						break;
					case 1:
						moverHitData.acceleration = new Point(0, -1500);
						break;
					case 2:
						moverHitData.acceleration = new Point(0, -1500);
						break;
					case 3:
						moverHitData.acceleration = new Point(1500, 0);
						break;
					case 4:
						moverHitData.acceleration = new Point(-1500, 0);
						break;
				}
				
				
				
				var entity:Entity = new Entity();
				var audio:Audio = new Audio();
				audio.play(SoundManager.EFFECTS_PATH + "bubbles_02_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.MUSIC])
				entity.add(audio);
				entity.add(Spatial(jetEntity.get(Spatial)));
				entity.add(new AudioRange(480, .01, 1.3, Quad.easeIn));
				entity.add(new Id("soundSource"));
				super.addEntity(entity);
				
				//jetEntity.remove(Sleep);
				
				geyser.geyserHit = hitCreator.createHit(super._hitContainer["jetHit"+c], HitType.MOVER, moverHitData, this);
				geyser.mover = geyser.geyserHit.get(Mover);
				
				turnOffGeyser(jetEntity);
			}
		}
		
		
		private function turnOnGeyser($jetEntity:Entity):void
		{
			// if within view distance
			
			
			
			var geyser:Geyser = $jetEntity.get(Geyser);
			geyser.shutOn();
			//geyser.turnOn();
			if(geyser.mover){
				geyser.geyserHit.add(geyser.mover);
			}
		}
		
		private function turnOffGeyser($jetEntity:Entity):void
		{
			var geyser:Geyser = $jetEntity.get(Geyser);
			geyser.shutOff();
			//geyser.turnOff();
			if(geyser.mover){
				geyser.mover = geyser.geyserHit.get(Mover);
				geyser.geyserHit.remove(Mover);
			}
		}
		
		private function setupZones():void
		{
			var entity:Entity = super.getEntityById("zoneFeed");
			var zone:Zone = entity.get(Zone);
			zone.pointHit = true;
			
			zone.inside.add(handleZoneInside);
			zone.exitted.add(handleZoneExit);
			//zone.entered.add(handleZoneEntered);
		}
		
		private function setupUrchins():void
		{
			var group:SubGroup = super.getGroupById(SubGroup.GROUP_ID) as SubGroup;
			var hitCreator:HitCreator = new HitCreator();
			
			var hazardHitData:HazardHitData = new HazardHitData();
			hazardHitData.knockBackCoolDown = .75;
			hazardHitData.knockBackVelocity = new Point(200, 200);
			hazardHitData.velocityByHitAngle = true;
			
			_hazardManager = new Entity();
			
			var urchinHazards:UrchinHazards = new UrchinHazards();
			urchinHazards.player = super.shellApi.player;
			
			for(var c:int = 1; c <= 10; c++){
				
				super._hitContainer.setChildIndex(super._hitContainer["urchin"+c], super._hitContainer.numChildren - 1);
				
				var urchin:Entity = new Entity();
				
				var bmw:BitmapWrapper = this.convertToBitmapSprite(Sprite(super._hitContainer["urchin"+c]).getChildAt(0), super._hitContainer["urchin"+c], true);
				bmw.bitmap.smoothing = true;
				
				urchin.add(new Display(super._hitContainer["urchin"+c]));
				urchin.add(new Spatial());
				
				urchinHazards.allUrchinHazards.push(urchin);
				
				
				/**** make each urchin a hazard ****/
				hitCreator.makeHit(urchin, HitType.HAZARD, hazardHitData);
				/***********************************/
				
				super.addEntity(urchin);
			}
			
			_hazardManager.add(urchinHazards);
			super.addEntity(_hazardManager);
			
			super.addSystem(new HazardHitSystem(), SystemPriorities.checkCollisions);
			super.addSystem(new UrchinHazardsSystem(this), SystemPriorities.checkCollisions);
		}
		
		private function schoolFish():void
		{
			_swarmer = new Swarmer();
			_swarmer.alignWeight = 8;
			_swarmer.separationWeight = 7;
			_swarmer.cohesionWeight = 5;
			_swarmer.wanderWeight = 3;
			_swarmer.tetherWeight = 10;
			_swarmer.followWeight = 10;
			_swarmer.followTarget = new FollowTarget(shellApi.player.get(Spatial));
			
			var group:SubGroup = super.getGroupById(SubGroup.GROUP_ID) as SubGroup;
			
			var fishAsset:String = "scenes/deepDive1/shared/fish/schoolFish.swf";
			loadSchoolFish(6, 400, new Point(Spatial(super.shellApi.player.get(Spatial)).x,Spatial(super.shellApi.player.get(Spatial)).y), fishAsset, _swarmer, formatFish);
			
			_feedSwarmEntity = new Entity();
			_feedSwarmEntity.add(new Display(super._hitContainer["feedSwarmPoint"]));
			_feedSwarmEntity.add(new Spatial());
			
			_feedSwarmer = new Swarmer();
			_feedSwarmer.alignWeight = 8;
			_feedSwarmer.separationWeight = 7;
			_feedSwarmer.cohesionWeight = 5;
			_feedSwarmer.wanderWeight = 3;
			_feedSwarmer.tetherWeight = 4;
			_feedSwarmer.followWeight = 6;
			_feedSwarmer.followTarget = new FollowTarget(new Spatial(1750,1350));
		}
		
		private function formatFish(entities:Vector.<Entity>):void
		{
			_schoolFish = entities;
			this.addSystem(new SwarmSystem(), SystemPriorities.update);
			
			// position and remove swarm component (temporarily)
			
			
			// format fish
			for(var c:uint = 0; c < _schoolFish.length; c++)
			{
				var fish:Entity = _schoolFish[c];
				var spatial:Spatial = fish.get(Spatial);
				var motion:Motion = fish.get(Motion);
				var foodFish:FoodFish = new FoodFish();
				fish.add(foodFish);
				
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
				foodFish.returnToOrigin();
				
				// animate fish
				var tween:Tween = fish.get(Tween);
				var bitmap:Bitmap = Sprite(Display(fish.get(Display)).displayObject).getChildAt(0) as Bitmap;
				tween.to(bitmap, 0.3, {width:30, height:18, yoyo:true, repeat:-1});
				
				super._hitContainer["lfish"+(c+1)].visible = false;
			}
			
			// create mazeFish manager and systems
			_mazeFishManager = new Entity();
			
			var mazeFish:MazeFish = new MazeFish();
			mazeFish.mazeFish = _schoolFish;
			
			_mazeFishManager.add(mazeFish);
			
			this.addEntity(_mazeFishManager);
			this.addSystem(new MazeFishSystem(this));
			
			var clip:MovieClip = _hitContainer["angler"];
			DisplayUtils.moveToTop( clip );
			_angler = createAnglerFish(clip, clip["fish"]["pupil"]);
		}
		
		private function createAnglerFish(mc:MovieClip, pupilMC:MovieClip):Entity
		{
			if(PlatformUtils.isMobileOS)
			{
				this.convertContainer(mc);
			}
			
			var angler:Entity = EntityUtils.createSpatialEntity(this, mc, _hitContainer);
			TimelineUtils.convertAllClips(mc, angler, this);
			
			var charGroup:CharacterGroup = this.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addTimelineFSM(angler, true, new <Class>[AnglerIdleState, AnglerEatIdleState, AnglerSwimState, AnglerRetreatState, AnglerEatState], MovieclipState.STAND, false, true);
			
			// NOTE :: Not sure what this accomplishes? - Bard
			// NOTE :: Best to check with Scott as he wrote this (not sure what its for either) - Bart
			angler.get(MotionTarget).targetSpatial = shellApi.player.get(Spatial);
			angler.get(MotionTarget).useSpatial = true;
			angler.get(Motion).maxVelocity = new Point(200, 0);
			
			var anglerComp:Angler = new Angler(new Point(mc.x, mc.y), 50, 3, 10, 250);
			anglerComp.onEaten.add( onAnglerEaten );
			angler.add(anglerComp);
			angler.add(new Tween());
			
			// Add the pupil and set it up to rotate with the player
			var pupil:Entity = new Entity();
			pupil.add(new Spatial(pupilMC.x, pupilMC.y));
			pupil.add(new Display(pupilMC));
			pupil.add(new Id("playerEye"));
			
			pupil.add(new TargetSpatial(this.shellApi.inputEntity.get(Spatial)));
			var rotateControl:RotateControl = new RotateControl();
			rotateControl.origin = angler.get(Spatial);
			rotateControl.targetInLocal = true;
			rotateControl.ease = .3;
			pupil.add(rotateControl);
			
			EntityUtils.addParentChild(pupil, angler);
			this.addEntity(pupil);
			
			if(!super.shellApi.checkEvent(_events.ANGLER_CAPTURED)){
				super.makeFilmable( angler, onAnglerStateChange, 300, 6 );
				Interaction( angler.get(Interaction)).up.add( interactWithAngler );
			}
			
			// adjust subCamera
			
			var subCamera:SubCamera = super.shellApi.player.get(SubCamera);
			subCamera.angle = 120;
			subCamera.distanceMax = 500;
			subCamera.distanceMin = 0;
			return angler;
		}
		
		private function interactWithAngler($entity:Entity):void
		{
			if(hasFish() && Filmable(_angler.get(Filmable)).isFilmable){
				//SceneUtil.lockInput(this, true);
				super.playMessage("filmAngler");
				_filming = true;
			}
		}
		
		private function onAnglerEaten():void
		{
			super.shellApi.triggerEvent("chomp");
			if( !hasFish() ){
				FSMControl(_angler.get(FSMControl)).setState( "retreat" );
				if(!super.shellApi.checkEvent(_events.ANGLER_CAPTURED)){
					Filmable(_angler.get(Filmable)).isFilmable = false;
				}
				_anglerInteracted = false;
				checkFilm();
			} else {
				FSMControl(_angler.get(FSMControl)).setState( "eatIdle" );
			}
		}
		private function handleZoneEntered(zoneId:String, characterId:String):void{
			// swarm fish to feed point
			for each(var fish:Entity in _schoolFish)
			{
				if(FoodFish(fish.get(FoodFish)).state == "schooling")
				{
					//Swarmer(fish.get(Swarmer)).followTarget = new FollowTarget(_feedSwarmEntity.get(Spatial));
					fish.remove(Swarmer);
					fish.add(_feedSwarmer);
				}
			}
		}
		
		private function handleZoneInside(zoneId:String, characterId:String):void
		{	
			//if( _anglerInteracted && hasFish())
			Angler(_angler.get(Angler)).inZone = true;
			if(hasFish() && !_anglerHiding){
				// angler comes out to feed
				feedAngler();
				
				if(!super.shellApi.checkEvent(_events.ANGLER_CAPTURED)){
					var filmable:Filmable = _angler.get(Filmable);
					filmable.isFilmable = true;
				}
				
				//filmable.attemptFilm();
			} else if(!_anglerHiding && !anglerEating()) {
				hideAngler();
				_anglerHiding = true;
			}
		}
		
		private function handleZoneExit(zoneId:String, characterId:String):void{
			Angler(_angler.get(Angler)).inZone = false;
			if(!anglerEating()){
				Angler(_angler.get(Angler)).fishToEat = null;
			}
			if(_anglerHiding){
				_anglerHiding = false;
			}
			resetAngler();
			_filming = false;
		}
		
		private function onAnglerStateChange( entity:Entity ):void
		{
			var filmable:Filmable = entity.get(Filmable);
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
					_filmSuccessful = true;
					
					filmable.stateSignal.remove( onAnglerStateChange );
					
					super.playMessage("filmAnglerSuccess");
					//SceneUtil.lockInput(this, false);
					
					// complete event
					super.shellApi.completeEvent(_events.ANGLER_CAPTURED);
					super.logFish( _events.ANGLER );
					
					// remove filmable component and interaction
					_angler.remove(Filmable);
					Interaction( _angler.get(Interaction)).up.removeAll();
					
					break;
				}
				default:
				{
					trace( "invalid state: " + filmable.state );
					break;
				}
			}
		}
		
		public function pickupFish($fish:Entity):void
		{
			super.shellApi.triggerEvent("getFish");
			$fish.add(_swarmer);
			$fish.remove(Sleep);
			Motion($fish.get(Motion)).pause = false;
			FoodFish($fish.get(FoodFish)).state = "schooling";
			_numFishCollected++;
		}
		
		public function loseAFish():void{
			for each(var fish:Entity in _schoolFish)
			{
				if(FoodFish(fish.get(FoodFish)).state == "schooling")
				{
					FoodFish(fish.get(FoodFish)).returnToOrigin();
					break;
				}
			}
		}
		
		public function feedAngler():void
		{
			_fedAngler = true;
			for each(var fish:Entity in _schoolFish){
				if(FoodFish(fish.get(FoodFish)).state == "schooling"){
					
					if(!_filming && !super.shellApi.checkEvent(_events.ANGLER_CAPTURED)){
						super.playMessage("anglerOut");
					}
					
					if(!anglerEating())
					{
						// replace with new swarmer that goes to Angler
						
						if(Angler(_angler.get(Angler)).lightOn){
							
							// jiggle light
							var tween:Tween = _angler.get(Tween);
							var lightMC:MovieClip = Display(_angler.get(Display)).displayObject["fish"]["light"] as MovieClip;
							
							tween.to(lightMC, 1, {rotation:15, ease:Bounce.easeInOut, onComplete:resetLight, onCompleteParams:[lightMC]});
							
							fish.remove(Swarmer);
							
							swimToAngler(fish);
							
							_numFishCollected--;
							
							FoodFish(fish.get(FoodFish)).state = "eating";
						}
						
						Angler(_angler.get(Angler)).fishToEat = fish;
						
						break;
					}
				}
			}
			
			function resetLight($lightMC:MovieClip):void{
				tween.to($lightMC, 0.5, {rotation:0, ease:Back.easeInOut});
			}
		}
		
		private function swimToAngler($fish:Entity):void{
			// tween to target, then swarm to angler
			var tween:Tween = $fish.get(Tween);
			Spatial($fish.get(Spatial)).rotation = 0;
			
			var offset:Number
			var speed:Number;
			
			offset= 105;
			speed = 2.1;
			
			Motion($fish.get(Motion)).pause = true;
			tween.to($fish.get(Spatial), speed, {x:Spatial(_angler.get(Spatial)).x + offset, y:Spatial(_angler.get(Spatial)).y - 25, ease:Back.easeInOut, onComplete:swimToMouth, onCompleteParams:[$fish], onUpdate:faceAngler, onUpdateParams:[$fish]});
		}
		
		private function faceAngler($fish:Entity):void{
			// update rotation to face angler's lure
			var dX:Number = Spatial($fish.get(Spatial)).x - (Spatial(_angler.get(Spatial)).x + 60);
			var dY:Number = Spatial($fish.get(Spatial)).y - (Spatial(_angler.get(Spatial)).y - 65);
			var rotation:Number = Math.atan2(dY, dX) * (180/Math.PI);
			
			Spatial($fish.get(Spatial)).rotation = rotation;
			
		}
		
		private function swimToMouth($fish:Entity):void{
			FoodFish($fish.get(FoodFish)).goingIntoMouth = true;
			//var tween:Tween = $fish.get(Tween);
			//tween.to($fish.get(Spatial), 0.7, {x:Spatial(_angler.get(Spatial)).x + 50, y:Spatial(_angler.get(Spatial)).y, ease:Cubic.easeInOut});
			lurchAngler($fish);
		}
		
		private function hideAngler():void{
			
			if(!_playedHideMessage && !super.shellApi.checkEvent(_events.ANGLER_CAPTURED) && !_fedAngler){
				super.playMessage("anglerHides");
				_playedHideMessage = true;
			}
			
			/*
			var fish:Entity = TimelineUtils.getChildClip(_angler,"angler");
			var timeline:Timeline = fish.get(Timeline);
			timeline.gotoAndPlay("retreat");
			*/
			
			
			var tween:Tween = _angler.get(Tween);
			var fishMC:MovieClip = Display(_angler.get(Display)).displayObject["fish"] as MovieClip;
			
			//tween.killAll();
			//tween = new Tween();
			tween.to(fishMC, 2, {x:-114, y:7, ease:Cubic.easeInOut});
			
			
			_filming = false;

		}
		
		private function lurchAngler($fish:Entity):void{
			/*var fish:Entity = TimelineUtils.getChildClip(_angler,"angler");
			var timeline:Timeline = fish.get(Timeline);
			timeline.gotoAndPlay("lurch");*/
			
			var fishMC:MovieClip = Display(_angler.get(Display)).displayObject["fish"] as MovieClip;
			var tween:Tween = _angler.get(Tween);
			//tween.killAll();
			//tween = new Tween();
			tween.to(fishMC, 0.5, {x:71, y:-10, ease:Cubic.easeInOut, onComplete:resetAngler});
			
			FSMControl(_angler.get(FSMControl)).setState("eat");
		}
		
		private function resetAngler($delay:Number = 0):void{
			
			/*
			var fish:Entity = TimelineUtils.getChildClip(_angler,"angler");
			var timeline:Timeline = fish.get(Timeline);
			timeline.gotoAndPlay("reset");
			*/
			
			var fishMC:MovieClip = Display(_angler.get(Display)).displayObject["fish"] as MovieClip;
			
			
			var tween:Tween = _angler.get(Tween);
			//tween.killAll();
			//tween = new Tween();
			tween.to(fishMC, 2, {x:-14, y:7, ease:Cubic.easeInOut, delay:$delay});
			
		}
		
		public function getAllFish():void{
			for each(var fish:Entity in _schoolFish)
			{
				pickupFish(fish);
			}
		}
		
		public function hasFish():Boolean
		{	
			for each(var fish:Entity in _schoolFish)
			{
				if(FoodFish(fish.get(FoodFish)).state == "schooling")
				{
					return true;
				}
			}
			
			return false;
		}
		
		public function checkFilm():void{
			//check film
			if(!_filmSuccessful && !super.shellApi.checkEvent(_events.ANGLER_CAPTURED)){
				super.playMessage("filmAnglerFail");
				
			} 
			
			//SceneUtil.lockInput(this, false);
			
			//SceneUtil.lockInput(this, false);
		}
		
		public function anglerEating():Boolean
		{
			for each(var fish:Entity in _schoolFish)
			{
				if(FoodFish(fish.get(FoodFish)).state == "eating")
				{
					return true;
				}
			}
			
			return false;
		}
		
		public function restoreControls():void{
			SceneUtil.lockInput(this, false);
			CharUtils.lockControls(this.shellApi.player, false, false);
		}
		
		private function setupBubbles():void{
			/**
			 * Some of this code is temporary until I have a firmer setup method - Bart
			 */
			BubbleGraphics.BUBBLE_1 = super._hitContainer["bubble1"]; // get graphic from scene (TEMP)
			BubbleGraphics.BUBBLE_2 = super._hitContainer["bubble2"]; // get graphic from scene (TEMP)
			BubbleGraphics.BUBBLE_3 = super._hitContainer["bubble3"]; // get graphic from scene (TEMP)
			
			var bubbleCreator:BubblesCreator = new BubblesCreator(this, super.shellApi.player, super._hitContainer["bubblesHolder"]); // init creator
			_bubbles = bubbleCreator.CreateBubbleField(60, super._hitContainer.width, super._hitContainer.height, false, -100); // create bubble field
		}
		
		private var _bubbles:Entity; // nape bubbles
		
		private var _schoolFish:Vector.<Entity> = new Vector.<Entity>;
		private var _swarmer:Swarmer;
		private var _feedSwarmer:Swarmer;
		
		private var _feedSwarmEntity:Entity;
		
		private var _mazeFishManager:Entity;
		private var _angler:Entity;
		private var _anglerInteracted:Boolean = false;
		private var _anglerHiding:Boolean = false;
		
		private var _feedGuide:Entity;
		
		private var _hazardManager:Entity;
		private var _filming:Boolean = false;
		
		private var _playedHideMessage:Boolean = false;
		
		private var _filmSuccessful:Boolean = false;
		
		private var _mazeUrchinManager:Entity;
		private var _numFishCollected:int;
		private var _fedAngler:Boolean;
	}
}