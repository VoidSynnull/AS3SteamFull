package game.scenes.con2.lobby
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.part.SkinPart;
	import game.components.hit.Zone;
	import game.components.motion.ShakeMotion;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Attack;
	import game.data.animation.entity.character.PlacePitcher;
	import game.data.animation.entity.character.Salute;
	import game.data.game.GameEvent;
	import game.scenes.con2.Con2Events;
	import game.scenes.con2.shared.Poptropicon2Scene;
	import game.systems.motion.ShakeMotionSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Lobby extends Poptropicon2Scene
	{
		private var sasha:Entity;
		private var guard:Entity;
		
		private var _events:Con2Events;
		
		private var phoneHasSignal:Boolean;
		
		private const PHONE_RING:String = SoundManager.EFFECTS_PATH + "phone_ring_01_L.mp3";
		private const PHONE_ANSWER:String = SoundManager.EFFECTS_PATH + "alarm_03.mp3";
		private const HIT_MACHINE:String = SoundManager.EFFECTS_PATH + "shake_machine_01.mp3";
		private const SMASH_MACHINE:String = SoundManager.EFFECTS_PATH + "metal_impact_16.mp3";
		
		
		private const PLAY:String = "play_";
		private const PHONE_ID:String = "mk_lead_designer01";
		
		public function Lobby()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con2/lobby/";
			
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
			setupChars();
			setupPhoneGuard();
			setupPhoneSignal();
			setupSodaMachine();
			
			addSystem(new ShakeMotionSystem());
			super.loaded();
		}
		
		override public function onEventTriggered(event:String, save:Boolean=true, init:Boolean=false, removeEvent:String=null):void
		{
			if(event == GameEvent.GOT_ITEM + _events.SASHA_CARD){
				SceneUtil.addTimedEvent(this,new TimedEvent(1,1,sashaLeaves));
			}
			else if( event == "call_sasha_phone"){
				if(shellApi.checkHasItem(_events.CELL_PHONE)){
					if(phoneHasSignal){
						//player us phone first, then ring
						usePhone(player);
						CharUtils.getTimeline(player).handleLabel("raised",Command.create(SceneUtil.addTimedEvent,this,new TimedEvent(1,1,ringPhoneBox)));
					}else{
						// no signal
						Dialog(player.get(Dialog)).sayById("noSignal");
					}
				}else{
					Dialog(player.get(Dialog)).sayById("noPhone");
				}
			}
			super.onEventTriggered(event, save, init, removeEvent);
		}
		
		private function ringPhoneBox():void
		{
			if(!shellApi.checkEvent(_events.OMEGON_CAPE_PHOTO)){
				// look at box, make it dance?
				SceneUtil.lockInput(this, true);
				var phoneBox:Entity = getEntityById("cellBoxInteraction");
				Display(phoneBox.get(Display)).isStatic = false;
				// shake
				var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-1, -1, 1, 1));
				shake.onInterval = 1.9;
				shake.offInterval = 1.75;
				shake.shaking = false;
				phoneBox.add(shake);
				phoneBox.add(new SpatialAddition());
				SceneUtil.setCameraTarget(this,phoneBox);
				// play positional sound on phone box
				AudioUtils.playSoundFromEntity(phoneBox, PHONE_RING, 700, 0.2, 1.5, Linear.easeInOut, true);
				// grab phone interaction
				var interaction:SceneInteraction = phoneBox.get(SceneInteraction);
				interaction.reached.removeAll();
				interaction.reached.addOnce(gotSashaPhone);
				// gaurd comment
				var dialog:Dialog = guard.get(Dialog);
				dialog.sayById("whatSignal");
				dialog.complete.addOnce(returnControls);
				
			}
		}
		
		private function gotSashaPhone(player:Entity, box:Entity):void
		{
			SceneUtil.lockInput(this,true);
			AudioUtils.stop(this, PHONE_RING);
			var phoneBox:Entity = getEntityById("cellBoxInteraction");
			phoneBox.remove(ShakeMotion);
			AudioUtils.playSoundFromEntity(phoneBox, PHONE_ANSWER, 1000, 0, 1.0, null, false);
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("gotPhoto");
			dialog.complete.addOnce(getOmegonPhoto);
			dialog.complete.addOnce(unlock);
		}
		
		private function getOmegonPhoto(...p):void
		{
			// give phone
			getEntityById("cellBoxInteraction").remove(WaveMotion);
			this.snapPhoto(_events.OMEGON_CAPE_PHOTO,returnControls);
		}
		
		private function setupPhoneSignal():void
		{
			if(!shellApi.checkEvent(_events.OMEGON_CAPE_PHOTO)){
				var zone:Zone = getEntityById("zone0").get(Zone);
				zone.entered.add(hasSignal);
				zone.exitted.add(noSignal);
			}else{
				noSignal();
			}
		}
		
		private function usePhone(char:Entity, stopAtEnd:Boolean = false, phoneIsTemp:Boolean = true):void
		{
			SkinUtils.setSkinPart(char, SkinUtils.ITEM, PHONE_ID);
			CharUtils.setAnim(char, Salute);
			if(stopAtEnd){
				CharUtils.getTimeline(char).handleLabel("raised", CharUtils.getTimeline(char).stop );
			}else if(phoneIsTemp){
				CharUtils.getTimeline(char).handleLabel("ending", Command.create(removePhone,char) );
			}
			AudioUtils.stop(this, PHONE_RING);
			AudioUtils.playSoundFromEntity(char, PHONE_ANSWER, 500, 0, 1.0, null, false);		
		}
		
		private function removePhone(char:Entity):void
		{
			var skinPart:SkinPart = SkinUtils.getSkinPart( char, SkinUtils.ITEM )
			skinPart.remove();
		}
		
		private function hasSignal(...p):void
		{
			//trace("HAS signal")
			phoneHasSignal = true;
		}
		private function noSignal(...p):void
		{
			//trace("NO signal")
			phoneHasSignal = false;
		}
		
		// set important characters
		private function setupChars():void
		{
			sasha = getEntityById("sasha");
			if(shellApi.checkEvent(_events.SASHA_LEFT_LOBBY)){
				removeEntity(sasha);
			}
			var pinata:Entity = getEntityById("pinataMan");
			Spatial(pinata.get(Spatial)).rotation = 50;
			var sceneInt:SceneInteraction = SceneInteraction(pinata.get(SceneInteraction));
			sceneInt.approach = false;
			sceneInt.triggered.removeAll()
			sceneInt.triggered.add(randomPinata);
			var clip:MovieClip = _hitContainer["rope"];
			clip.mouseEnabled = true;
			clip.mouseChildren = true;
			BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			var rope:Entity = EntityUtils.createMovingEntity(this,clip);
			Display(pinata.get(Display)).setContainer(clip["end"]);
			EntityUtils.position(pinata, 0, 0);
			MotionUtils.addWaveMotion(rope,new WaveMotionData("rotation", 3, .025, "cos", 3),this);
		}
		
		// pinata man says something random
		private function randomPinata(char:Entity, pinata:Entity):void
		{
			Dialog(pinata.get(Dialog)).sayById("pin"+GeomUtils.randomInt(0,2));
		}
		
		private function setupPhoneGuard():void
		{
			guard = getEntityById("guard");
			// interupt player at conference hall door, because it ain't real
			var demoDoor:Entity = getEntityById("roomInteraction");
			var inter:SceneInteraction = demoDoor.get(SceneInteraction);
			inter.minTargetDelta = new Point(25,50);
			inter.reached.removeAll();
			inter.reached.add(demoDoorReached);
			var cellBox:Entity = getEntityById("cellBoxInteraction");
			inter = cellBox.get(SceneInteraction);
			inter.reached.removeAll();
			inter.reached.add(dontTouch);
		}
		
		private function dontTouch(...p):void
		{
			var dialog:Dialog = player.get(Dialog);
			if(shellApi.checkEvent(_events.OMEGON_CAPE_PHOTO)){
				dialog.sayById("noTouch2");
			}
			else if(!shellApi.checkEvent(_events.SASHA_LEFT_LOBBY)){
				dialog.sayById("noTouch3");
			}
			else{
				dialog.sayById("noTouch");				
			}
		}
		
		private function demoDoorReached(...p):void
		{
			// do guard interupt
			SceneUtil.lockInput(this,true);
			SceneUtil.setCameraTarget(this,guard);
			var dialog:Dialog = guard.get(Dialog);
			dialog.sayById("noEntry");
			dialog.complete.addOnce(backUp);
			dialog.complete.addOnce(guardUsedPhone);
		}
		
		private function guardUsedPhone(...p):void
		{
			usePhone(guard);
			SceneUtil.addTimedEvent(this,new TimedEvent(1.2,1,Command.create(guard.get(Dialog).sayById,"guardNoSignal")));
			guard.get(Dialog).complete.addOnce(unlock);
		}
		
		private function backUp(...p):void
		{
			// back it up
			CharUtils.moveToTarget(player,650,770);
			CharUtils.setDirection(guard,true);
		}
		
		private function unlock(...p):void
		{
			SceneUtil.setCameraTarget(this,player);
			SceneUtil.lockInput(this,false);
		}
		
		private function sashaLeaves():void
		{
			if(sasha){
				SceneUtil.setCameraTarget(this,sasha);
				SceneUtil.lockInput(this,true);
				AudioUtils.playSoundFromEntity(sasha, PHONE_RING, 600, 0.2, 2.0, null, false);
				SceneUtil.addTimedEvent(this, new TimedEvent(2.6,1,Command.create(usePhone,sasha,true,false)));
				var dialog:Dialog = sasha.get(Dialog);
				SceneUtil.addTimedEvent(this,new TimedEvent(3,1,Command.create(dialog.sayById,"preview")));
				dialog.complete.addOnce(Command.create(moveChar,460,730,sashaTalkGuard));
			}
		}
		
		private function moveChar(d:*, x:Number, y:Number, finish:Function=null):void
		{
			CharUtils.moveToTarget(sasha, x, y, true, finish);
		}
		
		private function sashaTalkGuard(...p):void
		{
			var dialog:Dialog = guard.get(Dialog);
			dialog.sayById("phonePlease");
			dialog = sasha.get(Dialog);
			dialog.faceSpeaker = false;
			dialog.complete.addOnce(placePhone);
		}
		
		private function placePhone(...p):void
		{
			CharUtils.setAnim(sasha,PlacePitcher);	
			CharUtils.getTimeline(sasha).handleLabel("trigger", Command.create(removePhone,sasha) );
			SkinUtils.setSkinPart(sasha, SkinUtils.ITEM, PHONE_ID);
			SceneUtil.addTimedEvent(this,new TimedEvent(1,1,Command.create(moveChar,null,190,730,hideSasha)));
		}
		
		private function hideSasha(...p):void
		{
			removeEntity(sasha);
			shellApi.completeEvent(_events.SASHA_LEFT_LOBBY);
			unlock();
		}
		
		
		private function setupSodaMachine():void
		{
			// machine has card and no card frames
			var clip:MovieClip = _hitContainer["sodaMachine"];
			var sodaMachine:Entity;// = EntityUtils.createSpatialEntity(this, clip);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				sodaMachine = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,null,PerformanceUtils.defaultBitmapQuality);
				this.addEntity(sodaMachine);
			}else{
				sodaMachine = EntityUtils.createMovingTimelineEntity(this, clip);
			}
			sodaMachine.add(new Id("sodaMachine"));
			var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-2, -1, 2, 1));
			shake.active = false;
			sodaMachine.add(shake);
			sodaMachine.add(new SpatialAddition());
			var wizard:Entity = getEntityById("wizard");
			CharUtils.getTimeline(wizard).handleLabel("trigger",Command.create(shakeSoda,sodaMachine),false);
			// set button
			var sodaInt:Entity;
			if(!shellApi.checkEvent(_events.TIPPED_SODA_MACHINE))
			{
				sodaInt = getEntityById("sodaInteraction");
				var inter:SceneInteraction = sodaInt.get(SceneInteraction);
				inter.reached.addOnce(hitSodaMachine);
				Timeline(sodaMachine.get(Timeline)).gotoAndStop("stuckCard");
			}
			else
			{
				if(this.checkHasCard(_events.PONY_GIRL))
				{
					Timeline(sodaMachine.get(Timeline)).gotoAndStop("noCard");
					super.removeEntity( getEntityById("sodaInteraction") );
				}
				else
				{
					Timeline(sodaMachine.get(Timeline)).gotoAndStop("cardShowing");
					cardAvailable();
				}
			}
		}
		
		private function shakeSoda(soda:Entity, sound:String = HIT_MACHINE):void
		{
			var shake:ShakeMotion = soda.get(ShakeMotion);
			shake.active = true;
			AudioUtils.playSoundFromEntity(soda, sound,600,1);
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,Command.create(stopShakeSoda,shake)));
		}
		
		private function stopShakeSoda(shake:ShakeMotion):void
		{
			shake.active = false;
		}
		
		private function hitSodaMachine(...args):void
		{
			CharUtils.setAnim(player, Attack);
			var sodaMachine:Entity = getEntityById("sodaMachine");
			shakeSoda(sodaMachine,SMASH_MACHINE);
			shellApi.completeEvent(_events.TIPPED_SODA_MACHINE);
			
			SceneUtil.delay( this, 1.5, dropCard );
		}	
		
		private function dropCard(...args):void
		{
			var sodaMachine:Entity = getEntityById("sodaMachine");
			var timeline:Timeline = sodaMachine.get(Timeline);
			timeline.handleLabel( "cardShowing", cardAvailable );
			sodaMachine.get(Timeline).gotoAndPlay("dropCard");
		}
		
		private function cardAvailable(...args):void
		{
			super.getEntityById("wizard").get(Dialog).sayById("soda");
			trace("card has becom available");
			// if play clicks again, they get the card
			var sodaInt:Entity = getEntityById("sodaInteraction");
			var inter:SceneInteraction = sodaInt.get(SceneInteraction);
			inter.reached.addOnce( giveCard );
		}
		
		private function giveCard(...args):void
		{
			Timeline(getEntityById("sodaMachine").get(Timeline)).gotoAndStop("noCard");
			super.addCardToDeck(_events.PONY_GIRL);
			super.removeEntity( getEntityById("sodaInteraction") );
		}
		
	}
}