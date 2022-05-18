package game.scenes.time.future2{
	import com.greensock.easing.Sine;
	
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
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Parent;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.RadiusControl;
	import game.components.motion.Threshold;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Proud;
	import game.data.character.LookData;
	import game.data.comm.PopResponse;
	import game.data.game.GameEvent;
	import game.data.sound.SoundModifier;
	import game.scene.template.PhotoGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.TimeEvents;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.systems.SystemPriorities;
	import game.systems.motion.RadiusToTargetSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.hud.Hud;
	import game.ui.popup.IslandEndingPopup;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class Future2 extends PlatformerGameScene
	{
		private var willTakePhoto:Boolean;

		public function Future2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/future2/";
			
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
			_events = super.events as TimeEvents;
			
			if(!super.shellApi.checkHasItem(_events.MEDAL_TIME))
			{
				setupConversation();
				super.shellApi.eventTriggered.add(handleEventTrigger);
			}
			
			super.addSystem(new ThresholdSystem(), SystemPriorities.update);
			
			setupChar();
			setupRobot();
			setupEye();
			setupScreen();
			placeTimeDeviceButton();
			var pg:PhotoGroup = getGroupById(PhotoGroup.GROUP_ID) as PhotoGroup;
			if (pg) {
				if (pg.shouldTakePhoto('11711')) {
					willTakePhoto = true;
					var hud:Hud = getGroupById(Hud.GROUP_ID) as Hud;
					if (hud) {
						hud.photoNotificationCompleted.addOnce(onPhotoTaken);
					}
				}
			}
		}
				
		private function setupChar():void
		{
			var futurePlayer:Entity = super.getEntityById("char1");
			var playerLook:LookData = SkinUtils.getLook(super.player, true);

			// making him look like the current player
			if(playerLook.getAspect(SkinUtils.EYES) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.EYES, playerLook.getAspect(SkinUtils.EYES).value);
			if(playerLook.getAspect(SkinUtils.EYE_STATE) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.EYE_STATE, playerLook.getAspect(SkinUtils.EYE_STATE).value);
			if(playerLook.getAspect(SkinUtils.GENDER) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.GENDER, playerLook.getAspect(SkinUtils.GENDER).value);
			if(playerLook.getAspect(SkinUtils.HAIR) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.HAIR, playerLook.getAspect(SkinUtils.HAIR).value);
			if(playerLook.getAspect(SkinUtils.ITEM) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.ITEM, playerLook.getAspect(SkinUtils.ITEM).value);
			if(playerLook.getAspect(SkinUtils.MARKS) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.MARKS, playerLook.getAspect(SkinUtils.MARKS).value);
			if(playerLook.getAspect(SkinUtils.MOUTH) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.MOUTH, playerLook.getAspect(SkinUtils.MOUTH).value);
			if(playerLook.getAspect(SkinUtils.OVERPANTS) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.OVERPANTS, playerLook.getAspect(SkinUtils.OVERPANTS).value);
			if(playerLook.getAspect(SkinUtils.OVERSHIRT) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.OVERSHIRT, playerLook.getAspect(SkinUtils.OVERSHIRT).value);
			if(playerLook.getAspect(SkinUtils.PACK) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.PACK, playerLook.getAspect(SkinUtils.PACK).value);
			if(playerLook.getAspect(SkinUtils.PANTS) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.PANTS, playerLook.getAspect(SkinUtils.PANTS).value);
			if(playerLook.getAspect(SkinUtils.SHIRT) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.SHIRT, playerLook.getAspect(SkinUtils.SHIRT).value);
			if(playerLook.getAspect(SkinUtils.SKIN_COLOR) != null) SkinUtils.setSkinPart(futurePlayer, SkinUtils.SKIN_COLOR, playerLook.getAspect(SkinUtils.SKIN_COLOR).value);			
		}
		
		private function setupConversation():void
		{
			var hit:Entity = super.getEntityById("zone1");
			var zone:Zone = hit.get(Zone);
			zone.pointHit = true;
			zone.entered.addOnce(conversationTriggered);
		}
		
		private function conversationTriggered(zoneId:String, characterId:String):void
		{
			var char:Entity = super.getEntityById("char1");
			var interaction:Interaction = char.get(Interaction);
			interaction.click.dispatch(char);
			SceneUtil.lockInput(this, true);
		}
		
		private function handleEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == GameEvent.GOT_ITEM + _events.MEDAL_TIME)
			{
				CharUtils.setAnim( player, Proud );
				
				super.shellApi.triggerEvent( _events.VICTORY, true );
				if (!willTakePhoto) {
					shellApi.completedIsland('', onCompletions);
				}
			}
		}

		private function onPhotoTaken():void
		{
			shellApi.completedIsland('', onCompletions);
		}

		private function onCompletions(response:PopResponse):void
		{
			SceneUtil.lockInput(this, false, false);
			var islandEndPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer)
			islandEndPopup.closeButtonInclude = true;
			this.addChildGroup( islandEndPopup );
		}
		
		private function setupRobot():void
		{
			var robot:MovieClip = this._hitContainer["robot"];
			var robotEntity:Entity = EntityUtils.createSpatialEntity(this, robot);
			
			ButtonCreator.createButtonEntity(robot, this, stopFollowingDialog);
			
			robotAudio = new Audio();
			var soundEntity:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["audioHolder"]);
			soundEntity.add(robotAudio);
			soundEntity.add(new AudioRange(1200, 0, 1, Sine.easeIn));
			soundEntity.add(new FollowTarget(robotEntity.get(Spatial), 1));
			
			var threshold:Threshold = new Threshold("x", ">");
			threshold.threshold = 1550;
			threshold.entered.add(Command.create(robotStop, robotEntity));
			threshold.exitted.add(Command.create(robotFollow, robotEntity));
			shellApi.player.add(threshold);
			
			robotFollow(robotEntity);
		}
		
		private function stopFollowingDialog(button:Entity):void
		{
			Dialog(super.player.get(Dialog)).sayById("robot_following");	
		}
		
		private function robotFollow(entity:Entity):void
		{
			var follow:FollowTarget = new FollowTarget(shellApi.player.get(Spatial), .015);
			follow.properties = new <String>["x"];
			follow.offset = new Point(180, 0);
			
			entity.add(follow);
			robotAudio.play(SoundManager.EFFECTS_PATH + "robot_move_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
		
		private function robotStop(entity:Entity):void
		{
			entity.remove(FollowTarget);
			robotAudio.stop(SoundManager.EFFECTS_PATH + "robot_move_01_L.mp3");
		}
		
		private function setupEye():void
		{
			var pupil:MovieClip = this._hitContainer["pupil"];
			var pupilEntity:Entity = EntityUtils.createSpatialEntity(this, pupil);
			pupilEntity.add(EntityUtils.createTargetSpatial(shellApi.player));
			
			var radiusControl:RadiusControl = new RadiusControl(7, 90.15, 405.5); 
			pupilEntity.add(radiusControl);
			
			this.addSystem(new RadiusToTargetSystem());
		}
		
		private function setupScreen():void
		{
			var background:Entity = getEntityById("background");
			var bgDisplay:Display = background.get(Display);
			
			var cloneData:BitmapData = BitmapUtils.createBitmapData(bgDisplay.displayObject);
			var bitmap:Bitmap = new Bitmap(cloneData);
			var sprite:Sprite = new Sprite();
			sprite.addChild(bitmap);
			
			var backgroundEntity:Entity = EntityUtils.createMovingEntity(this, sprite);
			var display:Display = backgroundEntity.get(Display);
			backgroundEntity.add(new Spatial(-1000, -100));
			backgroundEntity.add(new SpatialAddition());
			
			SceneUtil.addTimedEvent(this, new TimedEvent(.03, 0, Command.create(updateScreen, backgroundEntity)));
			
			// Add the background to the window
			var screen:MovieClip = this._hitContainer["tvScreen"]["holder"];
			screen.addChild(display.displayObject);
			var screenEntity:Entity = EntityUtils.createSpatialEntity(this, screen);
			screenEntity.add(new Id("tvScreen"));
			backgroundEntity.add(new Parent(screenEntity));
		}
		
		private function updateScreen(entity:Entity):void
		{
			radians += .03;
			var spatialAddition:SpatialAddition = entity.get(SpatialAddition);
			spatialAddition.x = Math.round(100 * Math.cos(radians)) * 2.3;
			spatialAddition.y = Math.round(100 * Math.sin(radians));
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(TimeEvents(events).TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
		
		private var robotAudio:Audio;
		private var timeButton:Entity;
		private var radians:Number = 0;
		private var _events:TimeEvents;
	}
}