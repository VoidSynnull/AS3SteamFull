package game.scenes.prison.roof3
{
	import com.greensock.easing.Sine;
	import com.poptropica.AppConfig;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Hide;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.ValidHit;
	import game.components.hit.Zone;
	import game.components.motion.Destination;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionTarget;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Tremble;
	import game.data.animation.entity.character.Walk;
	import game.data.animation.entity.character.WalkNinja;
	import game.data.sound.SoundModifier;
	import game.scenes.prison.PrisonScene;
	import game.scenes.prison.escape.Escape;
	import game.scenes.prison.yard.components.Seagull;
	import game.scenes.prison.yard.states.SeagullBeginFlightState;
	import game.scenes.prison.yard.states.SeagullFlyState;
	import game.scenes.prison.yard.states.SeagullIdleState;
	import game.scenes.prison.yard.states.SeagullLandState;
	import game.scenes.prison.yard.states.SeagullSittingAngryState;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.EventAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.SetDirectionAction;
	import game.systems.actionChain.actions.SetSpatialAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TweenEntityAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.DetectionSystem;
	import game.systems.entity.character.clipChar.MovieclipState;
	import game.systems.motion.WaveMotionSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class Roof3 extends PrisonScene
	{
		public function Roof3()
		{
			super();
			this.mergeFiles = true;
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/prison/roof3/";
			
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
			
			setupGuard();
			setupLights();
			setupBucket();
			setupHideZones(3);
			getEntityById("endZone").get(Zone).entered.addOnce(showEscape);	
			setupBird();
		}
		
		private function setupGuard():void
		{
			player.add(new ValidHit("concrete", "wood", "baseGround", "wall"));
			
			// Setup the actual guard
			var building:Bitmap = this.createBitmap(_hitContainer["mainBuilding"]);	
			_guard = getEntityById("guard");	
			var displayObj:DisplayObject = EntityUtils.getDisplayObject(_guard);
			DisplayUtils.moveToBack(displayObj);
			EntityUtils.removeInteraction(_guard);
			
			var black:ColorTransform = new ColorTransform(1,1,1,0,0,0);
			black.color = 0x0F1121;
			displayObj.transform.colorTransform = black;			
			
			var lightEntity:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["flashlight"]);
			_lightFollow = new FollowTarget(_guard.get(Spatial));
			_lightFollow.offset = new Point(0, -40);
			lightEntity.add(_lightFollow);
			
			CharUtils.setAnim(_guard, Walk);
			var righAnim:RigAnimation = CharUtils.getRigAnim(_guard, 1);
			if(righAnim == null)
			{
				var animSlot:Entity = AnimationSlotCreator.create(_guard);
				righAnim = animSlot.get(RigAnimation) as RigAnimation;
			}
			
			righAnim.next = WalkNinja;
			righAnim.addParts(CharUtils.HAND_BACK, CharUtils.ARM_BACK);			
			switchGuardDirection();
			
			// setup the zones
			for(var i:uint = 1; i <= 4; i++)
			{
				var zone:Zone = getEntityById("guardZone" + i).get(Zone);
				zone.entered.add(enteredGuardZone);
				zone.exitted.add(exittedGuardZone);
			}
		}
		
		private function setupLights():void
		{			
			setupRoofLight("light1", 30, 5, 880, 90);
			setupRoofLight("light2", 28, 5, 900, 100);
			_endLight = EntityUtils.createMovingEntity(this, _hitContainer["light3"]);
			
			player.add(new Hide());
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new DetectionSystem(), SystemPriorities.resolveCollisions);			
		}
		
		private function setupBucket():void
		{
			var bucketEntity:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["bucketAnim"]);
			BitmapTimelineCreator.convertToBitmapTimeline(bucketEntity, null, true, null, PerformanceUtils.defaultBitmapQuality);						
			bucketEntity.add(new Audio());
			bucketEntity.add(new AudioRange(700));
			
			var timeline:Timeline = bucketEntity.get(Timeline);
			timeline.play();
			timeline.handleLabel("shake", Command.create(bucketShake, bucketEntity), false);		
		}
		
		private function bucketShake(bucket:Entity):void
		{
			bucket.get(Audio).play(SoundManager.EFFECTS_PATH + "shake_bin_01.mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
		
		private function setupBird():void
		{
			var clip:MovieClip = _hitContainer["canary"];
			_bird = EntityUtils.createMovingEntity(this, clip);
			TimelineUtils.convertClip(clip, this, _bird);
			if(AppConfig.mobile)
			{
				BitmapTimelineCreator.convertToBitmapTimeline(_bird, null, true, null, PerformanceUtils.defaultBitmapQuality);
			}
			
			_characterGroup.addTimelineFSM(_bird, true, new <Class>[SeagullIdleState, SeagullBeginFlightState, SeagullFlyState, SeagullLandState, SeagullSittingAngryState], MovieclipState.STAND, false);
			
			var spatial:Spatial = _bird.get(Spatial);
			var motionTarget:MotionTarget = _bird.get(MotionTarget);			
			motionTarget.targetX = spatial.x;
			motionTarget.targetY = spatial.y;
			
			_bird.add(new Seagull(600, 200, -1));
			_bird.add(new Audio());
			_bird.add(new AudioRange(700, 0, 1, Sine.easeIn));
			_bird.remove(Sleep);
		}
		
		private function switchGuardDirection(...args):void
		{
			var spatial:Spatial = _guard.get(Spatial);
			var endX:Number = spatial.x > 2600 ? 1550 : 2680;
			_lightFollow.offset.x = spatial.x > 2600 ? -60 : 60;
			
			CharUtils.moveToTarget(_guard, endX, 640, true, switchGuardDirection, new Point(20, 40));
			_guard.get(CharacterMotionControl).maxVelocityX = 140;
		}
		
		private function enteredGuardZone(zoneId:String, charId:String):void
		{
			if(charId == "player")
			{
				_currentPlayerZone = zoneId;
			}
			else if(charId == "guard")
			{
				_currentGuardZone = zoneId;
			}
			
			if(_currentGuardZone && _currentPlayerZone && _currentGuardZone == _currentPlayerZone)
			{
				roofCaught();
			}
		}
		
		private function exittedGuardZone(zoneId:String, charId:String):void
		{
			if(charId == "player")
			{
				_currentPlayerZone = null;
			}
			else if(charId == "guard")
			{
				_currentGuardZone = null;
			}
		}
		
		override protected function roofCaught(...args):void
		{
			_guard.get(Destination).interrupt = true;
			_currentPlayerZone = null;
			_currentGuardZone = null;
			
			roofCheckPoint = new Point(40, 660);
			
			super.roofCaught();
		}
		
		override protected function sendPlayerBack(screenEffects:ScreenEffects = null):void
		{
			_guard.get(Destination).interrupt = false;
			switchGuardDirection();			
			
			super.sendPlayerBack(screenEffects);
		}
		
		private function showEscape(...args):void
		{
			_warden = getEntityById("warden");
			var wardenControl:CharacterMotionControl = new CharacterMotionControl();
			wardenControl.jumpVelocity = 0;
			wardenControl.maxVelocityX = 160;
			_warden.add(wardenControl);
			_warden.add(new ValidHit("concrete", "wood", "baseGround", "wall"));
			
			_ratchet = getEntityById("ratchet");
			var ratchetControl:CharacterMotionControl = new CharacterMotionControl();
			ratchetControl.jumpVelocity = 0;
			ratchetControl.maxVelocityX = 160;
			_ratchet.add(ratchetControl);
			_ratchet.add(new ValidHit("concrete", "wood", "baseGround", "wall"));
			
			_nightingale = getEntityById("nightingale");
			var nightingaleControl:CharacterMotionControl = new CharacterMotionControl();
			nightingaleControl.jumpVelocity = 0;
			nightingaleControl.maxVelocityX = 160;
			_nightingale.add(nightingaleControl);
			_nightingale.add(new ValidHit("concrete", "wood", "baseGround", "wall"));
			
			SceneUtil.lockInput(this, true);
			player.get(MotionBounds).box = new Rectangle(0, 45, 3800, 2000);
			
			var actionChain:ActionChain = new ActionChain(this);
			actionChain.addAction(new PanAction(_endLight));
			actionChain.addAction(new SetSpatialAction(_nightingale, new Point(1600, 660)));
			actionChain.addAction(new SetSpatialAction(_ratchet, new Point(1670, 660)));
			actionChain.addAction(new SetSpatialAction(_warden, new Point(1740, 660)));			
			actionChain.addAction(new WaitAction(2));			
			actionChain.addAction(new PanAction(_warden));
			actionChain.addAction(new SetSpatialAction(player, new Point(3140, 670))).noWait = true;
			actionChain.addAction(new TalkAction(_nightingale, "footsteps"));
			actionChain.addAction(new TalkAction(_ratchet, "end"));
			actionChain.addAction(new TalkAction(_warden, "no_escape"));			
			actionChain.addAction(new PanAction(player));
			actionChain.addAction(new AnimationAction(player, Tremble)).noWait = true;
			actionChain.addAction(new TalkAction(player, "trapped"));
			actionChain.addAction(new PanAction(_warden));
			actionChain.addAction(new MoveAction(_nightingale, new Point(2730, 670))).noWait = true;
			actionChain.addAction(new MoveAction(_ratchet, new Point(2800, 670))).noWait = true;
			actionChain.addAction(new MoveAction(_warden, new Point(2870, 670)));
			actionChain.addAction(new AudioAction(player, SoundManager.EFFECTS_PATH + "small_bird_call_0" + GeomUtils.randomInt(1,3) + ".mp3", 2000)); 
			actionChain.addAction(new CallFunctionAction(moveBird));
			actionChain.addAction(new SetDirectionAction(_warden, false));
			actionChain.addAction(new SetDirectionAction(_ratchet, false));
			actionChain.addAction(new SetDirectionAction(_nightingale, false));
			actionChain.addAction(new WaitAction(1));
			actionChain.addAction(new PanAction(_bird));			
			actionChain.execute();				
		}
		
		private function moveBird():void
		{
			_firstStand = true;
			var motionTarget:MotionTarget = _bird.get(MotionTarget);
			motionTarget.targetX = 2795;
			motionTarget.targetY = 400;
			
			var fsmControl:FSMControl = _bird.get(FSMControl);
			fsmControl.stateChange = new Signal();
			fsmControl.stateChange.add(birdStateChange);
		}
		
		private function birdStateChange(type:String, entity:Entity):void
		{
			if(type == MovieclipState.STAND)
			{						
				if(_firstStand)
				{
					SceneUtil.delay(this, 5, makeBirdAngry).countByUpdate = true;
					_firstStand = false;
					return;
				}
				
				// After squawk start action chain
				var fsmControl:FSMControl = _bird.get(FSMControl);
				fsmControl.stateChange.removeAll();
				fsmControl.stateChange = null;
				
				var actionChain:ActionChain = new ActionChain(this);
				actionChain.addAction(new TweenEntityAction(_endLight, Spatial, 1.5, {rotation:2}));
				actionChain.addAction(new PanAction(player));
				actionChain.addAction(new AnimationAction(player, Salute)).noWait = true;
				actionChain.addAction(new TalkAction(player, "thank_bird"));
				actionChain.addAction(new MoveAction(player, new Point(3700, 950), new Point(200, 200)));
				
				var eventAction:EventAction = new EventAction(shellApi, _events.PLAYER_ESCAPED);
				eventAction.saveEvent = true;
				actionChain.addAction(eventAction);
				actionChain.addAction(new PanAction(_warden));
				actionChain.addAction(new TalkAction(_ratchet, "gone"));
				actionChain.addAction(new TalkAction(_nightingale, "nothing")).noWait = true;
				actionChain.addAction(new MoveAction(_warden, new Point(3460, 670)));
				actionChain.addAction(new TalkAction(_warden, "escaped"));
				actionChain.addAction(new WaitAction(1));
				actionChain.addAction(new CallFunctionAction(photoTake));
				actionChain.execute();			
			}
		}
		
		private function photoTake():void
		{
			shellApi.takePhotoByEvent("escaped_prison_photo_" + shellApi.profileManager.active.gender, Command.create(shellApi.loadScene, Escape));
		}
		
		private function makeBirdAngry():void
		{
			_bird.get(FSMControl).getState(MovieclipState.STAND).angryInterrupt = true;
		}
		
		private var _guard:Entity;
		private var _lightFollow:FollowTarget;
		private var _currentPlayerZone:String = null;
		private var _currentGuardZone:String = null;
		
		private var _endLight:Entity;
		private var _bird:Entity;
		private var _firstStand:Boolean;
		
		private var _warden:Entity;
		private var _nightingale:Entity;
		private var _ratchet:Entity;
	}
}