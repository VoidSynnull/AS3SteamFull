package game.scenes.backlot.kirkTrailer
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.hit.Door;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Drink;
	import game.data.animation.entity.character.Knock;
	import game.data.game.GameEvent;
	import game.scenes.backlot.BacklotEvents;
	import game.scene.template.PlatformerGameScene;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class KirkTrailer extends PlatformerGameScene
	{
		private var trailerDoor:Entity;
		private var doorTimline:Timeline;
		private var trailerDoorDoor:Entity;
		
		public function KirkTrailer()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/kirkTrailer/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var backlot:BacklotEvents;
		private var kirk:Entity;
		private var carson:Entity;
		private var kirkCup:Entity;
		
		// all assets ready
		override public function loaded():void
		{
			backlot = super.events as BacklotEvents;
			super.loaded();
			super.shellApi.eventTriggered.add( onEventTriggered );
			
			this.addSystem( new ThresholdSystem(), SystemPriorities.update);
			
			carson = super.getEntityById("char1");
			kirk = super.getEntityById("char2");
			kirk.remove(Sleep);
			
			if(super.shellApi.checkEvent(backlot.DISRUPTED_KIRK))
			{
				kirk.get(Display).visible = false;
			}
			else
			{
				removeEntity(kirk);
				removeEntity(carson);
			}
			if(super.shellApi.checkEvent(backlot.CARSON_RETURNS_STAGE_1))
			{
				super.removeEntity(kirk);
				super.removeEntity(carson);
			}
			
			this.setupTrailerDoor();
			this.setupEgg();
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var url:String = "items/backlot/cup_large_empty.swf";
			if(event == backlot.KIRK_THREW_CUP)
			{
				if(!super.shellApi.checkEvent(GameEvent.HAS_ITEM + backlot.KIRK_COFFEE_CUP))
				{
					if(getEntityById("kirkCoffeeCup"))
					{
						SceneUtil.lockInput(this, false);
						return;
					}
					super.shellApi.fileLoadComplete.addOnce(Command.create( throwCup, url));
					super.loadFiles([url], true);
				}
			}
			if(event == backlot.GAVE_KIRK_COFFEE)
			{
				shellApi.triggerEvent("open");
				doorTimline.gotoAndPlay(0);
				doorTimline.handleLabel("end",labelReachedDoor,true);
			}
			if(event == backlot.KIRK_RETURNS_STAGE_1 && !shellApi.checkEvent(backlot.CARSON_RETURNS_STAGE_1))
			{
				returnKirkToSet();
			}
			if(event == backlot.CARSON_RETURNS_STAGE_1)
			{
				returnCarsonToSet();
			}
		}
		
		private function returnCarsonToSet():void
		{
			CharUtils.moveToTarget(carson, super.shellApi.camera.areaWidth,super.shellApi.camera.areaHeight, false, exitCarson);
			CharacterMotionControl( carson.get(CharacterMotionControl) ).maxVelocityX = 200;
		}
		
		private function exitCarson(entity:Entity):void
		{
			SceneUtil.setCameraTarget(this, player);
			super.removeEntity(carson);
			SceneUtil.lockInput(this, false);
		}
		
		private function returnKirkToSet():void
		{
			SceneUtil.setCameraTarget(this, kirk);
			CharUtils.moveToTarget(kirk, super.shellApi.camera.areaWidth,super.shellApi.camera.areaHeight);
			CharacterMotionControl( kirk.get(CharacterMotionControl) ).maxVelocityX = 200;
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, exitKirk));
		}
		
		private function exitKirk():void
		{
			SceneUtil.setCameraTarget(this, carson);
			super.removeEntity(kirk);
			carson.get(Dialog).sayById("gave star coffee");
		}
		
		private function createCup(url:String):void
		{
			var cup:MovieClip = super.getAsset(url, true,true) as MovieClip;
			
			kirkCup = EntityUtils.createMovingEntity(this, cup, _hitContainer);
			kirkCup.add(new Id("kirkCoffeeCup"));
			
			var cupPosition:Spatial = kirkCup.get(Spatial);
			
			cupPosition.width /= 4;
			cupPosition.height /= 4;
		}
		
		private function giveKirkCoffee():void
		{
			SkinUtils.setSkinPart(kirk, SkinUtils.ITEM,"kirk_Coffee",false);
			super.shellApi.removeItem(backlot.KIRK_COFFEE_CUP);
			CharUtils.setAnim(kirk, Drink);
			var kirkTimeline:Timeline = kirk.get(Timeline);
			kirkTimeline.handleLabel("end",finishDrinkingCoffee,true);
		}
		
		private function finishDrinkingCoffee():void
		{
			Dialog(kirk.get(Dialog)).sayById("courtesy");
		}
		
		private function throwCup(url:String):void
		{
			createCup(url);
			
			var cupPosition:Spatial = kirkCup.get(Spatial);
			
			cupPosition.x = 1200;
			cupPosition.y = 550;
			
			var cupMotion:Motion = kirkCup.get(Motion);
			
			cupMotion.velocity = new Point(250, -500);
			cupMotion.acceleration.y = MotionUtils.GRAVITY;
			cupMotion.rotationVelocity = -300;
			
			var threshold:Threshold = new Threshold("y", ">");
			threshold.threshold = this.player.get(Spatial).y + 25;
			threshold.entered.addOnce(hitGround);
			kirkCup.add(threshold);
			
			SceneUtil.setCameraTarget(this, kirkCup);
		}
		
		private function hitGround():void
		{
			shellApi.triggerEvent("cup_dropped");
			kirkCup.remove(Motion);
			kirkCup.get(Spatial).rotation = 90;
			SceneUtil.setCameraTarget(this, player);
			SceneUtil.lockInput(this, false);
			
			kirkCup.add( new SceneInteraction());
			InteractionCreator.addToEntity(kirkCup,[InteractionCreator.CLICK],this._hitContainer["cup_mc"]);
			var interaction:SceneInteraction = kirkCup.get(SceneInteraction);
			
			ToolTipCreator.addToEntity(kirkCup);
			
			interaction.reached.addOnce(getCup);
		}
		
		private function getCup(player:Entity, cup:Entity):void
		{
			this.shellApi.getItem(backlot.KIRK_COFFEE_CUP, null, true);
			shellApi.setUserField("coffee1","[7,1,5]",shellApi.island,true);
			this.removeEntity(kirkCup);
		}
		
		private function setupTrailerDoor():void
		{
			this.trailerDoor = EntityUtils.createSpatialEntity(this,_hitContainer["trailerDoor"],_hitContainer);
			TimelineUtils.convertClip(this._hitContainer["trailerDoor"], this,trailerDoor, null, false);
			doorTimline = trailerDoor.get(Timeline);
			trailerDoor.add(new Id("trailerDoor"));
			
			if(shellApi.checkEvent(backlot.KIRK_RETURNS_STAGE_1))
				Timeline(trailerDoor.get(Timeline)).gotoAndStop("end");
			
			trailerDoorDoor = super.getEntityById("door1");
			var sceneInteraction:SceneInteraction = trailerDoorDoor.get(SceneInteraction);
			sceneInteraction.reached.removeAll();
			sceneInteraction.reached.add(approachDoor);
			
			Display(trailerDoor.get(Display)).moveToBack();
		}
		
		private function approachDoor(player:Entity, door:Entity):void
		{
			var kirkDialog:Dialog = kirk.get(Dialog);
			var playerDialog:Dialog = super.player.get(Dialog);
			if(super.shellApi.checkEvent(backlot.CARSON_RETURNS_STAGE_1))
			{
				Door(door.get(Door)).open = true;
				return;
			}
			if(super.shellApi.checkEvent(backlot.DISRUPTED_KIRK))
			{
				if(super.shellApi.checkEvent(backlot.GET_KIRK_COFFEE))
				{
					SceneUtil.lockInput(this);
					knockOnDoor(kirk, "go_away");
				}
				else
				{
					if(!super.shellApi.checkEvent(backlot.KIRK_CUP_FILLED))
					{
						knockOnDoor(kirk,"you_can_refill");
					}
					else
					{
						if(super.shellApi.checkEvent(backlot.MADE_TO_ORDER))
						{
							SceneUtil.lockInput(this);
							knockOnDoor(player,"right");
						}
						else
						{
							knockOnDoor(player,"wrong");
						}
					}
				}
			}
			else
			{
				knockOnDoor(player,"no_one_home");
			}
		}
		
		private function knockOnDoor(talker:Entity = null, nextLine:String =""):void
		{
			shellApi.triggerEvent("knock");
			CharUtils.setAnim(player,Knock);
			Timeline(player.get(Timeline)).handleLabel("ending",Command.create(knock, talker,nextLine),true);
		}
		
		private function knock(talker:Entity, nextLine:String):void
		{
			Dialog(talker.get(Dialog)).sayById(nextLine);
		}
		
		private function labelReachedDoor():void
		{
			doorTimline.stop();
			kirk.get(Display).visible = true;
			kirk.get(Spatial).x = trailerDoorDoor.get(Spatial).x;
			giveKirkCoffee();
		}
		
		private function setupEgg():void
		{
			var egg:Entity = this.getEntityById("eggInteraction");
			
			TimelineUtils.convertClip(this._hitContainer["eggInteraction"], this, egg, null, false);
			
			var interaction:SceneInteraction = egg.get(SceneInteraction);
			interaction.approach = false;
			
			function eggClicked(player:Entity, egg:Entity, timeline:Timeline):void { if(!timeline.playing) timeline.gotoAndPlay(0); }
			interaction.triggered.add(Command.create(eggClicked, egg.get(Timeline)));
		}
	}
}