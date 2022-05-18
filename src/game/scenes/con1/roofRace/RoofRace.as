package game.scenes.con1.roofRace
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.OriginPoint;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.Zone;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.sound.SoundModifier;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.con1.center.Center;
	import game.scenes.con1.roofRace.NavigationSmart.SmartNavUtils;
	import game.scenes.con1.roofRace.Timer.Timer;
	import game.scenes.con1.roofRace.Timer.TimerSystem;
	import game.scenes.con1.shared.Poptropicon1Scene;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeck;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeckSystem;
	import game.scenes.survival1.cave.particles.CaveDrip;
	import game.scenes.survival1.cave.particles.CaveSplash;
	import game.systems.entity.character.states.ClimbState;
	import game.systems.entity.character.states.FallState;
	import game.systems.entity.character.states.LandState;
	import game.systems.entity.character.states.RunState;
	import game.systems.entity.character.states.WalkState;
	import game.systems.entity.character.states.touch.JumpState;
	import game.systems.entity.character.states.touch.SkidState;
	import game.systems.entity.character.states.touch.StandState;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	public class RoofRace extends Poptropicon1Scene
	{
		public function RoofRace()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con1/roofRace/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
				
		private var path:Vector.<Point>;
		private var npc:Entity;
		
		private var finish:Entity;
		
		private var timer:Timer;
		
		private var playerFinished:Boolean = false;
		private var npcFinished:Boolean = false;
		
		private var finishLine:Zone;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();			
			addSystem(new HitTheDeckSystem());
			
			// for debug	
			//var navSystem:NavigationSystem = super.getSystem( NavigationSystem ) as NavigationSystem;
			//navSystem.debug = true;
			
			setUpNpc();
			setUpFinishLine();
			if(!PlatformUtils.isMobileOS)
			{
				setUpFlies();
				setUpDrips();
			}
			setUpMice();
			setUpAnimations();
			//setUpTimer(); //seems like the kind of scene players may like to race other kids times?
		}
		
		private function setUpAnimations():void
		{
			setUpTimeline(_hitContainer["steam"], 24);
			var range:AudioRange = new AudioRange(1500, 0, 2, Quad.easeOut);
			var flag:Entity = setUpTimeline(_hitContainer["flag"], 32);
			if(flag != null)
			{
				flag.add(new Audio()).add(range);
				Audio(flag.get(Audio)).play(SoundManager.EFFECTS_PATH + "flag_flapping_01.mp3", true, SoundModifier.POSITION);
			}
		}
		
		private function setUpTimeline(clip:MovieClip, frameRate:int):Entity
		{
			if(PlatformUtils.isMobileOS)
			{
				_hitContainer.removeChild(clip);
				return null;
			}
			var entity:Entity= EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			TimelineUtils.convertClip(clip, this, entity,null, true, frameRate);
			return entity;
		}
		
		private function setUpMice():void
		{
			for(var i:int = 1; i <= 2; i++)
			{
				var clip:MovieClip = _hitContainer["mouse"+i];
				//if(PlatformUtils.isMobileOS)
				//{
					//_hitContainer.removeChild(clip);
					//continue;
				//}
				BitmapUtils.convertContainer(clip);
				var mouse:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				TimelineUtils.convertClip(clip, this, mouse, null, false);
				Timeline(mouse.get(Timeline)).handleLabel("ending",Command.create(hideMouse, mouse));
				var look:HitTheDeck = new HitTheDeck(player.get(Spatial), 200,false);
				look.duck.add(lookAtPlayer);
				mouse.add(look);
			}
		}
		
		private function lookAtPlayer(mouse:Entity):void
		{
			Timeline(mouse.get(Timeline)).play();
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "rodent_small_03.mp3",2);
		}
		
		private function hideMouse(mouse:Entity):void
		{
			var time:Timeline = mouse.get(Timeline);
			time.gotoAndStop(time.currentIndex);
		}
		
		private function setUpTimer():void
		{
			loadFile("hud.swf",hudLoaded);
		}
		
		private function hudLoaded(hud:MovieClip):void
		{
			var tf:TextField = hud.tf;
			tf.text = "00:00:00";
			var entity:Entity = EntityUtils.createSpatialEntity(this, hud, overlayContainer);
			Display(entity.get(Display)).moveToBack();
			
			timer = new Timer(tf,Timer.TIMER, 1,false);
			entity.add(timer);
			addSystem(new TimerSystem());
		}
		
		private function setUpDrips():void
		{
			var range:AudioRange = new AudioRange(1000, 0, 1, Quad.easeIn);
			for(var i:int = 1; i <= 7; i++)
			{
				var clip:MovieClip = _hitContainer["drips"+i];
				var zone:Rectangle = clip.getBounds(_hitContainer);
				var rate:Number = Math.random() * .1 + .1;
				var particle:CaveDrip = new CaveDrip(zone, rate, i);
				particle.deadParticle.add(playDripAudio);
				var entity:Entity = EmitterCreator.create(this, _hitContainer, particle,zone.x, zone.y, null, "drip"+i);
				
				var splash:CaveSplash = new CaveSplash( new Point(zone.x, zone.bottom) );
				entity = EmitterCreator.create(this, this._hitContainer, splash,0,0, null, "splash"+i, null, false);
				entity.add(new Audio()).add(range);
				var spatial:Spatial = entity.get(Spatial);
				spatial.x = zone.x;
				spatial.y = zone.bottom;
				_hitContainer.removeChild(clip);
			}
		}		
		
		private function playDripAudio(caveDrip:CaveDrip):void
		{
			var entity:Entity = this.getEntityById("splash" + caveDrip.index);
			
			var emitter:Emitter = entity.get(Emitter);
			emitter.start = true;
			emitter.emitter.start();
			
			Audio(entity.get(Audio)).play(SoundManager.EFFECTS_PATH + "drip_0" + Utils.randInRange(1, 3) + ".mp3", false,SoundModifier.POSITION);
		}
		
		private function setUpFlies():void
		{
			for(var num:int = 1; num <=2; num++)
			{
				var basePosition:MovieClip = _hitContainer["fly"+num];
				for(var i:int = 1; i <= 4; i++)
				{
					var clip:MovieClip = new MovieClip();
					clip.graphics.beginFill(0,1);
					clip.graphics.drawCircle(0,0,2);
					clip.graphics.endFill();
					
					var fly:Entity = EntityUtils.createSpatialEntity(this, BitmapUtils.createBitmapSprite(clip), _hitContainer);
					
					var flyPos:Spatial = fly.get(Spatial);
					flyPos.x = basePosition.x + Math.random() * basePosition.width;
					flyPos.y = basePosition.y + Math.random() * basePosition.height;
					
					fly.add(new SpatialAddition());
					fly.add(new WaveMotion());
					fly.add(new OriginPoint(flyPos.x, flyPos.y));
					fly.add(new Tween());
					
					moveFly(fly);
				}
				_hitContainer.removeChild(basePosition);
			}
		}
		
		private function moveFly(fly:Entity):void
		{
			var wave:WaveMotion = fly.get(WaveMotion);
			wave.data.length = 0;
			wave.data.push(new WaveMotionData("x", Math.random() * 10, Math.random() / 10));
			wave.data.push(new WaveMotionData("y", Math.random() * 10, Math.random() / 10));
			
			var origin:OriginPoint = fly.get(OriginPoint);
			var targetX:Number = (Math.random() - 0.5) * 250 + origin.x;
			var targetY:Number = (Math.random() - 0.5) * 100 + origin.y;
			
			var time:Number = Math.random() * .25 +.5;
			
			var tween:Tween = fly.get(Tween);
			tween.to(fly.get(Spatial), time, {x:targetX, y:targetY, ease:Linear.easeInOut, onComplete:moveFly, onCompleteParams:[fly]});
		}
		
		private function setUpFinishLine():void
		{
			finish = getEntityById("finishZone");
			finishLine = finish.get(Zone);
			finishLine.entered.add(crossedFinishLine);
			finishLine.pointHit = true;
			finish.remove(Sleep);
		}
		
		private function crossedFinishLine(finishID:String, hitID:String):void
		{
			if(hitID == "player")
			{
				SceneUtil.lockInput(this);
				playerFinished = true;
				if(npcFinished)
					youWin(false);
				else
				{
					var spatial:Spatial = npc.get(Spatial);
					if(spatial.y > 1000)
					{
						spatial.x = 350;
						spatial.y = 1000;
						CharUtils.moveToTarget(npc, 405,450);
					}
				}
			}
			else
			{
				npcFinished = true;
				if(playerFinished)
					youWin(true);
			}
			if(timer != null)
				timer.stop();
		}
		
		private function youWin(won:Boolean):void
		{
			finishLine.entered.removeAll();
			SceneInteraction(npc.get(SceneInteraction)).activated = true;
			
			var dialog:Dialog = npc.get(Dialog);
			var dialogId:String = "win";
			var version:String = "1";
			
			// won is for player so dialog for npc is opposite
			if(won)
				dialogId = "loose";
			
			if(shellApi.checkEvent(_events.WON_RACE))
			{
				version = "2";
				if(won)
					Dialog(player.get(Dialog)).complete.addOnce(returnToCon);
			}
			else
			{
				if(won)
					dialog.complete.addOnce(cheetah);
			}
			
			if(!won)
				dialog.complete.addOnce(createLoosePopup);
			
			dialog.sayById(dialogId+version);
		}
		
		private function cheetah(...args):void
		{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("cheetah");
			dialog.complete.addOnce(dealIsADeal);
		}
		
		private function dealIsADeal(...args):void
		{
			var dialog:Dialog = npc.get(Dialog);
			dialog.sayById("fine");
			dialog.complete.addOnce(getGem);
		}
		
		private function createLoosePopup(...args):void
		{
			SceneUtil.lockInput(this, false);
			var loosePopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer, false, true);
			loosePopup.configData("climb_fail.swf", groupPrefix);
			loosePopup.updateText("You lost the race!", "Try Again", "Quit");
			loosePopup.buttonClicked.add(buttonClicked);
			addChildGroup(loosePopup);
		}
		
		private function buttonClicked(again:Boolean):void
		{
			if(again)
				shellApi.loadScene(RoofRace);
			else
				returnToCon();
		}
		
		private function returnToCon(...args):void
		{
			shellApi.removeEvent(_events.SKIP_PREVIEW);
			shellApi.loadScene(Center,300, 1500,"left",NaN, 2);
		}
		
		private function getGem(...args):void
		{
			shellApi.completeEvent(_events.WON_RACE);
			if(shellApi.checkHasItem(_events.POWER_GEM))
			{
				returnToCon();
				return;
			}
			var itemGroup:ItemGroup = super.getGroupById(ItemGroup.GROUP_ID, this) as ItemGroup;
			itemGroup.showAndGetItem(_events.POWER_GEM,null,returnToCon);
		}
		
		private function setUpNpc():void
		{
			npc = getEntityById("npc");
			npc.add(new ZoneCollider()).add(new SpecialAbilityControl()).remove(Sleep);
			SmartNavUtils.addSmartNavToChar(this, npc);
			
			var states:Vector.<Class> = new <Class>[ ClimbState, FallState, JumpState, LandState, RunState, SkidState, StandState, WalkState ]; 
			CharacterGroup(super.getGroupById( CharacterGroup.GROUP_ID )).addFSM( npc, true, states, "stand" );	

			SceneInteraction(npc.get(SceneInteraction)).reached.removeAll();
			
			path = SmartNavUtils.createPath(_hitContainer);
			
			skipIntro(shellApi.checkEvent(_events.SKIP_PREVIEW));
			
			getEntityById("climb1").remove(Sleep);
			getEntityById("climb2").remove(Sleep);
		}
		
		private function skipIntro(skip:Boolean):void
		{
			lockControls();
			if(skip)
				getReady();
			else
				startIntro();
		}
		
		private function startIntro():void
		{
			Dialog(npc.get(Dialog)).sayById("first");
			shellApi.completeEvent(_events.SKIP_PREVIEW);
		}
		
		override public function handleEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _events.VIEW_RACE)
				previewRace();
			if(event == _events.HEAD_START)
				race();
			if(event == _events.START_RACE)
			{
				if(timer != null)
					timer.start();
				returnControls();
			}
			
			super.handleEventTrigger(event, makeCurrent, init, removeEvent);
		}
		
		private function previewRace():void
		{
			SceneUtil.setCameraTarget(this, finish, false, .01);
			SceneUtil.addTimedEvent(this, new TimedEvent(5, 1, getReady));
		}
		
		private function getReady():void
		{
			SceneUtil.setCameraTarget(this, player, false, .05);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, Command.create(Dialog(npc.get(Dialog)).sayById, "set")));
		}
		
		private function race(...args):void
		{
			CharUtils.followPath(npc,path,null,true,false,new Point(50, 100), true);
			CharacterMotionControl(npc.get(CharacterMotionControl)).maxVelocityX = 600;
		}
		
		private function lockControls(...args):void
		{
			SceneUtil.lockInput(this);
		}
		
		private function returnControls(...args):void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player);
		}
	}
}