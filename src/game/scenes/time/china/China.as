package game.scenes.time.china
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.group.TransportGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Score;
	import game.data.game.GameEvent;
	import game.scenes.time.TimeEvents;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.china.components.FallingBrick;
	import game.scenes.time.china.components.RotatingPlatform;
	import game.scenes.time.china.systems.FallingBrickSystem;
	import game.scenes.time.china.systems.RotatingPlatformSystem;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.scenes.time.shared.emitters.Fire;
	import game.scenes.time.shared.emitters.FireSmoke;
	import game.scenes.time.shared.emitters.SmokeBlast;
	import game.scenes.time.shared.emitters.SmokeStream;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class China extends PlatformerGameScene
	{
		public function China()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			this.groupPrefix = "scenes/time/china/";
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
			_events = this.events as TimeEvents;
			
			placeTimeDeviceButton();
			this.shellApi.eventTriggered.add(handleEventTriggered);
			
			setupFallingBrick();
			setupWoodTipper();
			setupBowl();
		
			if(this.shellApi.checkItemUsedUp(_events.STONE_BOWL))
			{
				showStoneBowl(true);
				char1Smile();
			}
			
			if(this.shellApi.checkItemEvent(_events.AMULET))
			{
				hideAmulet();
			}
			
			this.addSystem(new FallingBrickSystem(), SystemPriorities.move);
			
			// Rotating System
			var rotatingSystem:RotatingPlatformSystem = new RotatingPlatformSystem();
			rotatingSystem._armMoved.add(woodMoveHandler);
			this.addSystem(rotatingSystem);
			
			if( this.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if (event == _events.MEMORY_GAME) 
			{
				showMemoryGame();
			}
			else if(event == GameEvent.GOT_ITEM + _events.STONE_BOWL)
			{
				if(!this.shellApi.checkHasItem(_events.STONE_BOWL) && !_returnedBool)
				{
					showStoneBowl();
					shellApi.triggerEvent(_events.ITEM_RETURNED_SOUND);
					if(timeButton){
						timeButton.get(TimeDeviceButton).flashButton();
					}
										
					var char1:Entity = this.getEntityById("char1");
					CharUtils.setAnim(char1, Score, false, 0, 0, true);
					RigAnimation( CharUtils.getRigAnim( char1) ).ended.add( char1Smile );
				}
			}
			else if(event == GameEvent.HAS_ITEM + _events.AMULET)
			{
				hideAmulet();
			}
		}
		
		private function char1Smile( anim:Animation = null ):void
		{
			var char1:Entity = this.getEntityById("char1");
			SkinUtils.setSkinPart(char1, SkinUtils.MOUTH, "6");
		}
		
		private function woodMoveHandler(armID:String):void
		{
			if(armID == "woodTip1")
			{
				this.shellApi.triggerEvent(_events.MOVE_WOOD_TIPPER);
			}
		}
		
		private function setupBowl():void
		{
			var bowl:MovieClip = this._hitContainer["bowl"];
			bowl.mouseEnabled = true;
			_bowlEntity = EntityUtils.createSpatialEntity(this, bowl);
			_bowlEntity.add(new Id("bowl"));
			TimelineUtils.convertClip(bowl, this, _bowlEntity);
		}
		
		private function showStoneBowl(instant:Boolean = false):void
		{
			_returnedBool = true;
			var timeline:Timeline = _bowlEntity.get(Timeline);
			
			if(instant)
				timeline.gotoAndStop("bowlVisible");
			else
				timeline.gotoAndPlay("viewBowl");			
			
			timeline.handleLabel("bowlVisible", showFire);
		}
		
		private function showFire():void
		{
			var timeline:Timeline = _bowlEntity.get(Timeline);
			
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.offsetX = 0;
			sceneInteraction.offsetY = 0;
			sceneInteraction.approach = false;
			_bowlEntity.add(sceneInteraction);
			InteractionCreator.addToEntity(_bowlEntity, [InteractionCreator.DOWN, InteractionCreator.UP]);
			
			Interaction(_bowlEntity.get(Interaction)).down.addOnce(bowlMouseDown);
			
			var group:Group = OwningGroup(_bowlEntity.get(OwningGroup)).group;
			_fire = new Fire();
			_fire.init(5, new RectangleZone(-13, -4, 13, -4));
			EmitterCreator.create(group, this._hitContainer["bowl"]["fireHolder"], _fire, 0, 0, _bowlEntity, "fire");
			
			_smoke = new FireSmoke();
			_smoke.init(9, new LineZone(new Point(-2, -20), new Point(2, -40)), new RectangleZone(-10, -5, 10, -5));
			EmitterCreator.create(group, this._hitContainer["bowl"]["smokeHolder"], _smoke, 0, 0, _bowlEntity, "smoke");
		
			_smokeBlast = new SmokeBlast();
			_smokeBlast.init(new RectangleZone(-20, -5, 20, 5), new LineZone(new Point(0, -170), new Point(0, -220)), 0, 11);
			EmitterCreator.create(group, this._hitContainer["bowl"]["smokeHolder"], _smokeBlast, 0, 0, _bowlEntity, "smokeBlast", null, false);
			
			// Smoke in the backdrop only if quality is high enough
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM)
			{
				var backdrop:Entity = getEntityById("backdrop");
				
				_backdropSmoke = new SmokeStream();
				_backdropSmoke.init(new RectangleZone(1080, 544, 1084, 559), 15, 7);
				EmitterCreator.create(OwningGroup(backdrop.get(OwningGroup)).group, backdrop.get(Display).displayObject, _backdropSmoke);		
			}
		
			_fireAudio = new Audio();
			var soundEnt:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["bowl"]);
			soundEnt.add(_fireAudio);
			soundEnt.add(new AudioRange(1500, 0, 3, Sine.easeIn));
			_fireAudio.play(SoundManager.EFFECTS_PATH + "fire_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
		
		private function bowlMouseDown(entity:Entity):void
		{
			Interaction(_bowlEntity.get(Interaction)).up.addOnce(bowlMouseUp);
			_fireAudio.fade(SoundManager.EFFECTS_PATH + "fire_01_L.mp3", 0, 1, 3); 
			_smoke.counter.stop();
			_fire.counter.stop();
			
			_smokeCount = 3;
			SceneUtil.addTimedEvent(this, new TimedEvent(.2, 20, counterIncrease))
		}
		
		private function bowlMouseUp(entity:Entity):void
		{
			Interaction(_bowlEntity.get(Interaction)).down.addOnce(bowlMouseDown);
			_fireAudio.play(SoundManager.EFFECTS_PATH + "fire_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]); 
			_smokeBlast.counter = new Blast(_smokeCount);
			_smokeBlast.start();
			_smoke.counter.resume();
			_fire.counter.resume();
		}
		
		private function playBackdropSmoke():void
		{
			_backdropSmoke.start();
		}
		
		private function counterIncrease():void
		{
			_smokeCount++;
		}
		
		private function hideAmulet():void
		{
			var amuletGame:Entity = this.getEntityById("char2");
			SkinUtils.setSkinPart(amuletGame, SkinUtils.OVERSHIRT, "empty", true);
		}
		
		private function setupFallingBrick():void
		{
			// setup the entities
			var brickDisplay:MovieClip = this._hitContainer["fallingBrick"];
		    this._hitContainer.setChildIndex(brickDisplay, this._hitContainer.numChildren - 1);
			
			var brick:Entity = this.getEntityById("fallingBrick");
			var hit:Entity = this.getEntityById("brickHit");
			var motion:Motion = new Motion();
			hit.add(motion);
			hit.remove(Sleep);
			
			var fallingBrick:FallingBrick = new FallingBrick();
			fallingBrick.scene = this;
			fallingBrick.hit = hit;
			fallingBrick.hitMotion = hit.get( Motion );
			fallingBrick.hitSpatial = hit.get( Spatial );
			fallingBrick.state = "stopped";
			fallingBrick.startPos = new Point(2213, 746);
			fallingBrick.range = new Rectangle(1570, 1000, 2655,1470);
			fallingBrick.spinSpeed = new Point(-100, 100);
			fallingBrick.velocity = 800;
			fallingBrick.waitTime = 1.2;
			brick.add(fallingBrick);
		}
		
		private function setupWoodTipper():void
		{
			var woodTip:Entity = this.getEntityById("woodTip1");
			var spatial:Spatial = woodTip.get(Spatial);
			var motion:Motion = new Motion();
			
			woodTip.remove(Sleep);
			var wood:Entity = EntityUtils.createMovingEntity(this, this._hitContainer["wood1"]);
			wood.add(motion);
			
			var rotationalPlatform:RotatingPlatform = new RotatingPlatform(spatial.x, spatial.y);
			
			rotationalPlatform.spatial = wood.get(Spatial);
			rotationalPlatform.motion = motion;
			woodTip.add(rotationalPlatform);
		}
		
		private function showMemoryGame():void
		{
			var popup:MemoryGame = this.addChildGroup(new MemoryGame(this.overlayContainer)) as MemoryGame;
			popup.id = "memoryGame";
			popup._victory.addOnce(Command.create(memoryGameWon, popup));
			popup._lost.addOnce(Command.create(memoryGameLost, popup));
		}
		
		private function memoryGameWon(popup:MemoryGame):void
		{
			popup.close();
			
			this.shellApi.triggerEvent("majong_won");
			
			if(this.shellApi.checkHasItem(_events.AMULET))
				Dialog(this.getEntityById("char2").get(Dialog)).sayById("memory_game_win_extra");
			else
				Dialog(this.getEntityById("char2").get(Dialog)).sayById("memory_game_win");
		}
		
		private function memoryGameLost(popup:MemoryGame):void
		{
			popup.close();
			Dialog(this.getEntityById("char2").get(Dialog)).sayById("memory_game_lost");
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(_events.TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
		private var timeButton:Entity;
		
		private var _fireAudio:Audio;
		private var _backdropSmoke:SmokeStream;
		private var _events:TimeEvents;
		private var _bowlEntity:Entity;
		private var _smoke:FireSmoke;
		private var _fire:Fire;
		private var _smokeBlast:SmokeBlast;
		private var _smokeCount:Number = 3;
		private var _returnedBool:Boolean = false;
	}
}