package game.scenes.ftue.outro
{
	import com.greensock.easing.Cubic;
	import com.greensock.easing.Elastic;
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
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
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.motion.FollowTarget;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.components.ui.Cursor;
	import game.components.ui.ToolTip;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Celebrate;
	import game.data.animation.entity.character.Disco;
	import game.data.animation.entity.character.Drink;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.Fall;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Throw;
	import game.data.animation.entity.character.Tremble;
	import game.data.animation.entity.character.poptropolis.ShotputAnim;
	import game.data.comm.PopResponse;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MovingHitData;
	import game.data.ui.ToolTipType;
	import game.scenes.ftue.AceRaceScene;
	import game.scenes.ftue.outro.components.Fokker;
	import game.scenes.ftue.outro.groups.FokkerBombGroup;
	import game.scenes.hub.town.Town;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class Outro extends AceRaceScene
	{
		public function Outro()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/ftue/outro/";
			
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
			// freeze player controls
			SceneUtil.lockInput(this);
			
			// add wrench to inventory if not present
			if(!shellApi.checkHasItem(ftue.WRENCH)){
				shellApi.getItem(ftue.WRENCH);
			}
			
			intro();
		}
		
		override protected function setupEntities():void
		{
			super.setupEntities();
			
			_blimp = EntityUtils.createMovingEntity(this, _hitContainer["blimp"], _hitContainer);
			MotionUtils.addWaveMotion(_blimp, new WaveMotionData("y", 15, 0.02, "sin", 1), this);
			MotionUtils.addWaveMotion(_blimp, new WaveMotionData("x", 8, 0.008, "sin", 1), this);
			
			// optimize
			convertContainer(Display(_blimp.get(Display)).displayObject);
			
			_hammock_back = EntityUtils.createMovingEntity(this, _hitContainer["hammock_back"]);
			MotionUtils.addWaveMotion(_hammock_back, new WaveMotionData("y", 15, 0.02, "sin", 1), this);
			MotionUtils.addWaveMotion(_hammock_back, new WaveMotionData("x", 8, 0.008, "sin", 1), this);
			
			var followTarget:FollowTarget = new FollowTarget(_blimp.get(Spatial), 1);
			_hammock_back.add(followTarget);
			
			_leftFlag = TimelineUtils.convertClip(_hitContainer["balloon"]["flag_left"], this);
			_rightFlag = TimelineUtils.convertClip(_hitContainer["balloon"]["flag_right"], this);
			
			_drinkBounce = TimelineUtils.convertClip(_hitContainer["airplane_b"]["drinkBounce"], this);
			
			characterInPlane(this.player, _blimp, "player", "right", new Spatial(40, 0));
			
			_pilot = characterInPlane(this.getEntityById("pilot"), _blimp, "pilot", "right", new Spatial(-30, 0));
			
			_crusoe = characterInPlane(this.getEntityById("crusoe"), _blimp, "crusoe", "right", new Spatial(0, 137));
			Display(_crusoe.get(Display)).visible = false;
			
			EntityUtils.removeInteraction(_crusoe);
			EntityUtils.removeInteraction(_pilot);
			
			var interaction:Interaction = InteractionCreator.addToEntity(_pilot, [InteractionCreator.DOWN]);
			interaction.down.add(pilotStatement);
			ToolTipCreator.addToEntity(_pilot);
			
			_camPoint = EntityUtils.createSpatialEntity();
			
			// get ballasts ready
			_ballast1 = ButtonCreator.createButtonEntity(_hitContainer["blimp"]["ballast1"], this, onBallast, null, null, ToolTipType.CLICK, false);
			_ballast2 = ButtonCreator.createButtonEntity(_hitContainer["blimp"]["ballast2"], this, onBallast, null, null, ToolTipType.CLICK, false);
			_ballast3 = ButtonCreator.createButtonEntity(_hitContainer["blimp"]["ballast3"], this, onBallast, null, null, ToolTipType.CLICK, false);
			_ballast4 = ButtonCreator.createButtonEntity(_hitContainer["blimp"]["ballast4"], this, onBallast, null, null, ToolTipType.CLICK, false);
			_ballast5 = ButtonCreator.createButtonEntity(_hitContainer["blimp"]["ballast5"], this, onBallast, null, null, ToolTipType.CLICK, false);
			
			// enable mouseChildren on blimp
			DisplayObjectContainer(_hitContainer["blimp"]).mouseEnabled = true;
			DisplayObjectContainer(_hitContainer["blimp"]).mouseChildren = true;
			
			_hammock = TimelineUtils.convertClip(_hitContainer["blimp"]["hammock"], this);
			
			_airplaneB.add(new Fokker()); // add _airplaneB componenet for mini-games
			
			_junk1 = EntityUtils.createSpatialEntity(this, _hitContainer["junk1"], _hitContainer);
			Display(_junk1.get(Display)).visible = false;
			
			_junk2 = EntityUtils.createSpatialEntity(this, _hitContainer["junk2"], _hitContainer);
			Display(_junk2.get(Display)).visible = false;
			
			_junk3 = EntityUtils.createSpatialEntity(this, _hitContainer["junk3"], _hitContainer);
			Display(_junk3.get(Display)).visible = false;
			
			_goggles = EntityUtils.createSpatialEntity(this, _hitContainer["goggles"], _hitContainer);
			Display(_goggles.get(Display)).visible = false;
			
			_drink = EntityUtils.createSpatialEntity(this, _hitContainer["drink"], _hitContainer);
			Display(_drink.get(Display)).visible = false;
			
			// create _blimp moving hit
			// add movieclip platform for player run on
			var hitCreator:HitCreator = new HitCreator();
			hitCreator.showHits = true;
			
			var movingHitData:MovingHitData = new MovingHitData();
			
			_blimpHit = hitCreator.createHit(super._hitContainer["blimpHit"], HitType.MOVING_PLATFORM, movingHitData, this);
			MotionUtils.addWaveMotion(_blimpHit, new WaveMotionData("y", 15, 0.02, "sin", 1), this);
			MotionUtils.addWaveMotion(_blimpHit, new WaveMotionData("x", 8, 0.008, "sin", 1), this);
		}
		
		private function pilotStatement(...p):void
		{
			Dialog(_pilot.get(Dialog)).sayById("catchingup");
		}
		
		override protected function initAnimations():void{
			_charGroup.preloadAnimations(new <Class>[
				Celebrate,
				Disco,
				Drink,
				DuckDown,
				Fall,
				Grief,
				Laugh,
				Place,
				Proud,
				Score,
				Sit,
				Stand,
				Throw,
				Tremble,
				ShotputAnim
			], this);
		}
		
		private function initSounds():void
		{
			// preload sounds
			AudioUtils.playSoundFromEntity(_airplaneB, PROP_SOUND, 1000, 0, 1.5, null, true);
		}
		
		private function intro():void
		{
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new CallFunctionAction( enter_blimp ) );
			actChain.addAction( new WaitAction(3.7) );
			actChain.addAction( new CallFunctionAction( panCameraTo_baron ) );
			actChain.addAction( new WaitAction(3) );
			actChain.addAction( new CallFunctionAction( resetCamera ) );
			actChain.addAction( new TalkAction(_pilot, "intro1") );
			actChain.addAction( new TalkAction(_pilot, "intro1b") );
			actChain.addAction( new CallFunctionAction( readyBallasts ) );
			actChain.addAction( new CallFunctionAction( helpBallast ) );
			
			actChain.execute();
		}
		
		
		private function enter_blimp():void{
			shellApi.completeEvent(ftue.RE_ENTERED_RACE);
			shellApi.track(ftue.RE_ENTERED_RACE);
			TweenUtils.entityTo(_blimp, Spatial, 5, {x:shellApi.camera.viewportWidth / 2, y:shellApi.viewportHeight/2 + 50, ease:Cubic.easeOut});
		}
		
		private function panCameraTo_baron():void{
			var spatial:Spatial = _airplaneB.get(Spatial);
			SceneUtil.setCameraTarget(this, _airplaneB, false, 0.05);
		}
		
		private function resetCamera():void{
			// lock onto blimp
			SceneUtil.setCameraTarget(this, _blimp, false, 0.05);
		}
		
		private function readyBallasts():void{
			SceneUtil.lockInput(this, false);
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;  // change default cursor
			swayBallasts();
		}
		
		private function helpBallast():void{
			_reminderTimer = SceneUtil.addTimedEvent(this, new TimedEvent(10, 0, remindBallast));
		}
		
		private function remindBallast():void{
			// amelia says something
			Dialog(_pilot.get(Dialog)).sayById("dropweight");
			swayBallasts();
		}
		
		private function swayBallasts(...p):void{
			for(var c:int = 1; c <= 5; c++){
				var entity:Entity = this.getEntityById("ballast"+c);
				var swayAmount:Number = (Math.random()*2)+2;
				if(entity)
					TweenUtils.entityTo(entity, Spatial, swayAmount * 0.1, {rotation:-swayAmount, ease:Cubic.easeInOut, onComplete:completeSway, onCompleteParams:[entity,swayAmount]});
			}
		}
		
		private function completeSway(entity:Entity, swayAmount:Number):void{
			TweenUtils.entityTo(entity, Spatial, swayAmount, {rotation:0, ease:Elastic.easeOut});
		}
		
		private function onBallast(ballast:Entity):void
		{
			if(_ballastReady){
				AudioUtils.play(this, DROP_BAG);
				
				// stop ballastHelp timer
				if(_reminderTimer){
					_reminderTimer.stop();
					_reminderTimer = null;
				}
				
				// remove interaction from entity
				ballast.remove(Interaction);
				ballast.remove(ToolTip);
				TweenUtils.entityTo(ballast, Spatial, 1, {y:Spatial(ballast.get(Spatial)).y + 500, ease:Cubic.easeIn, delay:1, onComplete:destroyBallast});
				
				CharUtils.setDirection(player, false);
				CharUtils.setAnim(player, Place, false, 0, 0, true);
				
				if(_bagsRemoved == 0){
					shellApi.completeEvent(ftue.DROPPED_BALLAST);
					shellApi.track(ftue.DROPPED_BALLAST);
					Dialog(_pilot.get(Dialog)).allowOverwrite = true;
					Dialog(_pilot.get(Dialog)).sayById("thatsit");
				}
				
				_bagsRemoved++;
				
				if(_bagsRemoved < 5){
					moveForward();
				} else {
					raiseBlimp();
				}
				_ballastReady = false;
			}
			
			function destroyBallast():void{
				ballast.group.removeEntity(ballast);
			}
		}
		
		private function moveForward():void{
			var soundString:String = (Math.random() > 0.5) ? WIND_SPEED_1 : WIND_SPEED_2;
			//AudioUtils.play(this, soundString);
			
			SceneUtil.lockInput(this);
			TweenUtils.entityTo(_blimp, Spatial, 3, {x:(shellApi.camera.viewportWidth / 2)+(_bagsRemoved*300), y:420, ease:Cubic.easeInOut, onComplete:readyAgain});
		}
		
		private function readyAgain():void{
			swayBallasts();
			_ballastReady = true;
			CharUtils.setAnim(player, Stand);
			if(_bagsRemoved < 4){
				SceneUtil.lockInput(this, false);
				Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;  // change default cursor
			} else if(_bagsRemoved == 4){
				SceneUtil.lockInput(this, false);
				shellApi.completeEvent(ftue.CAUGHT_UP_BARON);
				shellApi.track(ftue.CAUGHT_UP_BARON);
			}
		}
		
		private function caughtUpToBaron():void
		{
			shellApi.completeEvent(ftue.CAUGHT_UP_BARON);
			shellApi.track(ftue.CAUGHT_UP_BARON);
			
			// move camera between baron and player
			var spatial:Spatial = _blimp.get(Spatial);
			SceneUtil.setCameraPoint(this, spatial.x+150, spatial.y, false, 0.1);
			
			CharUtils.setDirection(player, true);
			
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new TalkAction(baron, "intro2") );
			actChain.addAction( new CallFunctionAction( baron_hitBreaks ) );
			actChain.addAction( new WaitAction(0.8) );
			actChain.addAction( new CallFunctionAction( blimp_bump ) );
			actChain.addAction( new WaitAction(0.2) );
			actChain.addAction( new CallFunctionAction( Command.create(CharUtils.setDirection, _pilot, true) ) );
			actChain.addAction( new CallFunctionAction( playerFallOut ) );
			actChain.addAction( new WaitAction(0.6) );
			actChain.addAction( new CallFunctionAction( blimp_dive ) );
			actChain.addAction( new TalkAction(baron, "intro3") );
			actChain.addAction( new CallFunctionAction( baron_returnToLead ) );
			actChain.addAction( new WaitAction(2) );
			actChain.addAction( new CallFunctionAction( Command.create(CharUtils.setDirection, player, true) ) );
			actChain.addAction( new CallFunctionAction( rescuePlayer ) );
			actChain.addAction( new WaitAction(3) );
			actChain.addAction( new TalkAction(_pilot, "caught") )
			actChain.addAction( new CallFunctionAction( blimp_positionBehindBaron ) );
			actChain.addAction( new WaitAction(2) );
			actChain.addAction( new AnimationAction(player, Stand, "", 30) );
			actChain.addAction( new TalkAction(player, "stopus1") );
			actChain.addAction( new TalkAction(baron, "stopus2") );
			actChain.addAction( new CallFunctionAction( game_readyAvoidBaron ) );
			actChain.addAction( new WaitAction(0.8) );
			actChain.addAction( new CallFunctionAction( camera_panBack ) );
			actChain.addAction( new WaitAction(2.2) );
			actChain.addAction( new CallFunctionAction( game_avoidBaron ) );
			
			actChain.execute();
		}
		
		private function baron_hitBreaks():void{
			var spatial:Spatial = _blimp.get(Spatial);
			TweenUtils.entityTo(_airplaneB, Spatial, 1.5, {x:spatial.x+310, y:spatial.y, ease:Cubic.easeInOut});
		}
		
		private function blimp_bump():void{
			AudioUtils.play(this, HIT);
			var spatial:Spatial = _blimp.get(Spatial);
			TweenUtils.entityTo(_blimp, Spatial, 2, {x:spatial.x - 20, y:spatial.y + 20, ease:Elastic.easeOut});
		}
		
		private function playerFallOut():void{
			var spatial:Spatial = _blimp.get(Spatial);
			
			CharUtils.setAnim(_pilot, Grief);
			CharUtils.setAnim(player, Fall);
			player.remove(FollowTarget);
			TweenUtils.entityTo(player, Spatial, 1.4, {y:spatial.y + 800, ease:Cubic.easeIn});
			CharUtils.setAnim(baron, Laugh, false);
			TweenUtils.entityTo(_camPoint, Spatial, 3, {x:spatial.x - 400, ease:Cubic.easeInOut})
			
		}
		
		private function blimp_dive():void{
			var spatial:Spatial = _blimp.get(Spatial);
			TweenUtils.entityTo(_blimp, Spatial, 3, {x:spatial.x - 400, y:spatial.y + 1500, ease:Cubic.easeIn, delay:2});
		}
		
		private function baron_returnToLead():void{
			CharUtils.setDirection(baron, true);
			var spatial:Spatial = _airplaneB.get(Spatial);
			TweenUtils.entityTo(_airplaneB, Spatial, 3, {x:spatial.x+190, ease:Cubic.easeInOut, delay:1});
		}
		
		private function rescuePlayer():void{
			//Motion(player.get(Motion)).acceleration.y = 0;
			SceneUtil.setCameraPoint(this, shellApi.camera.viewportWidth / 2+800, 420);
			CharUtils.setAnim(player, DuckDown);
			characterInPlane(this.player, _blimp, "player", "right", new Spatial(0, -482), false);
			TweenUtils.entityTo(_blimp, Spatial, 4, {x:shellApi.camera.viewportWidth / 2+800, y:700, ease:Cubic.easeOut});
			
			// move player on top of _blimp display object
			DisplayUtils.moveToTop(Display(player.get(Display)).displayObject);
		}
		
		private function blimp_positionBehindBaron():void{
			SceneUtil.setCameraPoint(this, shellApi.camera.viewportWidth / 2+1350, 420, false, 0.05);
			TweenUtils.entityTo(_blimp, Spatial, 3, {x:shellApi.camera.viewportWidth / 2+1200, y:900, ease:Cubic.easeInOut});
		}
		
		private function game_readyAvoidBaron():void
		{
			shellApi.completeEvent(ftue.CHALLENGED_BARON);
			shellApi.track(ftue.CHALLENGED_BARON);
			CharUtils.setAnim(player, DuckDown);
			DisplayObjectContainer(_hitContainer["blimp"]).mouseEnabled = false;
			DisplayObjectContainer(_hitContainer["blimp"]).mouseChildren = false;
			TweenUtils.entityTo(_blimp, Spatial, 3, {x:shellApi.camera.viewportWidth / 2+800, y:shellApi.camera.viewportHeight+400, ease:Cubic.easeInOut});
			TweenUtils.entityTo(_airplaneB, Spatial, 2.7, {x:shellApi.camera.viewportWidth / 2+800, y:shellApi.camera.viewportHeight / 2.5, ease:Cubic.easeInOut});
		}
		
		private function camera_panBack():void{
			SceneUtil.setCameraPoint(this, shellApi.camera.viewportWidth / 2+800, 420, false, 0.02);
		}
		
		private function game_avoidBaron():void
		{
			var followTarget:FollowTarget = new FollowTarget((_blimp.get(Spatial)));
			followTarget.offset = new Point(0, -415);
			_blimpHit.add(followTarget);
			
			// add control back to player
			player.remove(WaveMotion);
			player.remove(FollowTarget);
			var point:Point = DisplayUtils.localToLocal(EntityUtils.getDisplayObject(player), _hitContainer);
			var spatial:Spatial = player.get(Spatial);
			Display(player.get(Display)).setContainer(_hitContainer);
			spatial.x = point.x;
			spatial.y = point.y;
			
			_charGroup.addFSM(player);
			
			spatial = _blimp.get(Spatial);
			SceneUtil.setCameraPoint(this, spatial.x, 420, false, 0.1); // move camera in position
			
			// add _airplaneB bomb group
			this.addChildGroup(new FokkerBombGroup());
			
			SceneUtil.lockInput(this, false);
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.NAVIGATION_ARROW; // this is not working
		}
		
		public function firstMiss():void{
			//Dialog(player.get(Dialog)).sayById("miss");
		}
		
		public function catchPlayer():void{
			// put player in basket
			player_inBasket(false);
			
			// center blimp
			Spatial(_blimp.get(Spatial)).x = shellApi.camera.viewportWidth / 2+800;
			
			// raise blimp
			TweenUtils.entityTo(_blimp, Spatial, 4, {y:420, ease:Cubic.easeInOut, onComplete:playerCaught});
		}
		
		public function endGame():void{
			// wait for player to land on _blimp -- then stick player to _blimp
			var fsmControl:FSMControl = player.get(FSMControl);
			fsmControl.stateChange = new Signal(String, Entity);
			if(fsmControl.state.type == "stand" || fsmControl.state.type == "duck"){
				blimp_raise();
			} else {
				fsmControl.stateChange.add(onPlayerStateChange);
			}
		}
		
		private function onPlayerStateChange(type:String, entity:Entity):void
		{
			if(type == "stand" || type == "duck"){
				blimp_raise();
			}
		}
		
		private function blimp_raise():void{
			// lock controls
			SceneUtil.lockInput(this);
			
			// remove _blimp hit
			this.removeEntity(_blimpHit);
			
			// stick player to _blimp at current position
			var bSpatial:Spatial = _blimp.get(Spatial);
			
			var pSpatial:Spatial = player.get(Spatial);
			var oSpatial:Spatial = new Spatial(pSpatial.x - bSpatial.x, pSpatial.y - bSpatial.y);
			
			// sync up wave motion
			//var radians1:Number = WaveMotionData(WaveMotion(_pilot.get(WaveMotion)).data[0]).radians;
			//var radians2:Number = WaveMotionData(WaveMotion(_pilot.get(WaveMotion)).data[1]).radians;
			//MotionUtils.addWaveMotion(player, new WaveMotionData("y", 15, 0.02, "sin", radians1), this);
			//MotionUtils.addWaveMotion(player, new WaveMotionData("x", 8, 0.008, "sin", radians2), this);
			
			characterInPlane(player, _blimp, "player", "right", oSpatial, false, false);
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(player));
			
			//_charGroup.removeFSM(player);
			//MotionUtils.zeroMotion(player);
			
			// raise blimp
			TweenUtils.entityTo(_blimp, Spatial, 4, {y:420, ease:Cubic.easeInOut});
			
			hopDown();
			
		}
		
		private function hopDown():void{
			// play if player has dodged baron successfully
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new WaitAction(3) );
			actChain.addAction( new CallFunctionAction( player_hopDown ) );
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new CallFunctionAction( player_inBasket ) );
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new CallFunctionAction( catchUp ) );
			actChain.addAction( new WaitAction(3) );
			actChain.addAction( new CallFunctionAction( helpBallast ) );
			actChain.addAction( new TalkAction(_pilot, "reveal2") );
			actChain.addAction( new CallFunctionAction( Command.create(SceneUtil.lockInput, this, false) ) );
			
			actChain.execute();
		}
		
		private function playerCaught():void{
			// play if player falls and was caught
			SceneUtil.setCameraTarget(this, blimp);
			
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new TalkAction(player, "caught1") );
			actChain.addAction( new TalkAction(_pilot, "caught2") );
			actChain.addAction( new CallFunctionAction( catchUp ) );
			actChain.addAction( new WaitAction(3) );
			actChain.addAction( new CallFunctionAction( helpBallast ) );
			actChain.addAction( new TalkAction(_pilot, "reveal2") );
			actChain.addAction( new CallFunctionAction( Command.create(SceneUtil.lockInput, this, false) ) );
			
			actChain.execute();
		}
		
		private function player_hopDown():void
		{
			Spatial(player.get(Spatial)).x = 40;
			CharUtils.setAnim(player, Fall);
			TweenUtils.entityTo(player, Spatial, 1, {x:40, y:0, ease:Cubic.easeIn});
		}
		
		private function player_inBasket(camera:Boolean = true):void{
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;
			
			// reset eyes to default
			SkinUtils.setEyeStates(player);
			
			AudioUtils.play(this, LAND_BASKET);
			
			var spatial:Spatial = _blimp.get(Spatial);
			
			// sync up wave motion - once again
			//var radians1:Number = WaveMotionData(WaveMotion(_pilot.get(WaveMotion)).data[0]).radians;
			//var radians2:Number = WaveMotionData(WaveMotion(_pilot.get(WaveMotion)).data[1]).radians;
			//MotionUtils.addWaveMotion(player, new WaveMotionData("y", 15, 0.02, "sin", radians1), this);
			//MotionUtils.addWaveMotion(player, new WaveMotionData("x", 8, 0.008, "sin", radians2), this);
			
			characterInPlane(this.player, _blimp, "player", "right", new Spatial(40, 0));
			TweenUtils.entityTo(_blimp, Spatial, 1, {y:spatial.y+10, ease:Elastic.easeOut});
			
			if(camera)SceneUtil.setCameraTarget(this, _blimp);
			
			DisplayObjectContainer(_hitContainer["blimp"]).mouseEnabled = true;
			DisplayObjectContainer(_hitContainer["blimp"]).mouseChildren = true;
		}
		
		
		private function catchUp():void
		{
			CharUtils.setDirection(player, true);
			CharUtils.setDirection(_pilot, true);
			TweenUtils.entityTo(_blimp, Spatial, 4, {x:shellApi.camera.viewportWidth / 2+1300, ease:Cubic.easeInOut} );
		}
		
		private function raiseBlimp():void{
			EntityUtils.removeAllWordBalloons(this,_pilot);
			
			// player say something
			
			var actChain:ActionChain = new ActionChain(this);
			SceneUtil.lockInput(this);
			actChain.addAction( new WaitAction(3) );
			
			var spatial:Spatial = _airplaneB.get(Spatial);
			TweenUtils.entityTo(_airplaneB, Spatial, 2.7, {x:spatial.x+130, y:spatial.y+330, ease:Cubic.easeInOut});
			// raise blimp
			TweenUtils.entityTo(_blimp, Spatial, 3, {x:(shellApi.camera.viewportWidth / 2)+1700, y:420, ease:Cubic.easeInOut} );
			
			SceneUtil.setCameraPoint(this, shellApi.camera.viewportWidth / 2+1600, 420, false, 0.1);
			actChain.execute(readyCrusoe);
		}
		
		private function readyCrusoe(...p):void{
			
			SceneUtil.lockInput(this, false);
			
			Dialog(_pilot.get(Dialog)).sayById("hammock");
			
			CharUtils.setDirection(baron, true);
			
			// baron starts to tremble
			CharUtils.setAnim(baron, Tremble);
			
			// set hammock as button to reveal crusoe
			ButtonCreator.assignButtonEntity(_hammock, _hitContainer["blimp"]["hammock"], this, revealCrusoe, null, null, ToolTipType.CLICK);
			
			// animate hammock
			Timeline(_hammock.get(Timeline)).gotoAndPlay("wiggles");
			
			// release controls
			SceneUtil.lockInput(this, false);
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;
			
			// remind hammock
			_reminderTimer = SceneUtil.addTimedEvent(this, new TimedEvent(10, 0, remindHammock));
		}
		
		private function remindHammock():void{
			Dialog(_pilot.get(Dialog)).sayById("hammock");
		}
		
		private function revealCrusoe(...p):void
		{
			shellApi.completeEvent(ftue.REVEALED_CRUSOE);
			shellApi.track(ftue.REVEALED_CRUSOE);
			_hammock.remove(Interaction);
			_hammock.remove(ToolTip);
			
			Dialog(_pilot.get(Dialog)).say("");
			if(_reminderTimer){
				_reminderTimer.stop();
				_reminderTimer = null;
			}
			
			Timeline(_hammock.get(Timeline)).gotoAndPlay("coverOff");
			
			AudioUtils.play(this, UNCOVER_HAMMOCK);
			
			SceneUtil.lockInput(this);
			
			Display(_crusoe.get(Display)).visible = true;
			
			jumpInPlane();
		}
		
		private function proud():void{
			CharUtils.setAnim(_crusoe, Proud);
		}
		
		private function drink():void{
			CharUtils.setAnim(_crusoe, Drink);
		}
		
		private function throwGoggles():void{
			AudioUtils.play(this, THROW);
			
			// remove overshirt item part
			SkinUtils.setSkinPart(_pilot, SkinUtils.OVERSHIRT, "empty", true);
			
			var wSpatial:Spatial = _goggles.get(Spatial);
			var pSpatial:Spatial = _pilot.get(Spatial);
			
			wSpatial.x = pSpatial.x;
			wSpatial.y = pSpatial.y - 30;
			
			Display(_goggles.get(Display)).visible = true;
			
			var motion:Motion = new Motion();
			motion.acceleration = new Point(0,300);
			motion.velocity = new Point(-800,0);
			motion.rotationVelocity = 30;
			
			_goggles.add(motion);
			
			// move blimp forward a bit more
			TweenUtils.entityTo(_blimp, Spatial, 1, {x:(shellApi.camera.viewportWidth / 2)+(_bagsRemoved*300)+50, ease:Cubic.easeInOut});
			//TweenUtils.entityTo(_blimp, Spatial, 2, {x:(shellApi.camera.viewportWidth / 2)+(_bagsRemoved*300)+150, ease:Cubic.easeInOut});
		}
		
		private function readyToThrow():void{
			_readyToThrow = true;
		}
		
		private function helpWrench():void{
			_reminderTimer = SceneUtil.addTimedEvent(this, new TimedEvent(10, 0, remindWrench));
		}
		
		private function remindWrench():void{
			// amelia says something
			Dialog(_pilot.get(Dialog)).sayById("checkinv");
			// flash ballasts
		}
		
		private function useWrench():void{
			if(_readyToThrow){
				// stop amelia's dialog
				Dialog(_pilot.get(Dialog)).say("");
				if(_reminderTimer){
					_reminderTimer.stop();
					_reminderTimer = null;
				}
				
				throwWrench();
			}
		}
		
		public function throwWrench():void{
			shellApi.completeEvent(ftue.THREW_WRENCH);
			shellApi.track(ftue.THREW_WRENCH);
			shellApi.removeItem(ftue.WRENCH);
			
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "wrench", false);
			
			SceneUtil.lockInput(this);
			CharUtils.setAnim(player, ShotputAnim);
			CharUtils.getTimeline( player ).gotoAndPlay("start");
			Timeline(CharUtils.getTimeline(player)).handleLabel("launch", wrenchThrown);
		}
		
		private function wrenchThrown(...p):void{
			AudioUtils.play(this, THROW);
			TweenUtils.entityTo(_blimp, Spatial, 1, {x:(shellApi.camera.viewportWidth / 2)+(_bagsRemoved*300)+150, ease:Cubic.easeInOut, onComplete:finale});
			
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "empty", false);
			
			_wrench.remove(Motion);
			
			var wSpatial:Spatial = _wrench.get(Spatial);
			var pSpatial:Spatial = player.get(Spatial);
			var bSpatial:Spatial = blimp.get(Spatial);
			
			wSpatial.x = pSpatial.x+bSpatial.x;
			wSpatial.y = pSpatial.y+bSpatial.y;
			
			Display(_wrench.get(Display)).visible = true;
			
			var motion:Motion = new Motion();
			motion.acceleration = new Point(0,600);
			motion.velocity = new Point(200,200);
			motion.rotationVelocity = 120;
			
			_wrench.add(motion);
		}
		
		private function finale(...p):void{
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new CallFunctionAction( fokkerDodge ) );
			actChain.addAction( new CallFunctionAction( lowerBlimp ) );
			actChain.addAction( new TalkAction(baron, "wrench") );
			actChain.addAction( new CallFunctionAction( Command.create(CharUtils.setDirection, baron, true) ) );
			actChain.addAction( new CallFunctionAction( Command.create(CharUtils.setDirection, player, false) ) );
			actChain.addAction( new TalkAction(player, "heavy2") );
			actChain.addAction( new AnimationAction(_crusoe, Drink, "", 120));
			actChain.addAction( new TalkAction(_pilot, "heavy3") );
			actChain.addAction( new TalkAction(_crusoe, "heavy4") );
			actChain.addAction( new TalkAction(_pilot, "talkSense") );
			actChain.addAction( new CallFunctionAction( talkSense) );
			//actChain.addAction( new CallFunctionAction( helpTalk) );
			
			actChain.execute();
		}
		
		private function fokkerDodge():void{
			// lower fokker to appear it's dodging it
			var spatial:Spatial = _airplaneB.get(Spatial);
			TweenUtils.entityTo(_airplaneB, Spatial, 3, {x:spatial.x - 20, y:spatial.y + 100, ease:Elastic.easeOut} );
		}
		
		private function lowerBlimp():void{
			// lower blimp closer to fokker
			var spatial:Spatial = _blimp.get(Spatial);
			TweenUtils.entityTo(_blimp, Spatial, 4, {y:spatial.y + 130, ease:Cubic.easeInOut} );
		}
		
		private function talkSense():void{
			shellApi.completeEvent(ftue.TALK_TO_CRUSOE);
			shellApi.track(ftue.TALK_TO_CRUSOE);
			
			// replace crusoe's interaction with speech bubbles
			
			Display(_blimp.get(Display)).displayObject.mouseEnabled = false;
			Display(_blimp.get(Display)).displayObject.mouseChildren = false;
			
			Cursor(super.shellApi.inputEntity.get(Cursor)).defaultType = ToolTipType.ARROW;
			
			openCrusoeDialog();
		}
		
		private function helpTalk():void{
			_reminderTimer = SceneUtil.addTimedEvent(this, new TimedEvent(10, 0, remindTalk));
		}
		
		private function remindTalk():void{
			// amelia says something
			Dialog(_pilot.get(Dialog)).sayById("talkSense2");
		}
		
		public function openCrusoeDialog(...p):void{
			SceneUtil.lockInput(this, false);
			if(_reminderTimer){
				_reminderTimer.stop();
				_reminderTimer = null;
			}
			Dialog(shellApi.player.get(Dialog)).sayById("stillheavy");
			Dialog(player.get(Dialog)).start.add(lockDialog);
		}
		
		private function lockDialog(data:DialogData):void{
			SceneUtil.lockInput(this);
		}
		
		public function tossDrink():void{
			SceneUtil.lockInput(this);
			_crusoe.remove(Interaction);
			
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new TalkAction(player, "reveal3") );
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new TalkAction(_crusoe, "reveal5") );
			actChain.addAction( new AnimationAction(_crusoe, Place, "", 120) );
			actChain.addAction( new CallFunctionAction( pickupDrink ));
			actChain.addAction( new CallFunctionAction( Command.create(CharUtils.setDirection, _crusoe, true) ) );
			actChain.addAction( new AnimationAction(_crusoe, Drink, "", 60) );
			actChain.addAction( new CallFunctionAction( damageFokker ) );
			actChain.addAction( new CallFunctionAction( puffFokker ) );
			actChain.addAction( new TalkAction(_crusoe, "woops1") );
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new TalkAction(baron, "woops2") );
			actChain.addAction( new TalkAction(_crusoe, "woops3") );
			actChain.addAction( new CallFunctionAction( damageFokker ) );
			actChain.addAction( new CallFunctionAction( smokeFokker ) );
			actChain.addAction( new AnimationAction(_crusoe, Drink, "", 60) );
			actChain.addAction( new TalkAction(baron, "woops4") );
			actChain.addAction( new CallFunctionAction( goingDown ) );
			actChain.addAction( new WaitAction(5) );
			actChain.addAction( new CallFunctionAction( settleBlimp ) );
			actChain.addAction( new TalkAction(_pilot, "win1") );
			actChain.addAction( new CallFunctionAction( pilotsSit ) );
			actChain.addAction( new TalkAction(player, "win2") );
			actChain.addAction( new CallFunctionAction( crossFinishLine ) );
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new CallFunctionAction( celebrate ) );
			actChain.addAction( new WaitAction(6) );
			actChain.addAction( new CallFunctionAction( endScene ) );
			actChain.execute();
			
		}
		
		private function throwDrinkToPlayer():void
		{
			CharUtils.setAnim(_crusoe, ShotputAnim);
			CharUtils.getTimeline( _crusoe ).gotoAndPlay("start");
			Timeline(CharUtils.getTimeline(_crusoe)).handleLabel("launch", drinkFlyToPlayer);
		}
		
		private function drinkFlyToPlayer():void{
			AudioUtils.play(this, THROW);
			var cSpatial:Spatial = _crusoe.get(Spatial);
			var pSpatial:Spatial = player.get(Spatial);
			var dSpatial:Spatial = _drink.get(Spatial);
			var bSpatial:Spatial = blimp.get(Spatial);
			
			// remove drink item from Crusoe
			SkinUtils.setSkinPart(_crusoe, SkinUtils.ITEM, "empty", false);
			
			// show drink
			Display(_drink.get(Display)).visible = true;
			dSpatial.x = cSpatial.x + bSpatial.x;
			dSpatial.y = cSpatial.y + bSpatial.y;
			
			// tween drink to fly to player (2 seconds)
			TweenUtils.entityTo(_drink, Spatial, 0.6, {x:pSpatial.x+10+bSpatial.x, y:pSpatial.y-40+ bSpatial.y, rotation:500, ease:Linear.easeOut});
		}
		
		private function drinkInPlayersHand():void{
			// drink dissappears
			Display(_drink.get(Display)).visible = false;
			
			// put drink in player's item slot
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "ftue_drink", false);
		}
		
		private function throwDrinkOut():void{
			shellApi.completeEvent(ftue.THREW_DRINK);
			shellApi.track(ftue.THREW_DRINK);
			CharUtils.setAnim(player, ShotputAnim);
			CharUtils.getTimeline( player ).gotoAndPlay("start");
			Timeline(CharUtils.getTimeline(player)).handleLabel("launch", drinkFlyToPlane);
		}
		
		private function drinkFlyToPlane():void{
			AudioUtils.play(this, THROW);
			
			var pSpatial:Spatial = player.get(Spatial);
			var tSpatial:Spatial = _airplaneB.get(Spatial);
			var dSpatial:Spatial = _drink.get(Spatial);
			var bSpatial:Spatial = blimp.get(Spatial);
			
			// remove drink from player's hand
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "empty", false);
			
			// show drink
			Display(_drink.get(Display)).visible = true;
			dSpatial.x = pSpatial.x + bSpatial.x;
			dSpatial.y = pSpatial.y + bSpatial.y;
			
			// tween drink to fly to plane
			TweenUtils.entityTo(_drink, Spatial, 0.4, {x:tSpatial.x-10, y:tSpatial.y - 110, ease:Linear.easeNone, onComplete:drinkLandInPlane});
		}
		
		private function drinkLandInPlane():void{
			AudioUtils.play(this, IMPACT_PLANE);
			
			Display(_drink.get(Display)).visible = false;
			var timeline:Timeline = _drinkBounce.get(Timeline);
			timeline.play();
		}
		
		private function inchLastBit():void{
			TweenUtils.entityTo(_blimp, Spatial, 1, {x:(shellApi.camera.viewportWidth / 2)+(_bagsRemoved*300)+200, ease:Cubic.easeInOut});
			//TweenUtils.entityTo(_blimp, Spatial, 2, {x:(shellApi.camera.viewportWidth / 2)+(_bagsRemoved*300)+250, ease:Cubic.easeInOut});
		}
		
		private function jumpInPlane():void{
			
			var spatial:Spatial = _airplaneB.get(Spatial);
			
			_crusoe.remove(FollowTarget);
			
			var point:Point = DisplayUtils.localToLocal(EntityUtils.getDisplayObject(_crusoe), _hitContainer);
			var crusoeSpatial:Spatial = _crusoe.get(Spatial);
			crusoeSpatial.x = point.x;
			crusoeSpatial.y = point.y;
			var display:Display = _crusoe.get(Display);
			display.setContainer(_hitContainer);
			display.moveToBack();
			
			CharUtils.setAnim(_crusoe, Fall);
			TweenUtils.entityTo(_crusoe, Spatial, 0.4, {x:spatial.x - 80, y:spatial.y, ease:Linear.easeNone, onComplete:landInPlane});
			
			Display(_hammock.get(Display)).visible = false;
			Display(_hammock_back.get(Display)).visible = false;
		}
		
		private function landInPlane():void{
			
			AudioUtils.play(this, LAND_PLANE);
			
			characterInPlane(_crusoe, _airplaneB, "crusoeInFokker", "right", new Spatial(-80,0));
			
			TweenUtils.entityTo(_blimp, Spatial, 3, {x:shellApi.camera.viewportWidth / 2+1740, y:280, ease:Cubic.easeInOut} );
			
			var followTarget:FollowTarget = new FollowTarget(_airplaneB.get(Spatial));
			followTarget.offset = new Point(213,38);
			_explosion.add(followTarget);
			
			tossDrink();
		}
		
		private function pickupDrink():void{
			// put drink in crusoe's item part
			SkinUtils.setSkinPart(_crusoe, SkinUtils.ITEM, "ftue_drink", false);
		}
		
		private function damageFokker():void{
			var spatial:Spatial = _airplaneB.get(Spatial);
			TweenUtils.entityTo(_airplaneB, Spatial, 2, {x:spatial.x - 40, y:spatial.y + 20, ease:Elastic.easeOut} );
			Timeline(_explosion.get(Timeline)).gotoAndPlay(1);
		}
		
		private function puffFokker():void{
			AudioUtils.play(this, ZAP);
			_smokeParticles.stream();
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, _smokeParticles.stopStream));
		}
		
		private function smokeFokker():void{
			AudioUtils.play(this, DAMAGE_PLANE);
			_airplaneB.remove(Audio);
			AudioUtils.playSoundFromEntity(_airplaneB, PROP_SOUND_BROKE, 1000, 0, 1, null, true);
			_smokeParticles.stream();
			CharUtils.setAnim(baron, Grief);
		}
		
		private function goingDown():void{
			CharUtils.setDirection(baron, true);
			CharUtils.setAnim(baron, Tremble);
			Dialog(_crusoe.get(Dialog)).sayById("woops5");
			var spatial:Spatial = _airplaneB.get(Spatial);
			TweenUtils.entityTo(_airplaneB, Spatial, 5, {x:spatial.x - 100, y:shellApi.camera.viewportHeight + 300, ease:Cubic.easeInOut});
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, stopSmoke));
		}
		
		private function stopSmoke(...p):void{
			_smokeParticles.stopStream();
			_airplaneB.remove(Audio);
		}
		
		private function settleBlimp():void{
			// change music
			shellApi.triggerEvent("winRace"); // change music
			
			var spatial:Spatial = _blimp.get(Spatial);
			SceneUtil.setCameraPoint(this, spatial.x, 420, false, 0.01);
			TweenUtils.entityTo(_blimp, Spatial, 4, {y:420, ease:Cubic.easeInOut});
		}
		
		private function pilotsSit():void{
			CharUtils.setAnim(player, Sit);
			CharUtils.setAnim(_pilot, Sit);
		}
		
		private function crossFinishLine():void{
			shellApi.completeEvent(ftue.FINISHED_RACE);
			shellApi.track(ftue.FINISHED_RACE);
			AudioUtils.play(this, COMPLETE_RACE_HORN);
			// balloon with checker flag comes in
			Display(_balloon.get(Display)).visible = true;
			Display(_officiate.get(Display)).visible = true;
			TweenUtils.entityTo(_balloon, Spatial, 3, {x:Spatial(_blimp.get(Spatial)).x - 330, ease:Cubic.easeOut, onComplete:officiateFaceBlimp});		}
		
		private function celebrate():void{
			// pilot and player cheering in loop
			CharUtils.setAnimSequence(player, new <Class>[Score, Disco]);
			CharUtils.setAnimSequence(_pilot, new <Class>[Score, Disco]);
			AudioUtils.play(this, CHEERING);
			// confetti particles
			// _confetti.stream();
		}
		
		private function officiateFaceBlimp():void{
			CharUtils.setDirection(_officiate, true);
			Dialog(_officiate.get(Dialog)).sayById("winner");
		}
		
		public function endScene():void{
			this.shellApi.completeEvent("show_ftue_ending", "hub");
			shellApi.getItem(ftue.MEDAL);
			shellApi.completedIsland('', loadIntoTown);	
		}
		
		private function loadIntoTown(response:PopResponse):void
		{
			shellApi.loadScene(Town);
		}
		
		override public function onEventTriggered(event:String=null, makeCurrent:Boolean=false, init:Boolean=false, removeEvent:String=null):void
		{
			switch(event){
				case "tossDrink":
					tossDrink();
					break;
				case "talkSense":
					openCrusoeDialog();
					break;
				case ftue.USE+ftue.WRENCH:
					useWrench();
					break;
			}
		}
		
		private const HIT:String = SoundManager.EFFECTS_PATH + "whack_02.mp3";
		private const UNCOVER_HAMMOCK:String = SoundManager.EFFECTS_PATH + "whoosh_09.mp3";
		private const PROP_SOUND:String = SoundManager.EFFECTS_PATH + "Plane_L_loop_01_loop.mp3";
		private const PROP_SOUND_BROKE:String = SoundManager.EFFECTS_PATH + "Plane_H_loop_01_loop.mp3";
		private const LAND_PLANE:String = SoundManager.EFFECTS_PATH + "ls_car_hood_02.mp3";
		private const LAND_BASKET:String = SoundManager.EFFECTS_PATH + "whack_03.mp3";
		private const IMPACT_PLANE:String = SoundManager.EFFECTS_PATH + "machine_impact_06.mp3";
		private const THROW:String = SoundManager.EFFECTS_PATH + "whoosh_08.mp3";
		private const DROP_BAG:String = SoundManager.EFFECTS_PATH + "scissor_cut_01.mp3";
		private const ZAP:String = SoundManager.EFFECTS_PATH + "electrical_impact_01.mp3";
		private const DAMAGE_PLANE:String = SoundManager.EFFECTS_PATH + "small_explosion_02.mp3";
		//private const ENGINE_DOWN:String = SoundManager.EFFECTS_PATH + "turn_engine_off_01.mp3";
		private const COMPLETE_RACE_HORN:String = SoundManager.EFFECTS_PATH + "victoryFanfare.mp3";
		private const CHEERING:String = SoundManager.EFFECTS_PATH + "CrowdCheer_01.mp3";
		private const WIND_SPEED_1:String = SoundManager.EFFECTS_PATH + "winter_wind_gust_01.mp3";
		private const WIND_SPEED_2:String = SoundManager.EFFECTS_PATH + "winter_wind_gust_02.mp3";
		
		private var _junk1:Entity;
		private var _junk2:Entity;
		private var _junk3:Entity;
		private var _drink:Entity;
		private var _goggles:Entity;
		
		private var playersWaveMotion:WaveMotion;
		
		private var _crusoe:Entity;
		
		private var _leftFlag:Entity;
		private var _rightFlag:Entity;
		
		private var _reminderTimer:TimedEvent;
		
		private var _blimpHit:Entity;
		
		private var _ballast1:Entity;
		private var _ballast2:Entity;
		private var _ballast3:Entity;
		private var _ballast4:Entity;
		private var _ballast5:Entity;
		private var _hammock:Entity;
		
		private var _bagsRemoved:int = 0;
		private var _camPoint:Entity;
		
		private var _sipDrinkTimer:TimedEvent;
		private var _readyToThrow:Boolean;
		private var _drinkBounce:Entity;
		private var _hammock_back:Entity;
		private var _ballastReady:Boolean = true;
		
		public function get blimpHit():Entity{return _blimpHit;}
		public function get blimp():Entity{return _blimp;}
		public function get fokker():Entity{return _airplaneB;}
		public function get junk1():Entity{ return _junk1 };
		public function get junk2():Entity{ return _junk2 };
		public function get junk3():Entity{ return _junk3 };
	}
}