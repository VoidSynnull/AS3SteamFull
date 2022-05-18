package game.scenes.timmy.timmysHouse
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.OriginPoint;
	import game.components.entity.Sleep;
	import game.components.hit.Door;
	import game.components.hit.ValidHit;
	import game.components.motion.FollowTarget;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Score;
	import game.data.scene.hit.MovingHitData;
	import game.scenes.mocktropica.cheeseInterior.systems.VariableTimelineSystem;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.timmy.TimmyScene;
	import game.scenes.timmy.timmysStreet.TimmysStreet;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.SetDirectionAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.TriggerEventAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ProximitySystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class TimmysHouse extends TimmyScene
	{
		private var roomba:Entity;
		private var roombaPlat:Entity;
		private var cabinet:Entity;
		private var treats:Entity;
		private var shoes:Entity;
		private var closet:Entity;
		private var garbanzo:Entity;
		private var key:Entity;	
		private var lazyBearCam:Entity;
		private var lazyBearOverlay:Entity;
		private var roombaText:Entity;
		private var totalclick:Entity;
		
		private var timmy:Entity;
		
		private var roombaTimer:TimedEvent;
		
		private const SAD_BEEP_SOUND:String =  SoundManager.EFFECTS_PATH + "alert_01.mp3";
		private const HAPPY_BEEP_SOUND:String =  SoundManager.EFFECTS_PATH + "points_ping_03c.mp3";
		private const VAC_SOUND:String =  SoundManager.EFFECTS_PATH + "small_engine_01_loop.mp3";
		private const OPEN_BOT_SOUND:String =  SoundManager.EFFECTS_PATH + "metal_impact_small_01.mp3";
		private const CUT_SOUND:String = SoundManager.EFFECTS_PATH + "scissor_cut_01.mp3";
		private const UNLOCK_SOUND:String = SoundManager.EFFECTS_PATH + "bathroom_unlocked_01.mp3";
		private const BREAK_SOUND:String = SoundManager.EFFECTS_PATH + "glass_break_03.mp3";
		private const DROP_SOUND:String = SoundManager.EFFECTS_PATH + "arrow_hit_dirt_01.mp3";
		private const SMASH_SOUND:String =	SoundManager.EFFECTS_PATH + "wood_break_01.mp3";

		
		public function TimmysHouse()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/timmy/timmysHouse/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function addBaseSystems():void
		{
			addSystem( new TriggerHitSystem());
			addSystem(new ProximitySystem());
			
			super.addBaseSystems();
		}
	
		// all assets ready
		override public function loaded():void
		{
			
			shellApi.eventTriggered.add(handleEventTriggered);
			
			super.loaded();

			setupCharacters();
			setupLazyBear();
			setupRoomba();
			setupCabinet();
			setupCloset();
			setupGarbanzo();
			setupFloor();
		}
		
		private function handleEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == _events.USE_SCREWDRIVER){
				moveToRoomba();
			}
			else if(event == _events.USE_GARDEN_SHEARS){
				moveToCabinet();
			}
			else if(event == _events.USE_OFFICE_KEY){
				moveToCloset();
			}
			else if(event == "eat_key"){
				openLazyBear();
				//roombaEatKey();
			}
			else if(event == _events.CALL_TOTAL){
				useTreats();
			}
			else if(event == _events.USE_CAMERA || event == _events.USE_BOX || event == _events.USE_MARKER){				
				checkLazyBearParts(event);
			}
		}
		
		private function checkLazyBearParts(event:String):void
		{
			// assemble camera if all pieces found
			if(shellApi.checkEvent(_events.GOT_DETECTIVE_LOG_PAGE+"2")){
				if(shellApi.checkHasItem(_events.CAMERA) && shellApi.checkHasItem(_events.BOX) && shellApi.checkHasItem(_events.PERMANENT_MARKER)){
					positionForLazyBear();
				}else{
					Dialog(player.get(Dialog)).sayById("missing_pieces");
				}
			}
			else{
				partsComment(event);
			}
		}		
		
		private function partsComment(event:String):void
		{
			var dialog:Dialog = Dialog(player.get(Dialog));
			if(event == _events.USE_CAMERA){
				dialog.sayById("cant_use_camera");
			}
			else if(event == _events.USE_BOX){
				dialog.sayById("cant_use_box");
			}
			else if(event == _events.USE_MARKER){
				dialog.sayById("cant_use_marker");
			}	
		}
		
		private function positionForLazyBear():void
		{
			var p:Point = EntityUtils.getPosition(lazyBearCam);
			p.y += 100;
			CharUtils.moveToTarget(player, p.x, p.y,false, placeLazyBear, new Point(60,100)).validCharStates = new <String>[CharacterState.STAND];
		}
		
		private function placeLazyBear(...param):void
		{
			CharUtils.setState(player, CharacterState.STAND);
			var p:Point = EntityUtils.getPosition(lazyBearCam);
			p.y += 100;
			EntityUtils.position(player,p.x, p.y);
			CharUtils.stateDrivenOff(player);
			var falloffvac:ValidHit = new ValidHit("roombaPlat");
			falloffvac.inverse = true;
			player.add(falloffvac);
			
			var actions:ActionChain = new ActionChain(this);
			
			actions.lockInput = true;
			
			actions.addAction(new WaitAction(1.2));
			actions.addAction(new AnimationAction(player,Score)).noWait = true;
			actions.addAction(new WaitAction(0.2));
			actions.addAction(new AudioAction(lazyBearCam,OPEN_BOT_SOUND));
			actions.addAction(new CallFunctionAction(enableLazyBear));
			actions.addAction(new CallFunctionAction(Command.create(showLazyBear,"box")));
			actions.addAction(new TriggerEventAction(_events.PLACED_LAZY_BEAR,true));
			actions.addAction(new WaitAction(0.5));
			actions.addAction(new AnimationAction(player,Score)).noWait = true;
			actions.addAction(new WaitAction(0.2));
			actions.addAction(new AudioAction(lazyBearCam,OPEN_BOT_SOUND));
			actions.addAction(new CallFunctionAction(enableLazyBear));
			actions.addAction(new CallFunctionAction(Command.create(showLazyBear,"text")));
			actions.addAction(new TriggerEventAction(_events.PLACED_LAZY_BEAR,true));
			actions.addAction(new WaitAction(0.5));
			actions.addAction(new AnimationAction(player,Score)).noWait = true;
			actions.addAction(new WaitAction(0.2));
			actions.addAction(new AudioAction(lazyBearCam,OPEN_BOT_SOUND));
			actions.addAction(new CallFunctionAction(enableLazyBear));
			actions.addAction(new CallFunctionAction(Command.create(showLazyBear,"camera")));
			actions.addAction(new TriggerEventAction(_events.PLACED_LAZY_BEAR,true));
			actions.addAction(new WaitAction(0.5));
			actions.addAction(new CallFunctionAction(Command.create(player.remove, ValidHit))).noWait  = true;
			actions.addAction(new RemoveItemAction(_events.BOX, null, false)).noWait = true;
			actions.addAction(new RemoveItemAction(_events.CAMERA, null, false)).noWait = true;
			actions.addAction(new RemoveItemAction(_events.PERMANENT_MARKER, null, false)).noWait = true;

			actions.execute(timmyPage5);
		}
		
		private function enableLazyBear():void
		{
			Display(lazyBearCam.get(Display)).visible = true;
			// interaction to launch roomba key-eating video
			InteractionCreator.addToEntity(lazyBearCam,[InteractionCreator.CLICK]);
			ToolTipCreator.addToEntity(lazyBearCam);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.offsetY = 70;
			sceneInter.reached.add(openLazyBear);
			lazyBearCam.add(sceneInter);
		}
		
		private function showLazyBear(frame:String):void
		{
			var timeline:Timeline = lazyBearCam.get(Timeline);
			timeline.gotoAndStop(frame);
		}
		
		private function useTreats():void
		{
			this.callTotalOver();
		}
		
		private function beginFollow(...p):void
		{
			if(!shellApi.checkEvent(_events.GOT_DETECTIVE_LOG_PAGE+"2"))
			{
				Dialog(player.get(Dialog)).sayById("treats");
				timmyAtDoor();
			}
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(_total));
			this.removeEntity(totalclick);
		}
		
		private function timmyAtDoor(...p):void
		{
			var door:Entity = getEntityById("doorTimmysStreet");
			var inter:SceneInteraction = door.get(SceneInteraction);
			inter.reached.removeAll();
			// timmy be like... no
			inter.reached.addOnce(timmyPage2);
		}
		
		private function timmyPage2(...p):void
		{
			positionTotal(false);
			
			var falloffvac:ValidHit = new ValidHit("roombaPlat");
			falloffvac.inverse = true;
			player.add(falloffvac);
			
			SceneUtil.lockInput(this, true);
			OriginPoint(timmy.get(OriginPoint)).applyToSpatial(timmy.get(Spatial));
			var timmyPos:Point = EntityUtils.getPosition(timmy);
			var targ:Point = EntityUtils.getPosition(player);
			if(targ.x < timmyPos.x){
				targ.x += 180;
			}else{
				targ.x -= 180;
			}
			targ.y = timmyPos.y;
			
			var actions:ActionChain = new ActionChain(this);
			
			actions.lockInput = true;
			
			actions.addAction(new CallFunctionAction(showTimmy));
			actions.addAction(new WaitAction(0.4));
			actions.addAction(new PanAction(timmy));
			actions.addAction(new MoveAction(timmy, targ, new Point(60,100)));
			actions.addAction(new TalkAction(timmy, "fast"));
			actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,false)));
			actions.addAction(new TalkAction(player, "sitting"));
			actions.addAction(new TalkAction(timmy, "slack"));
			actions.addAction(new TalkAction(player, "how"));
			actions.addAction(new TalkAction(timmy, "lazy"));
			actions.addAction(new TriggerEventAction(_events.GOT_DETECTIVE_LOG_PAGE + '2', true));
			actions.addAction(new WaitAction(0.8));
			actions.addAction(new CallFunctionAction(Command.create(showDetectivePage,2)));
			timmyPos.x += 120;
			actions.addAction(new WaitAction(0.6));
			actions.addAction(new CallFunctionAction(Command.create(Display(timmy.get(Display)).moveToBack)));
			actions.addAction(new MoveAction(timmy, timmyPos, new Point(40,100)));
			actions.addAction(new CallFunctionAction(hideTimmy));
			actions.addAction(new PanAction(player));
			actions.addAction(new TalkAction(player, "where"));

			actions.execute(restoreDoor);
		}

		private function restoreDoor(...p):void
		{
			player.remove(ValidHit);
			var door:Entity = getEntityById("doorTimmysStreet");
			var inter:SceneInteraction = door.get(SceneInteraction);
			inter.reached.removeAll();
			inter.reached.add(openDoor);
		}
		
		private function openDoor(...p):void
		{
			var door:Door = getEntityById("doorTimmysStreet").get(Door);
			AudioUtils.play(this,SoundManager.EFFECTS_PATH + "door_knob_turn_open_01.mp3");
			shellApi.loadScene(TimmysStreet, door.data.destinationSceneX, door.data.destinationSceneY, door.data.destinationSceneDirection);
		}
		
		private function timmyPage5(...pa):void
		{
			positionTotal(false);
			
			OriginPoint(timmy.get(OriginPoint)).applyToSpatial(timmy.get(Spatial));
			var timmyPos:Point = EntityUtils.getPosition(timmy);
			var targ:Point = EntityUtils.getPosition(player);
			targ.x -= 180;
			targ.y = timmyPos.y;
			CharUtils.stateDrivenOn(player);

			var actions:ActionChain = new ActionChain(this);
			
			actions.lockInput = true;
			
			actions.addAction(new CallFunctionAction(showTimmy));
			actions.addAction(new WaitAction(0.4));
			actions.addAction(new PanAction(timmy));
			actions.addAction(new MoveAction(timmy, targ, new Point(60,100)));
			actions.addAction(new SetDirectionAction(player, false));
			actions.addAction(new TalkAction(timmy, "nice"));
			actions.addAction(new TalkAction(timmy, "lead"));
			actions.addAction(new TriggerEventAction(_events.GOT_DETECTIVE_LOG_PAGE + '5', true));
			actions.addAction(new WaitAction(0.8));
			actions.addAction(new CallFunctionAction(Command.create(showDetectivePage,5)));
			actions.addAction(new MoveAction(timmy,timmyPos));
			actions.addAction(new CallFunctionAction(hideTimmy));
			actions.addAction(new PanAction(player));
			
			actions.execute();
		}
		
		private function showTimmy(...p):void
		{
			Display(timmy.get(Display)).visible = true;
			Display(timmy.get(Display)).moveToFront();
			ToolTipCreator.addToEntity(timmy);
			var targ:Point = new Point(OriginPoint(timmy.get(OriginPoint)).x,OriginPoint(timmy.get(OriginPoint)).y);
			EntityUtils.position(timmy, targ.x, targ.y);
		}
		
		private function hideTimmy(...p):void
		{
			Display(timmy.get(Display)).visible = false;
			ToolTipCreator.removeFromEntity(timmy);
			EntityUtils.position(timmy, -200, OriginPoint(timmy.get(OriginPoint)).y);
		}
		
		private function openLazyBear(...p):void
		{
			if(shellApi.checkEvent(_events.KEY_EATEN) && shellApi.checkEvent(_events.MOLLYS_ONTO_YOU)){
				this.screenEffects.fadeToBlack(1.5, setupKeyEat);
			}else{
				Dialog(player.get(Dialog)).sayById("record");
			}
		}
		
		private function setupLazyBear():void
		{
			var clip:MovieClip = _hitContainer["lazyBearCam"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );				
			}
			lazyBearCam = EntityUtils.createMovingTimelineEntity( this, clip );
			setupBearOverlay();
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(lazyBearCam));
			if(shellApi.checkEvent(_events.PLACED_LAZY_BEAR)){
				enableLazyBear();
				Timeline(lazyBearCam.get(Timeline)).gotoAndStop("camera");
			}else{
				Display(lazyBearCam.get(Display)).visible = false;
			}
			
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(lazyBearOverlay));
			Display(EntityUtils.getDisplay(lazyBearOverlay)).disableMouse();
			Display(lazyBearOverlay.get(Display)).visible = false;
			
			key = EntityUtils.createSpatialEntity(this, _hitContainer["key"]);
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(key));
			Display(key.get(Display)).visible = false;
		}
		
		private function setupBearOverlay():void
		{
			this.addSystem(new VariableTimelineSystem());
			var clip:MovieClip = _hitContainer["lazyBearFrame"];
			clip.x = 0;//shellApi.viewportWidth * 0.5;
			clip.y = 0;//shellApi.viewportHeight * 0.5;
			clip.width = shellApi.viewportWidth;
			clip.height = shellApi.viewportHeight;
			overlayContainer.addChild(clip);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
			}
			lazyBearOverlay = EntityUtils.createMovingTimelineEntity(this, clip, overlayContainer, true, 26);
			lazyBearOverlay.add(new Sleep(false,true));
		}
		
		private function setupKeyEat(...p):void
		{
			lazyBearOverlay.get(Display).visible = true;
			if(_total){
				_total.get(Display).visible = false;
			}

			// make roomba active for camera view
			if(shellApi.checkEvent(_events.KEY_EATEN) && shellApi.checkEvent(_events.MOLLYS_ONTO_YOU)){
				roombaRunning();
			}
			SceneUtil.setCameraTarget(this, key);
			key.get(Display).visible = true;
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(roomba));
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(key));
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(closet));
			roombaPlat.remove(Motion);
			var spatial:Spatial = roombaPlat.get(Spatial);
			EntityUtils.position(roombaPlat, 1382, spatial.y);
			SceneUtil.lockInput(this, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(0.6,1,Command.create(this.screenEffects.fadeFromBlack,1.5,roombaEatKey)));
		}
		
		private function roombaEatKey(...p):void
		{			
			//position and slide in from left
			TweenUtils.entityTo(roombaPlat, Spatial, 2.5, {x:812, onComplete:breakOnKey}, "room", 1.2);
		}	
		
		private function breakOnKey(...p):void
		{
			Timeline(roomba.get(Timeline)).gotoAndPlay("broken");
			roomba.remove(Audio);
			roombaPlat.remove(Audio);
			AudioUtils.playSoundFromEntity(roomba, BREAK_SOUND, 700, 1);
			//TODO: shake, maybe some sparks/smoke
			key.get(Display).visible = false;
			roombaSad();
			roombaTimer = SceneUtil.addTimedEvent(this, new TimedEvent(4,0,roombaSad));
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5,1,Command.create(this.screenEffects.fadeToBlack, 1.0, returnFromCam)));
			shellApi.completeEvent(_events.WATCHED_LAZY_BEAR);
		}
		
		private function returnFromCam(...p):void
		{
			if(_total){
				_total.get(Display).visible = true;
			}
			SceneUtil.setCameraTarget(this, player);
			lazyBearOverlay.get(Display).visible = false;
			this.screenEffects.fadeFromBlack(1.0, returnToScene);
		}	
		
		private function returnToScene():void
		{
			SceneUtil.lockInput(this,false,false);
			CharUtils.stateDrivenOn(player);
			
			if(shellApi.checkEvent(_events.KEY_EATEN) && !shellApi.checkItemEvent(_events.OFFICE_KEY)){
				// roomba broken
				Dialog(player.get(Dialog)).sayById("key");
			}
			else{
				// roomba working
				roombaRunning();
			}
		}
		private function roombaRunning(...p):void
		{
			if(roombaTimer){
				roombaTimer.stop();
			}
			AudioUtils.playSoundFromEntity(roomba, VAC_SOUND, 500, 0.3, 1.2, null, true);
			Timeline(roomba.get(Timeline)).gotoAndPlay("left");
			roombaPlat.add(new Motion());
		}
		
		private function setupCharacters():void
		{
			// setup total
			_total = getEntityById("total");
			Display(_total.get(Display)).moveToFront();
			if(shellApi.checkEvent(_events.CHASE_COMPLETE)){
				Display(_total.get(Display)).visible = false;
			}
			else if(shellApi.checkEvent(_events.TOTAL_FOLLOWING)){ 
				var validHit:ValidHit = new ValidHit("roombaPlat");
				validHit.inverse = true;
				_total.add(validHit);
				DisplayUtils.moveToTop(EntityUtils.getDisplayObject(_total));
			}
			else if(!shellApi.checkEvent(_events.TOTAL_FOLLOWING) && !(shellApi.checkEvent(_events.FREED_ROLLO) && !shellApi.checkEvent(_events.FREED_TOTAL))){
				// bear returns to house if not following
				
				ToolTipCreator.addToEntity( _total );
				shellApi.completeEvent(_events.TOTAL_IN_HOUSE);
				Display(_total.get(Display)).visible = true;
				this.totalReset();
				if(!shellApi.checkItemEvent(_events.CRISPY_RICE_TREATS)){
					var timeline:Timeline = _total.get(Timeline);
					timeline.gotoAndPlay("look_up");
				}
				
				var tInter:Interaction = _total.get(Interaction);
				var sInter:SceneInteraction = new SceneInteraction();
				sInter.reached.add(totalComment);
				var displayObject:MovieClip 							=	Display( _total.get( Display )).displayObject as MovieClip;
				displayObject.mouseChildren 							=	true;
				displayObject.mouseEnabled								=	true;
				
				_total.add( sInter );
			}
			else{
				Display(_total.get(Display)).visible = false;
			}
			
			timmy = getEntityById("timmy");
			timmy.add(new OriginPoint(timmy.get(Spatial).x,timmy.get(Spatial).y));
			Display(timmy.get(Display)).visible = false;
			timmy.get(Spatial).x = -200;

			var display:Display 									=	timmy.get( Display );
			display.displayObject[ "shorts" ].alpha = 0;
			display.displayObject[ "shirt_garbage" ].alpha = 0;
			display.displayObject[ "head_garbage" ].alpha = 0;
			
			ToolTipCreator.removeFromEntity(timmy);
			
			var phone:Entity = getEntityById("phoneInteraction");
			var inter:SceneInteraction = phone.get(SceneInteraction);
			inter.reached.add(noPhone);
		}
		
		private function noPhone(...p):void
		{
			Dialog(player.get(Dialog)).sayById("phone");
		}
		
		private function totalComment(...p):void
		{
			if(shellApi.checkEvent(_events.TOTAL_FOLLOWING)){
				Dialog(player.get(Dialog)).sayById("treats");
			}
			else if(shellApi.checkItemEvent(_events.CRISPY_RICE_TREATS)){
				Dialog(player.get(Dialog)).sayById("total2");
			}
			else{
				Dialog(player.get(Dialog)).sayById("total");
			}
		}
		
		private function setupRoomba():void
		{
			this.addSystem(new VariableTimelineSystem());
			// moves back and forth on carpet, has click, eats key when scene is viewed with lazy bear camera.
			roombaPlat = getEntityById("roombaPlat");
			Display(roombaPlat.get(Display)).disableMouse();
			Display(roombaPlat.get(Display)).visible = false;
			var clip:MovieClip 		=	_hitContainer[ "roomba" ];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
			}
			roomba = EntityUtils.createMovingTimelineEntity(this, clip, null, true, 26);
			Timeline(roomba.get(Timeline)).gotoAndPlay("left");
			roomba.add(new FollowTarget(roombaPlat.get(Spatial)));
			var moving:MovingHitData = roombaPlat.get(MovingHitData);
			moving.reachedPoint.add(flip);
			flip();
			
			var inter:Interaction = InteractionCreator.addToEntity(roomba,[InteractionCreator.CLICK]);
			ToolTipCreator.addToEntity(roomba);
			inter.click.add(roombaComment);
			
			if(shellApi.checkEvent(_events.KEY_EATEN) && shellApi.checkEvent(_events.MOLLYS_ONTO_YOU) && !shellApi.checkItemEvent(_events.OFFICE_KEY)){
				// fail sound every few seconds
				roombaPlat.remove(Motion);
				roombaPlat.get(Spatial).x += 160;
				roombaTimer = SceneUtil.addTimedEvent(this, new TimedEvent(4,0,roombaSad));
				Timeline(roomba.get(Timeline)).gotoAndPlay("broken");
			}else{
				AudioUtils.playSoundFromEntity(roomba, VAC_SOUND, 500, 0.3, 1.2, null, true);
			}
			roomba.add(new Sleep(false,true));
			roombaPlat.add(new Sleep(false,true));
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(roomba));
		}
		
		private function roombaSad(...p):void
		{
			AudioUtils.playSoundFromEntity(roomba, SAD_BEEP_SOUND, 700, 0.3, 1.2);
		}
		
		private function moveToRoomba():void
		{
			if(!shellApi.checkItemEvent(_events.OFFICE_KEY)){
				var room:Point = EntityUtils.getPosition(roomba);
				CharUtils.moveToTarget(player, room.x, room.y, false, prepOpenRoomba, new Point(60,100)).validCharStates = new <String>[CharacterState.STAND];
			}else{
				Dialog(player.get(Dialog)).sayById("screwdriver");
			}
		}
		
		private function prepOpenRoomba( ...p ):void
		{
			var onLeft:Boolean = Spatial( roomba.get( Spatial )).x > Spatial( player.get( Spatial )).x ? true : false;
			CharUtils.setDirection( player, onLeft );
			super.positionTotal( onLeft, openRoomba );
		}
		
		private function openRoomba(...p):void
		{	
			CharUtils.setState(player, CharacterState.STAND);
			var dial:Dialog = Dialog(player.get(Dialog));
			if(shellApi.checkEvent(_events.WATCHED_LAZY_BEAR)){
				if(roombaTimer){
					roombaTimer.stop();
				}
				if(shellApi.checkEvent(_events.KEY_EATEN) && shellApi.checkEvent(_events.MOLLYS_ONTO_YOU)){
					// equip screwdriver, bend down, aquire key, fix roomba
					var actions:ActionChain = new ActionChain(this);
					actions.lockInput = true;
					
					actions.addAction(new SetSkinAction(player,SkinUtils.ITEM,"tf_screwdriver",false,true));
					actions.addAction(new AnimationAction(player, Place));
					actions.addAction(new AudioAction(roomba, OPEN_BOT_SOUND, 700, 0.6, 1.2));
					actions.addAction(new GetItemAction(_events.OFFICE_KEY));
					actions.addAction(new WaitAction(0.4));
					actions.addAction(new AudioAction(roomba, HAPPY_BEEP_SOUND, 700, 0.3, 1.2));
					actions.addAction(new CallFunctionAction(roombaRunning));
					actions.addAction(new CallFunctionAction(Command.create(roombaPlat.add,new Motion())));
					actions.addAction(new WaitAction(0.6));
					actions.addAction(new SetSkinAction(player, SkinUtils.ITEM, "empty", true, true));
					
					actions.execute();
				}
				else{
					dial.sayById("screwdriver");
				}
			}else{
				dial.sayById("screwdriver2");
			}
		}
		
		private function roombaComment(...p):void
		{
			var dial:Dialog = Dialog(player.get(Dialog));
			if(shellApi.checkEvent(_events.KEY_EATEN) && shellApi.checkEvent(_events.MOLLYS_ONTO_YOU) && !shellApi.checkItemEvent(_events.OFFICE_KEY)){
				if(shellApi.checkEvent(_events.WATCHED_LAZY_BEAR)){
					dial.sayById("key_inside");
				}else{
					dial.sayById("roomba_broken");
				}
			}
			else{
				dial.sayById("amazing");
			}
		}
		
		// flip roomba x 
		private function flip(...p):void
		{
			var displ:Display = roomba.get(Display);
			var spat:Spatial = roomba.get(Spatial);
			var motion:Motion = roombaPlat.get(Motion);
			spat.scaleX *= -1;
			if(spat.scaleX > 0){
				Timeline(roomba.get(Timeline)).gotoAndPlay("right");
			}
			else{
				Timeline(roomba.get(Timeline)).gotoAndPlay("left");
			}
		}
		
		
		private function setupCabinet():void
		{	
			var clip:MovieClip 			=	_hitContainer[ "cabinet" ];
			
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
			}
			cabinet = EntityUtils.createMovingTimelineEntity(this, clip, null, true);
			if(!shellApi.checkItemEvent(_events.CRISPY_RICE_TREATS) && !shellApi.checkEvent(_events.UNLOCKED_CABINET)){
				treats = EntityUtils.createSpatialEntity(this, _hitContainer["treats"]);
				InteractionCreator.addToEntity(cabinet,[InteractionCreator.CLICK]);
				var sceneInter:SceneInteraction = new SceneInteraction();
				sceneInter.offsetY = 60;
				sceneInter.reached.add(lockComment);
				sceneInter.ignorePlatformTarget = false;
				cabinet.add(sceneInter);
				ToolTipCreator.addToEntity(cabinet);
				Display(treats.get(Display)).visible = false;
			}
			else if(shellApi.checkEvent(_events.UNLOCKED_CABINET) && !shellApi.checkItemEvent(_events.CRISPY_RICE_TREATS)){
				treats = EntityUtils.createSpatialEntity(this, _hitContainer["treats"]);
				Display(treats.get(Display)).visible = true;
				Timeline(cabinet.get(Timeline)).gotoAndStop("opened");
				Display(cabinet.get(Display)).disableMouse();
				enableTreatsItem();
				timmyAtDoor();
			}
			else{
				if(shellApi.checkItemEvent(_events.CRISPY_RICE_TREATS) && !shellApi.checkEvent(_events.GOT_DETECTIVE_LOG_PAGE+"2")){
					timmyAtDoor();
				}
				Timeline(cabinet.get(Timeline)).gotoAndStop("opened");
				_hitContainer.removeChild(_hitContainer["treats"]);
				Display(cabinet.get(Display)).disableMouse();
			}
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(cabinet));
			if(treats){
				DisplayUtils.moveToBack(EntityUtils.getDisplayObject(treats));
			}
		}
		
		private function lockComment(...p):void
		{
			Dialog(player.get(Dialog)).sayById("locked");
		}
		
		
		private function moveToCabinet():void
		{
			if(!shellApi.checkItemEvent(_events.CRISPY_RICE_TREATS)){
				var CAB:Point = EntityUtils.getPosition(cabinet);
				CAB.x += 30;
				CAB.y -= 20;
				CharUtils.moveToTarget( player, CAB.x, CAB.y, false, openCabinet, new Point( 60,60 )).validCharStates = new <String>[CharacterState.STAND];
			}else{
				Dialog(player.get(Dialog)).sayById("shears");
			}
		}
		
		private function checkIslandBlock(...args):void
		{
			CharUtils.setState(player, CharacterState.STAND);
			/*if(IslandBlockPopup.checkIslandBlock(this.shellApi))
			{
				this.addChildGroup(new IslandBlockPopup("scenes/timmy/", this.overlayContainer));
			}
			else
			{*/
				openCabinet();
			//}
		}
		
		private function openCabinet(...p):void
		{
			CharUtils.setState(player, CharacterState.STAND);
			showTreats();
			SceneUtil.lockInput(this, true, true);
			var CAB:Point = EntityUtils.getPosition(cabinet);
			CAB.x += 30;
			CAB.y += 30;
			CharUtils.stateDrivenOff(player);
			var actions:ActionChain = new ActionChain(this);
			
			actions.lockInput = true;
			actions.lockPosition = true;
			
			actions.addAction(new WaitAction(0.6));
			actions.addAction(new CallFunctionAction(Command.create(EntityUtils.position,player,CAB.x,CAB.y)));
			actions.addAction(new WaitAction(0.6));
			actions.addAction(new SetSkinAction(player,SkinUtils.ITEM,"tf_shears", false));
			actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection, player, false)));
			actions.addAction(new AnimationAction(player, PointItem, "pointing", 0, false));
			actions.addAction(new TimelineAction(SkinUtils.getSkinPartEntity(player,SkinUtils.ITEM),"chop","cut", false));
			actions.addAction(new AudioAction(roomba, CUT_SOUND, 0, 0, 1.2));
			actions.addAction(new TimelineAction(cabinet, "open"));
			actions.addAction(new WaitAction(1.0));
			actions.addAction(new SetSkinAction(player, SkinUtils.ITEM, "empty", true));
			actions.addAction(new TriggerEventAction(_events.UNLOCKED_CABINET,true));
			actions.addAction(new TalkAction(player,"treats_found"));
			actions.addAction(new CallFunctionAction(getTreats));
			actions.addAction(new TimelineAction(_total,"dance")).noWait = true;
			actions.addAction(new WaitAction(1.0));
			actions.addAction(new TimelineAction(_total,"stand")).noWait = true;
			actions.addAction(new CallFunctionAction(autoTreatTotal));
			
			actions.execute();
		}
		
		private function autoTreatTotal():void
		{
			cabinet.remove(Interaction);
			cabinet.remove(SceneInteraction);
			ToolTipCreator.removeFromEntity(cabinet);
			ToolTipCreator.removeFromEntity( _total );
			_total.remove( SceneInteraction );
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "crispy_rice_treats", true, callTotal);
		}
		
		private function callTotal(...p):void
		{
			this.callTotalOver();
			SceneUtil.delay(this, 2.0, beginFollow);
		}
		
		private function showTreats():void
		{
			Display(treats.get(Display)).visible = true;
		}
		
		private function enableTreatsItem():void
		{
			CharUtils.stateDrivenOn(player);
			cabinet.remove(Interaction);
			cabinet.remove(SceneInteraction);
			ToolTipCreator.removeFromEntity(cabinet);
			var inter:Interaction = InteractionCreator.addToEntity(treats,[InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.minTargetDelta = new Point(30, 50);
			treats.add(sceneInter);
			ToolTipCreator.addToEntity(treats);
			var prox:Proximity = new Proximity(140,player.get(Spatial));
			prox.entered.addOnce(getTreats);
			treats.add(prox);
		}
		
		private function getTreats(...p):void
		{
			if(treats){
				removeEntity(treats,true);
			}
			shellApi.getItem(_events.CRISPY_RICE_TREATS,null,true);
		}
		
		private function setupCloset():void
		{
			var clip:MovieClip 				=	_hitContainer["closet"];
			
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
			}
			closet = EntityUtils.createMovingTimelineEntity(this, clip, null, true);
			if(!shellApi.checkItemEvent(_events.SHOES) && !shellApi.checkEvent(_events.OPENED_OFFICE)){
				shoes = EntityUtils.createSpatialEntity(this, _hitContainer["shoes"]);
				Display(shoes.get(Display)).visible = false;
				InteractionCreator.addToEntity(closet,[InteractionCreator.CLICK]);
				var sceneInter:SceneInteraction = new SceneInteraction();
				sceneInter.offsetY = 50;
				sceneInter.reached.add(lockComment2);
				closet.add(sceneInter);
				ToolTipCreator.addToEntity(closet);
			}
			else if(shellApi.checkEvent(_events.OPENED_OFFICE) && !shellApi.checkItemEvent(_events.SHOES)){
				shoes = EntityUtils.createSpatialEntity(this, _hitContainer["shoes"]);
				Timeline(closet.get(Timeline)).gotoAndStop("opened");
				Display(closet.get(Display)).disableMouse();
				enableShoesItem();
			}
			else{
				Timeline(closet.get(Timeline)).gotoAndStop("opened");
				_hitContainer.removeChild(_hitContainer["shoes"]);
				Display(closet.get(Display)).disableMouse();
			}
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(closet));
			if(shoes){
				DisplayUtils.moveToBack(EntityUtils.getDisplayObject(shoes));
			}
		}
		
		private function lockComment2(...p):void
		{
			Dialog(player.get(Dialog)).sayById("locked2");
		}
		
		private function moveToCloset():void
		{
			if(!shellApi.checkItemEvent(_events.SHOES)){
				var clos:Point = EntityUtils.getPosition(closet);
				clos.y -= 20;
				clos.x -= 20;
				CharUtils.moveToTarget(player, clos.x, clos.y, false, prepOpenCloset, new Point(60,100)).validCharStates = new <String>[CharacterState.STAND];
				var falloffvac:ValidHit = new ValidHit("roombaPlat");
				falloffvac.inverse = true;
				player.add(falloffvac);
			}
		}
		
		// move total out of the way
		private function prepOpenCloset(...p):void
		{
			positionTotal( true, openCloset );
		}
		
		private function openCloset(...p):void
		{
			CharUtils.setState(player, CharacterState.STAND);
			showShoes();
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			actions.addAction(new CallFunctionAction(Command.create(EntityUtils.position,player, 1720, 742)));
			actions.addAction(new WaitAction(0.25));
			actions.addAction(new SetDirectionAction(player, true));
			actions.addAction(new WaitAction(0.25));
			actions.addAction(new RemoveItemAction(_events.OFFICE_KEY,"closet")).noWait = true;
 			actions.addAction(new AnimationAction(player, PointItem));
			actions.addAction(new AudioAction(closet, UNLOCK_SOUND, 700, 0.6, 1.2));
			actions.addAction(new TimelineAction(closet,"open")).noWait = true;
			actions.addAction(new WaitAction(1.0));
			actions.addAction(new TriggerEventAction(_events.OPENED_OFFICE,true));
			actions.addAction(new TalkAction(player,"shoes_found"));
			actions.addAction(new CallFunctionAction(getShoes));
			actions.addAction(new CallFunctionAction(Command.create(player.remove,ValidHit)));

			actions.execute();
		}
		
		private function showShoes():void
		{		
			Display(shoes.get(Display)).moveToBack();
			Display(shoes.get(Display)).visible = true;
		}
		
		private function enableShoesItem():void
		{
			Display(shoes.get(Display)).visible = true;
			closet.remove(Interaction);
			closet.remove(SceneInteraction);
			ToolTipCreator.removeFromEntity(closet);
			var inter:Interaction = InteractionCreator.addToEntity(shoes,[InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			shoes.add(sceneInter);
			ToolTipCreator.addToEntity(shoes);
			var prox:Proximity = new Proximity(140,player.get(Spatial));
			prox.entered.addOnce(getShoes);
			shoes.add(prox);
		}
		
		private function getShoes(...p):void
		{
			removeEntity(shoes,true);
			shellApi.getItem(_events.SHOES, null, true);
		}
		
		private function setupGarbanzo():void
		{
			var clip:MovieClip 					=	_hitContainer[ "garbanzo" ];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
			}
			garbanzo = EntityUtils.createMovingTimelineEntity(this, clip, null, true);

			if(!shellApi.checkEvent(_events.GARBANZO_DROPPED)){
				// "we jumped out a windoooow"		
				var inter:Interaction = InteractionCreator.addToEntity(garbanzo,[InteractionCreator.CLICK]);
				var sceneInter:SceneInteraction = new SceneInteraction();
				sceneInter.offsetY += 120;
				garbanzo.add(sceneInter);
				ToolTipCreator.addToEntity(garbanzo);
				sceneInter.reached.add(reachedGarbanzo);
			}else{
				Timeline(garbanzo.get(Timeline)).gotoAndStop("gone");
				garbanzo.remove(SceneInteraction);
				//sceneInter.reached.add(openGarbanzoDoor);
			}
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(garbanzo));
		}
		
		private function reachedGarbanzo(...p):void
		{
			//if(!shellApi.checkEvent(_events.GOT_DETECTIVE_LOG_PAGE +"4")){
				//Dialog(player.get(Dialog)).sayById("what");
			//}else{	
				SceneInteraction(garbanzo.get(SceneInteraction)).reached.remove(reachedGarbanzo);
				dropGarbanzo();
			//}
		}
		
		private function openGarbanzoDoor(...p):void
		{
			var door:Door = getEntityById("doorTimmysStreet").get(Door);
			shellApi.loadScene(TimmysStreet, door.data.destinationSceneX-200, door.data.destinationSceneY-450, door.data.destinationSceneDirection);
		}
		
		private function dropGarbanzo(...p):void
		{
			CharUtils.setAnim(player, Score);
			var garb:Spatial = garbanzo.get(Spatial);
			// drop out window, somehow...
			SceneUtil.lockInput(this,true);
			var tl:Timeline = Timeline(garbanzo.get(Timeline));
			// SOUND
			AudioUtils.play(this, DROP_SOUND, 1.2);
			tl.gotoAndPlay("fall");
			tl.handleLabel("gone",whoopsDelay);
			ToolTipCreator.removeFromEntity(garbanzo);
		}		
		
		private function whoopsDelay(...p):void
		{
			AudioUtils.play(this, SMASH_SOUND, 1);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.0,1,whoops));
		}
		
		private function whoops(...p):void
		{
			shellApi.completeEvent(_events.GARBANZO_DROPPED);
			Dialog(player.get(Dialog)).sayById("whoops");
			SceneUtil.lockInput(this,false);
			garbanzo.remove(SceneInteraction);
			//sceneInter.reached.removeAll();
			//sceneInter.reached.add(openGarbanzoDoor);
		}		
		
		// ADDED 9-14-2015 to make player always appear correctly placed in regards to Total
		private function setupFloor():void
		{	
			addTriggerHit( getEntityById( "floor_carpet" ), layerAboveTotal );
			addTriggerHit( getEntityById( "floor" ), layerAboveTotal );
			addTriggerHit( getEntityById( "roombaPlat" ), layerUnderTotal );
			addTriggerHit( getEntityById( "counter" ), layerUnderTotal );
			addTriggerHit( getEntityById( "carpet" ), layerUnderTotal );
		}
		
		private function addTriggerHit( hitEntity:Entity, handler:Function ):void
		{
			var triggerHit:TriggerHit 						=	new TriggerHit( null, new <String>[ "player" ]);
			triggerHit.triggered 							=	new Signal();
			triggerHit.offTriggered							=	new Signal();
			triggerHit.triggered.add( handler );
			
			hitEntity.add( triggerHit );
		}		
		
		private function layerAboveTotal():void
		{
			DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, Display( _total.get( Display )).displayObject, true );
		}
		
		private function layerUnderTotal():void
		{
			DisplayUtils.moveToOverUnder( Display( player.get( Display )).displayObject, Display( _total.get( Display )).displayObject, false );
		}
		
		
		override protected function totalFollow():void
		{
			ToolTipCreator.removeFromEntity( _total );
			_total.remove( SceneInteraction );
			
			var displayObject:MovieClip 							=	Display( _total.get( Display )).displayObject as MovieClip;
			displayObject.mouseChildren 							=	false;
			displayObject.mouseEnabled								=	false;
			
			super.totalFollow();
		}
	}
}