package game.scenes.deepDive2.pipeRoom
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Quad;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.motion.Proximity;
	import game.components.motion.RotateToVelocity;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.sound.SoundModifier;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive1.shared.components.Filmable;
	import game.scenes.deepDive1.shared.components.SubCamera;
	import game.scenes.deepDive1.shared.systems.FishPathSystem;
	import game.scenes.deepDive2.DeepDive2Events;
	import game.scenes.deepDive2.pipeRoom.components.Pipe;
	import game.scenes.deepDive2.pipeRoom.systems.PipeSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.ProximitySystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	
	public class PipeRoom extends SubScene
	{
		private var goButton:Entity;
		private var movingFish:Entity;
		private var tankFish:Entity;
		private var extraFish:Entity;
		
		private var piece4:Entity;
		private var piece5:Entity;
		
		private var glyph1:Entity;
		
		private var pipes:Vector.<Entity>;
		
		private var pipeLinkMap:Array;
		private var pipeTypes:Array;
		private var fishPath:Array;
		private var pipeRotations:Array;
		
		private var pipeSys:PipeSystem;
		
		private var fishMoving:Boolean = false;
		private var highQuality:Boolean;
		private var fishInTank:Boolean;
		private var pipeRotating:Boolean;
		
		private var _dd2Events:DeepDive2Events;
		
		private var intakePipe:Timeline;
		private var buttonTL:Timeline;
		
		private var tankLight:Entity;
		private var tankWire:Entity;
		
		private var messagePlaying:Boolean;
		private var nextComment:Function;
		
		public function PipeRoom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive2/pipeRoom/";
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
			_dd2Events = DeepDive2Events(events);
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGH){
				highQuality = true;	
			}
			else{
				highQuality = false;
			}
			
			super.addLight(super.shellApi.player, 400, .4, true, false, 0x000033, 0x000033);
			
			var subCamera:SubCamera = super.shellApi.player.get(SubCamera);
			subCamera.angle = 120;
			subCamera.distanceMax = 400;
			subCamera.distanceMin = 0;
			
			//CameraGroup(this.getGroupById("cameraGroup")).zoomTarget = .9;
			loadPipeTest();
			shellApi.eventTriggered.add(handleEvents);
			setupGlyphs();
			
			super.loaded();
		}
		
		private function handleEvents( event:String, ...p):void
		{
			if(event ==_dd2Events.GOT_PUZZLE_PIECE_+4){
				shellApi.getItem(_dd2Events.PUZZLE_KEY,null,true);
			}
			else if(event ==_dd2Events.GOT_PUZZLE_PIECE_+5){
				shellApi.getItem(_dd2Events.PUZZLE_KEY,null,true);
			}
			
		}
		
		private function setupGlyphs():void
		{
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapUtils.convertContainer(_hitContainer["filmGlyph1"], PerformanceUtils.defaultBitmapQuality);
			}

			glyph1 = EntityUtils.createSpatialEntity(this,_hitContainer["filmGlyph1"]);
			
			glyph1.add(new Id("glyph_1"));
			
			var isCaptured:Boolean = shellApi.checkItemEvent(_dd2Events.GLYPH_+4);
			glyph1 = makeFilmable(glyph1,handleFilmed,200,3,true,true,isCaptured);
		}
		
		private function loadPipeTest():void
		{			
			addSystem(new ThresholdSystem(),SystemPriorities.move);
			pipeSys = PipeSystem(this.addSystem( new PipeSystem()));
			
			pipes = new Vector.<Entity>();
			
			// bitmap clear pipes
			BitmapUtils.convertContainer(_hitContainer["staticPipes"],PerformanceUtils.defaultBitmapQuality);
			
			var startClip:DisplayObjectContainer = _hitContainer["pipeStart"];
			BitmapUtils.convertContainer(startClip,PerformanceUtils.defaultBitmapQuality);
			var startPipe:Entity = EntityUtils.createMovingEntity(this,startClip);
			startPipe.add(new Id("pipeStart"));
			startPipe.get(Display).moveToBack();
			pipes.push(startPipe);
			// moving pipes
			for (var i:int = 0; i < 16; i++) 
			{
				var clip:DisplayObjectContainer = _hitContainer["pipe"+i];
				BitmapUtils.convertContainer(clip,PerformanceUtils.defaultBitmapQuality);
				var pipe:Entity = EntityUtils.createMovingEntity(this, clip);
				pipe.add(new Id("pipe"+i));
				Display(pipe.get(Display)).moveToBack();
				InteractionCreator.addToEntity(pipe,[InteractionCreator.CLICK]);
				ToolTipCreator.addToEntity(pipe);
				pipes.push(pipe);
				var interaction:Interaction = pipe.get(Interaction);
				interaction.click.add(Command.create(rotatePipe,pipe));
			}
			var tankClip:MovieClip = _hitContainer["tank"];
			var endPipe:Entity = EntityUtils.createMovingTimelineEntity(this, tankClip, null, false);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				endPipe = BitmapTimelineCreator.convertToBitmapTimeline(endPipe,tankClip,true,null,PerformanceUtils.defaultBitmapQuality);
			}
			endPipe.add(new Id("tank"));
			Display(endPipe.get(Display)).moveToBack();
			pipes.push(endPipe);
			
			setupFish();
			
			setupButton();
			
			setupPuzzlePieces();
			
			// init each pipe's starting connection possibilities
			pipeLinkMap = [
				[ null,null,null,pipes[1] ],
				[ null,pipes[0],null,pipes[2] ],
				[ null,pipes[1],pipes[6],pipes[3] ],
				[ null,pipes[2],pipes[7],pipes[4] ],
				[ null,pipes[3],null,pipes[17] ],
				[ pipes[1],null,pipes[9],pipes[6] ],
				[ pipes[2],pipes[5],pipes[10],null ],
				[ pipes[3],null,pipes[11],pipes[8] ],
				[ pipes[4],pipes[7],pipes[12],null ],
				[ pipes[5],null,pipes[13],pipes[10] ],
				[ pipes[6],pipes[9],pipes[14],pipes[11] ],
				[ pipes[7],pipes[10],pipes[15],pipes[12] ],
				[ pipes[8],pipes[11],pipes[16],null ],
				[ pipes[9],null,null,pipes[14] ],
				[ pipes[10],pipes[13],null,pipes[15] ],
				[ pipes[11],pipes[14],null,pipes[16] ],
				[ pipes[12],pipes[15],null,null ],
				[ null,pipes[4],null,null ],
			];
			
			pipeTypes = [Pipe.TYPE_START,Pipe.TYPE_BAR,Pipe.TYPE_ANGLE,Pipe.TYPE_ANGLE,Pipe.TYPE_BAR,
				Pipe.TYPE_ANGLE,Pipe.TYPE_ANGLE,Pipe.TYPE_ANGLE,Pipe.TYPE_ANGLE,
				Pipe.TYPE_BAR,Pipe.TYPE_ANGLE,Pipe.TYPE_ANGLE,Pipe.TYPE_BAR,
				Pipe.TYPE_ANGLE,Pipe.TYPE_ANGLE,Pipe.TYPE_ANGLE,Pipe.TYPE_ANGLE,Pipe.TYPE_END];
			
			pipeRotations = [0 ,0,0,1,0,3,2,3,3,0,3,3,0,3,3,2,3, 0];
			
			// add components
			for (var j:int = 0; j < pipes.length; j++) 
			{
				var link:Pipe = new Pipe(pipeRotations[j],pipeLinkMap[j],pipeTypes[j]);
				pipes[j].add(link);
				if(j == pipes.length-1){
					link.rotationUpdated = true;
				}
			}
			
			// tank light anims
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapUtils.convertContainer(_hitContainer["tankLights"], PerformanceUtils.defaultBitmapQuality);
				BitmapUtils.convertContainer(_hitContainer["tankWire"], PerformanceUtils.defaultBitmapQuality);
			}
			tankLight = EntityUtils.createSpatialEntity(this,_hitContainer["tankLights"]["orange"]);
			tankLight.add(new Id("tankLights"));
			tankLight.get(Display).visible = false;
			tankWire = EntityUtils.createSpatialEntity(this,_hitContainer["tankWire"]["orange"]);
			tankWire.add(new Id("tankWire"));
			tankWire.get(Display).visible = false;
			
			DisplayUtils.moveToTop(_hitContainer["tank"]);
			DisplayUtils.moveToTop(_hitContainer["tankLights"]);
			DisplayUtils.moveToTop(shellApi.player.get(Display).displayObject);
			
			var intake:Entity = EntityUtils.createMovingTimelineEntity(this,_hitContainer["intakePipe"]);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				intake = BitmapTimelineCreator.convertToBitmapTimeline(intake,_hitContainer["intakePipe"],true,null,PerformanceUtils.defaultBitmapQuality);
			}
			intake.add(new Id("intakePipe"));
			intakePipe = intake.get(Timeline);
			
			//if sucess already happened, position the fish
			if(shellApi.checkEvent(_dd2Events.COMPLETED_PIPES) ){
				turnOnTankLights();
				EntityUtils.positionByEntity(tankFish,pipes[pipes.length - 1],false,false);
				tankFish.get(Timeline).gotoAndPlay("goBig");
				fishInTank = true;
				//shellApi.triggerEvent("tankOn");
				playTankSound();
			}
		}
		
		private function turnOnTankLights():void
		{
			// added a light to the tank itself to make it appear more energized (similar to predator area) - Bart
			var tank:Entity = getEntityById("tank");
			Timeline(tank.get(Timeline)).gotoAndStop("on");
			
			var disp:Display = tankLight.get(Display)
			disp.visible = true;
			disp.alpha = 0;
			disp = tankWire.get(Display);
			disp.visible = true;
			disp.alpha = 0;
			fadeIn(tankWire);
			fadeIn(tankLight);
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
		
		private function setupPuzzlePieces():void
		{
			//addItems();
			piece4 = EntityUtils.createMovingEntity(this, _hitContainer["puzzlePiece2"]);
			var pInt:Interaction = InteractionCreator.addToEntity(piece4,[InteractionCreator.CLICK]);
			pInt.click.add(pieceComment); 
			piece5 = EntityUtils.createMovingEntity(this, _hitContainer["puzzlePiece3"]);
			pInt = InteractionCreator.addToEntity(piece5,[InteractionCreator.CLICK]);
			pInt.click.add(pieceComment);
			piece4.add(new Id("puzzlePiece2"));
			piece5.add(new Id("puzzlePiece3"));
			ToolTipCreator.addToEntity(piece4);
			ToolTipCreator.addToEntity(piece5);
			if(shellApi.checkEvent(_dd2Events.GOT_PUZZLE_PIECE_ + 4)){
				removeEntity(piece4);
				piece4 = null;
			}
			if(shellApi.checkEvent(_dd2Events.GOT_PUZZLE_PIECE_ + 5)){
				removeEntity(piece5);
				piece5 = null;
			}
		}
		
		private function setupFish():void
		{
			addSystem(new FishPathSystem(),SystemPriorities.update);
			movingFish = addFishEntity("puffer0");
			tankFish = addFishEntity("puffer1");
			extraFish = addFishEntity("puffer2");			
		}
		
		private function setupButton():void
		{
			addSystem(new ProximitySystem());
			goButton = getEntityById("fishButtonInteraction");
			goButton = TimelineUtils.convertClip(EntityUtils.getDisplayObject(goButton) as MovieClip,this,goButton,null,false);
			if(!shellApi.checkEvent(_dd2Events.SAW_BUTTON)){
				var prox:Proximity = new Proximity(800,shellApi.player.get(Spatial));
				prox.entered.addOnce(spotButton);
				goButton.add(prox);
				shellApi.completeEvent(_dd2Events.SAW_BUTTON);
			}
			buttonTL = goButton.get(Timeline);
			var sceneInter:SceneInteraction = goButton.get(SceneInteraction);
			sceneInter.offsetX = 60;
			sceneInter.minTargetDelta.y = 30;
			sceneInter.minTargetDelta.x = 30;
			sceneInter.reached.addOnce(pushButton);
		}
		
		private function pushButton(...p):void
		{
			buttonTL.gotoAndPlay("up");
			buttonTL.handleLabel("down",Command.create(startFishMove,movingFish));
			TweenUtils.globalTo(this,shellApi.player.get(Spatial),0.9,{x:shellApi.player.get(Spatial).x+60},"button_go");
			shellApi.triggerEvent("switchHit");
		}
		
		private function spotButton(...p):void
		{
			SceneUtil.lockInput(this,true);
			SceneUtil.setCameraTarget(this,goButton,false,0.07);
			SceneUtil.addTimedEvent(this, new TimedEvent(3,1,camToSub));
			//playMessage("spotbutton",camToSub);
		}
		
		private function camToSub(...p):void
		{
			SceneUtil.lockInput(this,false);
			SceneUtil.setCameraTarget(this,shellApi.player,false,0.1);
		}
		
		private function pieceComment(...p):void
		{
			// player talks
			playMessage("spotPuzzlePiece");
		}
		
		private function startFishMove(...p):void
		{
			//generate path
			SceneUtil.addTimedEvent(this, new TimedEvent(2,1,Command.create(buttonTL.gotoAndPlay,"down")));
			updateFishPath();
			if(fishPath.length > 0){
				fishMoving = true;
				var pathSpat:Spatial = fishPath[0].get(Spatial); 
				TweenUtils.globalTo(this, movingFish.get(Spatial),0.7, {x:pathSpat.x, y:pathSpat.y, ease:Bounce.easeInOut, onComplete:fishNextMove});
				if(fishInTank && fishPath[fishPath.length-1].get(Id).id == "tank"){
					fishInTank = false;
					EntityUtils.position(tankFish, 2400, 600);
				}
			}else{
				fishMoving = false;
				var inter:SceneInteraction = goButton.get(SceneInteraction);
				inter.reached.addOnce(pushButton);
			}
		}
		
		private function updateFishPath():void
		{
			fishPath = new Array();
			pipeSys.updatePath();
			fishPath = pipeSys.currentPath;
			
			SceneUtil.lockInput(this,true);
			SceneUtil.setCameraTarget(this,movingFish,false,.08);
			
			if(!shellApi.checkEvent(_dd2Events.USED_PIPES)){
				shellApi.completeEvent(_dd2Events.USED_PIPES);
				SceneUtil.addTimedEvent(this,new TimedEvent(2,1,Command.create(playMessage,"fishMoved")));
			}
		}
		
		private function fishNextMove(index:int = 0):void{
			var movingSpat:Spatial = movingFish.get(Spatial);
			if(index == 0){
				intakePipe.gotoAndPlay("start");
				intakePipe.handleLabel("end", spinFish);
				movingFish.get(Timeline).gotoAndPlay("goBig");
				movingSpat.scaleX *= -1;
				shellApi.triggerEvent("pipeWoosh");
			}
			else if(index == 1){
				movingSpat.scaleX *= -1;
			}
			if(index < fishPath.length){
				shellApi.triggerEvent("fishMove");
				var pathSpat:Spatial = fishPath[index].get(Spatial);
				TweenUtils.globalTo(this, movingSpat, 0.7, {x:pathSpat.x, y:pathSpat.y, onComplete:Command.create(fishNextMove, index +1)});
			}else{
				// wander off somewhere or do sucess
				movingFish.get(Motion).rotationVelocity = 0;
				fishMoving = false;
				var lastPipe:Pipe = fishPath[index-1].get(Pipe)
				if(!lastPipe.endPiece){
					// escape from pipe, start puzzle hit test
					movePuzzlePiece(fishPath[index-1]);
					sendFishOffScreen(lastPipe.exitDirection);
				}
				else{
					//sucess
					if(!shellApi.checkEvent(_dd2Events.COMPLETED_PIPES)){
						shellApi.triggerEvent(_dd2Events.COMPLETED_PIPES,true);
						playMessage("fishTrapped");
						shellApi.triggerEvent("tankOn");
						playTankSound();
					}
					turnOnTankLights();
					TweenUtils.globalTo(this, movingSpat,1.2, {rotation:180});
					replacefish();
				}
				SceneUtil.lockInput(this,false);
			}
		}
		
		// add positional audio
		private function playTankSound():void
		{
			var tank:Entity = getEntityById("tank");
			tank.get(Timeline).gotoAndStop("on");
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "alien_gen_uw.mp3", true, [SoundModifier.POSITION]); // changed for consistency - Bart
			tank.add(audio);
			tank.add(new AudioRange(950, 1.4, 2, Quad.easeIn));
		}
		
		private function movePuzzlePiece(lastPipe:Entity):void
		{
			var id:String = lastPipe.get(Id).id;
			var thresh:Threshold = new Threshold("y","<");
			thresh.threshold = 315;
			var spd:Number = 450;
			if(id == "pipe4" && piece4){
				piece4.get(Motion).velocity.y = -spd;
				piece4.add(new Sleep(false,true));
				thresh.entered.addOnce(Command.create(releasePuzzlePiece,piece4));
				piece4.add(thresh);
				MotionUtils.addWaveMotion(piece4, new WaveMotionData("y",5,0.1),this);
				entityToFront(piece4);
				shellApi.triggerEvent("pieceReleased");
			}else if( id == "pipe7" && piece5){
				piece5.get(Motion).velocity.y = -spd;
				piece5.add(new Sleep(false,true));
				thresh.entered.addOnce(Command.create(releasePuzzlePiece,piece5));
				piece5.add(thresh);
				MotionUtils.addWaveMotion(piece5, new WaveMotionData("y",6,0.1),this);
				entityToFront(piece5);
				shellApi.triggerEvent("pieceReleased");
			}
		}
		
		private function releasePuzzlePiece(piece:Entity):void
		{
			//ready piece for collection
			MotionUtils.zeroMotion(piece);
			var inter:Interaction = piece.get(Interaction);
			inter.click.removeAll();
			var sceneInt:SceneInteraction = new SceneInteraction();
			sceneInt.targetX = piece.get(Spatial).x;
			sceneInt.targetY = piece.get(Spatial).y;
			sceneInt.minTargetDelta.x = 20;
			sceneInt.minTargetDelta.y = 20;
			piece.add(sceneInt);
			var prox:Proximity = new Proximity(200,shellApi.player.get(Spatial));
			prox.entered.addOnce(getPuzzlePiece);
			piece.add(prox);
		}
		
		private function getPuzzlePiece(piece:Entity):void
		{
			var id:String = piece.get(Id).id;
			if(id == "puzzlePiece2"){
				shellApi.triggerEvent(_dd2Events.GOT_PUZZLE_PIECE_+4,true);
				removeEntity(piece4);
				piece4  = null;
			}
			else if(id == "puzzlePiece3"){
				shellApi.triggerEvent(_dd2Events.GOT_PUZZLE_PIECE_+5,true);
				removeEntity(piece5);
				piece5 = null;
			}
			shellApi.getItem(_dd2Events.PUZZLE_KEY,null);
			//force show item
			shellApi.showItem(_dd2Events.PUZZLE_KEY,null);
		}
		
		private function sendFishOffScreen(dir:int):void
		{
			var spd:Number = 500;
			var thresh:Threshold;
			var movingSpat:Spatial = movingFish.get(Spatial);
			if(dir == 0){
				movingFish.get(Motion).velocity.y = -spd;
				TweenUtils.globalTo(this, movingSpat, 1, { rotation:-90},"fishMove", 0);
				thresh = new Threshold("y","<");
				thresh.threshold = -150;
			}
			else if(dir == 1){
				movingFish.get(Motion).velocity.x = spd;
				TweenUtils.globalTo(this, movingSpat, 1, { rotation:0},"fishMove", 0);
				thresh = new Threshold("x",">");
				movingSpat.scaleY = -1;
				thresh.threshold = 2400;
			}
			else if(dir == 2){
				movingFish.get(Motion).velocity.y = spd;
				TweenUtils.globalTo(this, movingSpat, 1, { rotation:90},"fishMove", 0);
				thresh = new Threshold("y",">");
				thresh.threshold = 2400;
			}
			else if(dir == 3){
				movingFish.get(Motion).velocity.x = -spd;
				TweenUtils.globalTo(this, movingSpat, 1, { rotation:180},"fishMove", 0);
				movingSpat.scaleY = 1;
				thresh = new Threshold("x","<");
				thresh.threshold = -150;
			}
			movingFish.add(new Sleep(false,true));
			thresh.entered.addOnce(resetFish);
			thresh.entered.addOnce(camToSub);
			movingFish.add(thresh);
			entityToFront(movingFish);
		}
		
		private function entityToFront(ent:Entity):void
		{
			SceneUtil.addTimedEvent(this,new TimedEvent(0.3,1,Command.create(ent.get(Display).moveToFront)));
		}
		
		private function replacefish(...p):void
		{
			var pos:Point = EntityUtils.getPosition(movingFish);
			EntityUtils.position(tankFish, pos.x, pos.y);
			tankFish.get(Display).moveToBack();
			tankFish.get(Timeline).gotoAndStop("big");
			fishInTank = true;
			resetFish();
			SceneUtil.setCameraTarget(this,tankFish);
			SceneUtil.addTimedEvent(this, new TimedEvent(6,1,camToSub));
		}
		
		private function spinFish(...p):void
		{
			movingFish.get(Motion).rotationVelocity = 80;			
		}
		
		private function resetFish(...p):void
		{
			// reset button and fishy
			MotionUtils.zeroMotion(movingFish);
			var movingSpat:Spatial = movingFish.get(Spatial);
			movingSpat.scaleY = 1;
			movingSpat.rotation = 180;
			movingFish.get(Timeline).gotoAndPlay("goSmall");
			var inter:SceneInteraction = goButton.get(SceneInteraction);
			inter.reached.addOnce(pushButton);
			EntityUtils.position(movingFish, 2300, 506);
			TweenUtils.globalTo(this, movingSpat,2, {x:2100},"fishMove", 0);
			Display(movingFish.get(Display)).moveToBack();
		}
		
		private function rotatePipe(player:Entity, pipe:Entity):void
		{
			if(!fishMoving && !pipeRotating){
				pipeRotating = true;
				var motion:Motion = pipe.get(Motion);
				var rotationtarget:Number = motion.rotation + 90;
				TweenUtils.globalTo(this, motion, 0.40, {rotation:rotationtarget, onComplete:Command.create(completeRotate,pipe)},"pipeSpin");
				shellApi.triggerEvent("rotatePipe");
			}
		}		
		
		private function completeRotate(pipe:Entity):void
		{
			pipeRotating = false;
			var link:Pipe = pipe.get(Pipe);
			link.rotatePipeTick();
			shellApi.triggerEvent("pipeStop");
		}	
		
		
		private function handleFilmed( glyph:Entity ):void
		{
			var id:String = glyph.get(Id).id;
			var filmable:Filmable = glyph.get(Filmable);
			if(id == "glyph_1"){
				handleFilmStates(filmable, _dd2Events.GLYPH_ + 4);
			}
			//			else if(id == "glyph_2"){
			//				handleFilmStates(filmable, _dd2Events.GLYPH_+1);
			//			}
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
			if(!messagePlaying){
				playMessage(camMessage, messageClosed);
				messagePlaying = true;
			}
			else{
				nextComment = Command.create(playMessage,camMessage,messageClosed);
			}
		}
		
		private function messageClosed():void
		{
			messagePlaying = false;
			if(nextComment){
				nextComment();
				nextComment = null;
			}
		}
		
		private function addFishEntity(name:String):Entity
		{
			var nfish:Entity = EntityUtils.createMovingEntity(this,_hitContainer[name]);
			nfish = TimelineUtils.convertClip(_hitContainer[name],this,nfish,null,false);
			nfish.add(new Id(name));
			var rot:RotateToVelocity = new RotateToVelocity(0,0.7);
			rot.mirrorHorizontal = true;
			rot.originY = nfish.get(Spatial).scaleY;
			rot.originX = nfish.get(Spatial).scaleX;
			nfish.add(rot);
			nfish.get(Display).moveToBack();
			MotionUtils.addWaveMotion(nfish, new WaveMotionData("y",6,0.1),this);
			return nfish;
		}
	}
}
