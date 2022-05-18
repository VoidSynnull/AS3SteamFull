package game.scenes.carnival.mirrorMaze{
	import com.greensock.easing.Sine;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.entity.Dialog;
	import game.components.hit.Platform;
	import game.components.render.Reflection;
	import game.components.render.Reflective;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Chicken;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Throw;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MovingHitData;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.CarnivalEvents;
	import game.scenes.carnival.mirrorMaze.particles.MirrorBreak;
	import game.scenes.carnival.mirrorMaze.particles.SmokeBlast;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.render.ReflectionSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class MirrorMaze extends PlatformerGameScene
	{
		private var _events:CarnivalEvents;
		
		private var mirrorEmitter:MirrorBreak;
		private var mirrorEmitterEntity:Entity;
		private var mirrorTarget:Entity;
		private var smokeEmitter:SmokeBlast;
		private var smokeEmitterEntity:Entity;
		private var smokeTarget:Entity;
		private var flash:Entity;

		private var currCurtain:Entity;
		private var currMirror:Entity;
		private var finalCurtain:Entity;
		private var finalMirror:Entity;
		private var ringMasterMirror:Entity;
		private var curtainArray:Array = ["c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", "c9", "c10", "c11", "c12", "c13", "c14", "c15", "c16", "c17", "c18", "c19", "c20", "c21", "c22", "c23", "c24", "c25", "c26", "c27", "c28", "c29", "c30", "c31", "c32" ];
		private var mirrorArray:Array = ["m1", "m2", "m3", "m4", "m5", "m6", "m7", "m8", "m9", "m10", "m11", "m12", "m13", "m14", "m15", "m16", "m17", "m18", "m19", "m20", "m21", "m22", "m23", "m24", "m25", "m26", "m27", "m28", "m29", "m30", "m31", "m32"];
		private var wideArray:Array = ["wide1", "wide2"];
		private var tallArray:Array = ["tall1", "tall2", "tall3", "tall4", "tall5"];
		private var setsArray:Array = [2, 3, 4, 5, 6, 7];
		private var mirrorContainer:DisplayObjectContainer;
		private var savedRingMasterLevel:Number;
		private var edgar:Entity;
		private var ringMaster:Entity;
		private var panTarget:Entity;
		private var plat:Entity;
		private var platform:Platform;
		
		private var inFinalGame:Boolean = false;
		private var breakGlass:Boolean = false;
		
		private var currSet:Number = 1;
		private var currStart:Number = 0;
		private var currEntrance:Point;
		private var currSpeed:Number = 0.5;
		private var maxSpins:Number = 5;
		private var spins:Number;
		private var gameOver:Boolean = false;
		private var finalSetBreaks:Number = 0;
		
		private var chickenCycles:Number = 0;
		private var noHammer:Boolean = false;
		//private var _boatHit:Entity;
		private var testGotToPlatform:Boolean = false;
		
		public function MirrorMaze()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/mirrorMaze/";
			//super.showHits = true;
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
			super.addSystem(new ReflectionSystem(), SystemPriorities.postRender);
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			this.edgar = this.getEntityById("edgar");
			this.ringMaster = this.getEntityById("ringmaster");
			
			var movingHitData:MovingHitData = new MovingHitData();
			movingHitData.visible = "boatHit";
			
			var hitCreator:HitCreator = new HitCreator();
			//hitCreator.showHits = true;
			plat = hitCreator.createHit(super._hitContainer["boatHit"], HitType.MOVING_PLATFORM, movingHitData, this);
			
			var motion:Motion = plat.get(Motion);
			motion.friction = new Point(0,0);
			motion.maxVelocity = new Point(0,0);
			motion.minVelocity = new Point(0,0);
			motion.velocity = new Point(0,0);
			
			platform = plat.get(Platform);
			plat.remove(Platform);
			
			ringMaster.remove(Interaction);
			ringMaster.remove(SceneInteraction);
			ToolTipCreator.removeFromEntity(ringMaster);
			edgar.remove(Interaction);
			edgar.remove(SceneInteraction);
			ToolTipCreator.removeFromEntity(edgar);
			edgar.get(Display).alpha = 0;
			
			if(!super.shellApi.checkEvent(_events.ESCAPED_RINGMASTER_TENT)){
				inFinalGame = false;
				this.removeEntity(ringMaster);
				this.removeEntity(edgar);
			}else{
				inFinalGame = true;
				var te:TimedEvent = new TimedEvent(.5, 1, sayline, true);
				SceneUtil.addTimedEvent(this, te);
			}
			setupMirrors();	
			
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			if( event == "startGame" ) {
				gotoEntrance();
			}else if( event == "endTaunt" ) {
				runToMirrorSet();
			}else if( event == "becomeSlave" ) {
				jumpBehindMirror();
			}else if( event == "actChicken" ) {
				//CharUtils.setAnim(ringMaster, Chicken);
				edgar.get(Display).alpha = 1;
				CharUtils.followPath(edgar, new <Point> [new Point(player.get(Spatial).x + 100, player.get(Spatial).y)], reachedEdgar, true);
			}else if( event == "fadeBlack" ) {
/*				this.shellApi.completeEvent( this._events.ENSLAVED_RINGMASTER );
				super.shellApi.removeEvent(_events.SET_DAY);
				super.shellApi.removeEvent(_events.SET_NIGHT);
				super.shellApi.removeEvent(_events.SET_EVENING);
				
				super.shellApi.completeEvent(_events.SET_MORNING);
				
				//super.shellApi.loadScene(RidesEmpty, 50, 1758);
				//cutscene popup
				var popup:NextDayPopup = super.addChildGroup( new NextDayPopup( super.overlayContainer )) as NextDayPopup;
				popup.id = "nextDayPopup";*/
				handleEnslavement();
			}
		}

		private function handleEnslavement():void
		{
			shellApi.completeEvent(_events.ENSLAVED_RINGMASTER);
			shellApi.removeEvent(_events.SET_DAY);
			shellApi.removeEvent(_events.SET_NIGHT);
			shellApi.removeEvent(_events.SET_EVENING);
			shellApi.completeEvent(_events.SET_MORNING);

			shellApi.takePhoto( "12836", showNextDayPopup );
		}
		
		private function showNextDayPopup():void
		{
			var popup:NextDayPopup = super.addChildGroup( new NextDayPopup( super.overlayContainer )) as NextDayPopup;
			popup.id = "nextDayPopup";
		}
		
		/////////////////////////////////////////////////////////////////////GAME//////////////////////////////////////////////////////////////////
		private function gotoEntrance():void {
			plat.add(platform);
			plat.get(Spatial).x = super.getEntityById("m"+(currStart+1)).get(Spatial).x - 100;
			plat.get(Spatial).y = super.getEntityById("m"+(currStart+1)).get(Spatial).y + 159;
			openCurtain(super.getEntityById("c"+(currStart+1)));
			openCurtain(super.getEntityById("c"+(currStart+2)));
			openCurtain(super.getEntityById("c"+(currStart+3)));
			openCurtain(super.getEntityById("c"+(currStart+4)));
			rotateGlass(super.getEntityById("m"+(currStart+1)), 0.5);
			CharUtils.followPath(ringMaster, new <Point> [currEntrance], reachedEntrance, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, testResolveStuck, true));
			testGotToPlatform = true;
		}
		
		private function testResolveStuck():void {
			if(testGotToPlatform){
				reachedEntrance(ringMaster);
			}
		}
		
		private function reachedEntrance(entity:Entity):void {
			testGotToPlatform = false;
			CharUtils.stateDrivenOff(ringMaster, 0);
			CharUtils.setAnim(ringMaster, Stand);
			
			mirrorContainer.addChildAt(ringMaster.get(Display).displayObject, 0);
			
			var spatial:Spatial = ringMaster.get(Spatial);
			spatial.y = super.getEntityById("m"+(currStart+1)).get(Spatial).y + 120;
			spatial.x = super.getEntityById("m"+(currStart+1)).get(Spatial).x;
			spatial.rotation = 0;
			Motion(ringMaster.get(Motion)).pause = true;
			//startMirrorSpin();
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, startMirrorSpin, true));
		}
		
		private function startMirrorSpin():void {
			ringMaster.get(Spatial).y = super.getEntityById("m"+(currStart+1)).get(Spatial).y + 120;
			ringMaster.get(Spatial).x = super.getEntityById("m"+(currStart+1)).get(Spatial).x;
			plat.remove(Platform);
			rotateGlass(super.getEntityById("m"+(currStart+1)), currSpeed);
			rotateGlass(super.getEntityById("m"+(currStart+2)), currSpeed);
			rotateGlass(super.getEntityById("m"+(currStart+3)), currSpeed);
			rotateGlass(super.getEntityById("m"+(currStart+4)), currSpeed);
			SceneUtil.addTimedEvent(this, new TimedEvent(currSpeed * 2, 1, mirrorSpin, true));
			spins = maxSpins;
		}
		
		private function mirrorSpin():void {
			if(spins > 0){
				spins--;
				var s:String = "m"+(((currSet-1)*4)+Math.ceil(Math.random()*4));
				var s2:String = "m"+(((currSet-1)*4)+Math.ceil(Math.random()*4));

				ringMasterMirror = super.getEntityById(s);
				ringMaster.get(Spatial).x = super.getEntityById(s).get(Spatial).x;
				ringMaster.get(Spatial).y = super.getEntityById(s).get(Spatial).y + 120;
				panTarget.get(Spatial).x = super.getEntityById(s2).get(Spatial).x;
				panTarget.get(Spatial).y = super.getEntityById(s2).get(Spatial).y;
				rotateGlass(super.getEntityById("m"+(currStart+1)), currSpeed);
				rotateGlass(super.getEntityById("m"+(currStart+2)), currSpeed);
				rotateGlass(super.getEntityById("m"+(currStart+3)), currSpeed);
				rotateGlass(super.getEntityById("m"+(currStart+4)), currSpeed);
				SceneUtil.addTimedEvent(this, new TimedEvent(currSpeed * 2, 1, mirrorSpin, true));
			}else{
				noHammer = false;
				SceneUtil.lockInput(this, false);
				super.shellApi.camera.target = player.get(Spatial);
				panTarget.get(Spatial).x = super.getEntityById("m"+(currStart+2)).get(Spatial).x;
				panTarget.get(Spatial).y = super.getEntityById("m"+(currStart+2)).get(Spatial).y;
			}
		}
		
		private function breakRingMasterMirror():void {
			SceneUtil.lockInput(this, true);
			CharUtils.stateDrivenOn(ringMaster);
			Motion(ringMaster.get(Motion)).pause = false;
			_hitContainer.addChild(ringMaster.get(Display).displayObject);
			CharUtils.followPath(ringMaster, new <Point> [new Point(currMirror.get(Spatial).x - 90, currMirror.get(Spatial).y + 120)], leftMirror, true).validCharStates = new <String>[ CharacterState.STAND ];
			CharUtils.moveToTarget(player, currMirror.get(Spatial).x + 80, currMirror.get(Spatial).y + 120, false, faceRingMaster);
		}
		
		private function breakFinalMirror():void {
			noHammer = true;
			SceneUtil.lockInput(this, true);
			ringMaster.get(Spatial).y = currMirror.get(Spatial).y + 120;
			ringMaster.get(Spatial).x = currMirror.get(Spatial).x;
			CharUtils.stateDrivenOn(ringMaster);
			Motion(ringMaster.get(Motion)).pause = false;
			_hitContainer.addChild(ringMaster.get(Display).displayObject);
			CharUtils.followPath(ringMaster, new <Point> [new Point(finalMirror.get(Spatial).x - 90, player.get(Spatial).y)], leftMirror, true).validCharStates = new <String>[ CharacterState.STAND ];
			CharUtils.moveToTarget(player, finalMirror.get(Spatial).x + 80, 1913, false, faceRingMaster);
		}
		
		private function leftMirror(entity:Entity):void {
			if(!gameOver){
				SceneUtil.lockInput(this, true);
				faceRingMaster();
				Dialog(ringMaster.get(Dialog)).sayById("taunt"+Math.ceil(Math.random()*3));	
				SceneUtil.addTimedEvent(this, new TimedEvent(.75, 1, setSmoke, true));
			}else{
				SceneUtil.lockInput(this, true);
				faceRingMaster();
				Dialog(ringMaster.get(Dialog)).sayById("becomeSlave");	
			}
		}
		
		private function setSmoke():void {
			SceneUtil.lockInput(this, true);
			smokeTarget.get(Spatial).x = ringMaster.get(Spatial).x;
			smokeTarget.get(Spatial).y = ringMaster.get(Spatial).y;
		}
		
		private function runToMirrorSet():void {
			SceneUtil.lockInput(this, true);
			if(setsArray.length > 2){//2 is correct, 6 to test
				var index:Number = Math.ceil(Math.random()*(setsArray.length-1));
				currSet = setsArray[index];
				currStart = (currSet-1) * 4;
				setsArray.splice(index, 1);
				currSpeed -= 0.05;
				maxSpins += 1;
			}else{
				gameOver = true;
				currSet = 8;
				currStart = (currSet-1) * 4;
			}
			currEntrance.x = super.getEntityById("m"+(currStart+1)).get(Spatial).x;
			currEntrance.y = super.getEntityById("m"+(currStart+1)).get(Spatial).y + 80;
			CharUtils.stateDrivenOff(ringMaster, 0);
			//drop smoke
			smokeEmitter.start();
			
			ringMaster.get(Spatial).x = super.getEntityById("m"+(currStart+2)).get(Spatial).x - 130;
			ringMaster.get(Spatial).y = super.getEntityById("m"+(currStart+2)).get(Spatial).y + 150;
			panTarget.get(Spatial).x = super.getEntityById("m"+(currStart+2)).get(Spatial).x;
			panTarget.get(Spatial).y = super.getEntityById("m"+(currStart+2)).get(Spatial).y;
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, laugh, true));
		}
		
		private function laugh():void {
			super.shellApi.camera.target = panTarget.get(Spatial);
			CharUtils.setAnim(ringMaster, Laugh);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, gotoEntrance, true));
		}
		
		private function rotateGlass(mirror:Entity, speed:Number):void {
			super.shellApi.triggerEvent("rotateMirror");
			mirror.get(Tween).to(mirror.get(Spatial), speed, { scaleX:0, ease:Sine.easeInOut, onComplete:rotateGlass2, onCompleteParams:[mirror, speed] });
		}
		
		private function rotateGlass2(mirror:Entity, speed:Number):void {
			super.shellApi.triggerEvent("rotateMirror");
			mirror.get(Tween).to(mirror.get(Spatial), speed, { scaleX:1, ease:Sine.easeInOut });
		}
		/////////////////////////////////////////////////////////////////////END GAME//////////////////////////////////////////////////////////////////
		
		private function reachedEdgar(entity:Entity):void {
			CharUtils.setDirection(player, true);
			Dialog(edgar.get(Dialog)).sayById("stoppedRingmaster");	
		}
		
		private function jumpBehindMirror():void {
			flash.get(Spatial).x = finalMirror.get(Spatial).x;
			flash.get(Timeline).gotoAndPlay(1);
			rotateGlass(finalMirror, 0.5);
			plat.add(platform);
			plat.get(Spatial).x = finalMirror.get(Spatial).x - 100;
			plat.get(Spatial).y = finalMirror.get(Spatial).y + 159;
			CharUtils.setAnim(ringMaster, Throw);
			player.remove(Reflection);
			CharUtils.moveToTarget(player, finalMirror.get(Spatial).x, finalMirror.get(Spatial).y + 80, false, reachedFinalMirror);
		}
		
		private function reachedFinalMirror(entity:Entity):void {
			rotateGlass(finalMirror, 0.5);
			player.get(Display).alpha = 0;
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, jumpBackOut, true));
			SkinUtils.setSkinPart( ringMaster, SkinUtils.EYES, "hypnotized_raven");
		}
		
		private function jumpBackOut():void {
			player.get(Display).alpha = 1;
			var typesArray:Array = ["mirror"];
			player.add(new Reflection());
			plat.remove(Platform);
			CharUtils.moveToTarget(player, finalMirror.get(Spatial).x + 80, 1913, false, finalConversation);
		}
		
		private function finalConversation(entity:Entity):void {
			faceRingMaster();
			Dialog(player.get(Dialog)).sayById("enslaveRingmaster");
		}
		
		private function sayline():void {
			super.shellApi.camera.target = panTarget.get(Spatial);
			SceneUtil.lockInput(this);
			Dialog(ringMaster.get(Dialog)).sayById("tauntstart");
		}
		
		private function faceRingMaster(entity:Entity=null):void {
			if(player.get(Spatial).x < ringMaster.get(Spatial).x){
				CharUtils.setDirection(player, true);
				CharUtils.setDirection(ringMaster, false);
			}else{
				CharUtils.setDirection(player, false);
				CharUtils.setDirection(ringMaster, true);
			}
		}
		
		private function setupMirrors():void 
		{
			mirrorContainer = super.getEntityById("mirrors").get(Display).displayObject;
			mirrorContainer.mouseChildren = false;
			mirrorContainer.mouseEnabled = false;
			var typesArray:Array = ["mirror"];
			
			//ringMaster.add(new Reflection(typesArray));
			//edgar.add(new Reflection(typesArray));
			player.add(new Reflection(typesArray));
			//ringMaster.get(Display).alpha = 0;
			
			var shardAsset:MovieClip = super.getAsset( "shard.swf") as MovieClip; 
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(shardAsset);
			mirrorEmitter = new MirrorBreak();
			mirrorEmitter.init( bitmapData );
			
			mirrorTarget = new Entity();
			mirrorTarget.add(new Spatial());
			
			mirrorEmitterEntity = EmitterCreator.create( this, super._hitContainer, mirrorEmitter, 0, 0, player, "mEmitterEntity", mirrorTarget.get(Spatial), false );
			
			smokeEmitter = new SmokeBlast();
			smokeEmitter.init();
			
			smokeTarget = new Entity();
			smokeTarget.add(new Spatial(player.get(Spatial).x, player.get(Spatial).y));
			
			smokeEmitterEntity = EmitterCreator.create( this, super._hitContainer, smokeEmitter, 0, 0, player, "sEmitterEntity", smokeTarget.get(Spatial), false );
			
			/*for(var i:uint=0;i<curtainArray.length;i++){
				var clip:MovieClip = mirrorContainer[curtainArray[i]];
				var entity:Entity = new Entity();
				entity = TimelineUtils.convertClip(clip, this, entity);
				entity.add(new Id(curtainArray[i]));
				super.addEntity(entity);
				if(!inFinalGame){
					entity.get(Timeline).gotoAndStop("curtainOpen");
				}else{
					entity.get(Timeline).gotoAndStop(0);
				}
			}*/
			
			var bitSequence:BitmapSequence;
			var clip:MovieClip;
			var entity:Entity;
			for(var i:uint=0;i<curtainArray.length;i++){
				
				if(i==0){
					clip = mirrorContainer[curtainArray[i]];
					entity = new Entity();
					entity.add(new Display(clip));
					entity.add(new Spatial(clip.x, clip.y));
					entity.add(new Id(curtainArray[i]));
					super.addEntity(entity);
					BitmapTimelineCreator.convertToBitmapTimeline(entity);
					bitSequence = entity.get(BitmapSequence);
				}else{
					clip = mirrorContainer[curtainArray[i]];
					entity = new Entity();
					entity.add(new Display(clip));
					entity.add(new Id(curtainArray[i]));
					super.addEntity(entity);
					BitmapTimelineCreator.convertToBitmapTimeline(entity, null, true, bitSequence);
				}
				
				if(!inFinalGame){
					entity.get(Timeline).gotoAndStop("curtainOpen");
				}else{
					entity.get(Timeline).gotoAndStop(0);
				}
			}
			
			for(var j:uint=0;j<mirrorArray.length;j++){
				var clip2:MovieClip = mirrorContainer[mirrorArray[j]];
				var entity2:Entity = new Entity();
				var spatial:Spatial = new Spatial();
				spatial.x = clip2.x;
				spatial.y = clip2.y;
				entity2.add(spatial);
				entity2.add(new Display(clip2));
				entity2.add(new Id(mirrorArray[j]));
				entity2.add(new Tween());
				super.addEntity(entity2);
				
				var bd:BitmapData = new BitmapData(clip2.width,clip2.height,true,0x00000000);
				var bitmap:Bitmap = new Bitmap(bd);
				clip2.addChild(bitmap);
				bitmap.x = -64;
				clip2.swapChildren(bitmap, clip2.sheen);
				
				var display:Display = new Display(bitmap, clip2);
				
				var reEntity:Entity = new Entity();
				reEntity.add(display);
				
				reEntity.add(new Reflective(Reflective.SURFACE_BACK, "mirror"));
				
				super.addEntity(reEntity);
			}
			
			panTarget = EntityUtils.createSpatialEntity(this, _hitContainer["panTarget"], _hitContainer);
			panTarget.get(Display).alpha = 0;
			
			currEntrance = new Point();
			currEntrance.x = super.getEntityById("m1").get(Spatial).x;
			currEntrance.y = super.getEntityById("m1").get(Spatial).y + 80;
			
			var flashClip:MovieClip = MovieClip(_hitContainer)["flash"];
			flash = new Entity();
			flash = TimelineUtils.convertClip( flashClip, this, flash );
			
			var fspatial:Spatial = new Spatial();
			fspatial.x = flashClip.x;
			fspatial.y = flashClip.y;
			
			flash.add(fspatial);
			flash.add(new Display(flashClip));
			
			super.addEntity(flash);
			flash.get(Timeline).gotoAndStop(0);
			
			setupWideMirrors();
			setupTallMirrors();
		}
		
		private function setupMirrorEmitter():void {
			
		}
		
		private function setupWideMirrors():void {
			for(var j:uint=0;j<wideArray.length;j++){
				var clip2:MovieClip = mirrorContainer[wideArray[j]];
				var entity2:Entity = new Entity();
				var spatial:Spatial = new Spatial();
				spatial.x = clip2.x;
				spatial.y = clip2.y;
				entity2.add(spatial);
				entity2.add(new Display(clip2));
				entity2.add(new Id(wideArray[j]));
				entity2.add(new Tween());
				super.addEntity(entity2);
				
				var bd:BitmapData = new BitmapData(clip2.width * .5,clip2.height,true,0x00000000);
				var bitmap:Bitmap = new Bitmap(bd);
				clip2.addChild(bitmap);
				bitmap.width = clip2.width;
				clip2.swapChildren(bitmap, clip2.sheen);
				
				var display:Display = new Display(bitmap, clip2);
				
				var reEntity:Entity = new Entity();
				reEntity.add(display);
				
				reEntity.add(new Reflective(Reflective.SURFACE_BACK, "mirror", -80, 0));
				
				super.addEntity(reEntity);
			}
		}
		
		private function setupTallMirrors():void {
			for(var j:uint=0;j<tallArray.length;j++){
				var clip2:MovieClip = mirrorContainer[tallArray[j]];
				var entity2:Entity = new Entity();
				var spatial:Spatial = new Spatial();
				spatial.x = clip2.x;
				spatial.y = clip2.y;
				entity2.add(spatial);
				entity2.add(new Display(clip2));
				entity2.add(new Id(tallArray[j]));
				entity2.add(new Tween());
				super.addEntity(entity2);
				
				var bd:BitmapData = new BitmapData(clip2.width,clip2.height * .5,true,0x00000000);
				var bitmap:Bitmap = new Bitmap(bd);
				clip2.addChild(bitmap);
				bitmap.height = clip2.height;
				clip2.swapChildren(bitmap, clip2.sheen);
				
				var display:Display = new Display(bitmap, clip2);
				
				var reEntity:Entity = new Entity();
				reEntity.add(display);
				
				reEntity.add(new Reflective(Reflective.SURFACE_BACK, "mirror", 10, -120));
				
				super.addEntity(reEntity);
			}
		}
		
		private function closeCurtain(curtain:Entity):void {
			curtain.get(Timeline).gotoAndStop("off");
		}
		
		private function openCurtain(curtain:Entity):void {
			curtain.get(Timeline).gotoAndPlay("openCurtain");
		}
		
		private function crackGlass(curtain:Entity):void {
			curtain.get(Timeline).gotoAndPlay("crackGlass");
		}
		
		public function hammerStrike():void {
			if(breakGlass){
				if(currCurtain.get(Timeline).currentIndex != 0 && currCurtain.get(Timeline).currentIndex != 26){
					mirrorEmitter.start();
					crackGlass(currCurtain);
					if(gameOver){
						if(currCurtain == super.getEntityById("c29") || currCurtain == super.getEntityById("c30") || currCurtain == super.getEntityById("c31")){
							if(finalSetBreaks < 1){
								finalSetBreaks++;
							}else{
								if(currCurtain == super.getEntityById("c29")){
									if(super.getEntityById("c30").get(Timeline).currentIndex == 12){
										finalCurtain = super.getEntityById("c30");	
										finalMirror = super.getEntityById("m30");
									}else{
										finalCurtain = super.getEntityById("c31");
										finalMirror = super.getEntityById("m31");
									}
								}else if(currCurtain == super.getEntityById("c30")){
									if(super.getEntityById("c29").get(Timeline).currentIndex == 12){
										finalCurtain = super.getEntityById("c29");
										finalMirror = super.getEntityById("m29");
									}else{
										finalCurtain = super.getEntityById("c31");
										finalMirror = super.getEntityById("m31");
									}
								}else if(currCurtain == super.getEntityById("c31")){
									if(super.getEntityById("c29").get(Timeline).currentIndex == 12){
										finalCurtain = super.getEntityById("c29");
										finalMirror = super.getEntityById("m29");
									}else{
										finalCurtain = super.getEntityById("c30");
										finalMirror = super.getEntityById("m30");
									}
								}
								breakFinalMirror();
							}
						}
					}else if(currMirror == ringMasterMirror){
						breakRingMasterMirror();
					}
				}
			}
		}
		
		public function stopHammerStrike():Boolean {
			if(!super.shellApi.checkEvent(_events.ESCAPED_RINGMASTER_TENT)){
				Dialog(player.get(Dialog)).sayById("dontUseHammer");
				return true;
			}else{
				if(!noHammer){
					var mirror:Entity;
					var curtain:Entity;
					var offset:Number;
					if(player.get(Spatial).scaleX > 0){
						offset = -30;
					}else{
						offset = 30;
					}
					
					for(var i:uint=0;i<mirrorArray.length;i++){
						mirror = super.getEntityById(mirrorArray[i]);
						curtain = super.getEntityById(curtainArray[i]);
						if(Math.abs(mirror.get(Spatial).x - (player.get(Spatial).x + offset)) < 100 && Math.abs(mirror.get(Spatial).y - (player.get(Spatial).y - 80)) < 100){
							mirrorTarget.get(Spatial).x = mirror.get(Spatial).x;
							mirrorTarget.get(Spatial).y = mirror.get(Spatial).y + 50;
							currCurtain = curtain;
							currMirror = mirror;
							breakGlass = true;
							//rotateGlass(mirror);
							return false;
						}else{
							breakGlass = false;
						}
					}
					return false;
				}else{
					return true;
				}
			}
		}
	}
}








