package game.scenes.backlot.coffeeShopRight
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.entity.character.Stomp;
	import game.scenes.backlot.BacklotEvents;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.shared.emitters.CoffeeSteam;
	import game.scenes.backlot.shared.popups.CoffeePopup;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class CoffeeShopRight extends PlatformerGameScene
	{
		public function CoffeeShopRight()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/coffeeShopRight/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var counterNpc:Entity;
		private var willy:Entity;
		
		// all assets ready
		override public function loaded():void
		{
			_events = super.events as BacklotEvents;
			super.loaded();
			
			setUpNpcs();
			setupCoffeeMachine();
			setupMilk();
			
			super.shellApi.eventTriggered.add( onEventTriggered );
		}
		
		private function setUpNpcs():void
		{
			counterNpc = getEntityById("char1");
			willy = getEntityById("char2");
			
			if(shellApi.checkEvent(_events.FOUND_VILLAIN))
				removeEntity(willy);
			
			Display(counterNpc.get(Display)).moveToBack();
		}
		
		private function onEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "stop_and_listen")
			{
				SceneUtil.lockInput(this);
			}
			if(event == _events.POUR_COFFEE_RIGHT)
			{
				SceneUtil.lockInput(this, false);
				_coffeePopup = super.addChildGroup( new CoffeePopup( super.overlayContainer )) as CoffeePopup;
			}
			if(event == "you_know")
			{
				//replays animation after every word balloon
				CharUtils.setAnim(super.getEntityById("char2"), Stomp);
			}
			if(event == _events.BLACK_HAT)
			{
				SceneUtil.lockInput(this);
				CharUtils.moveToTarget(player, willy.get(Spatial).x, willy.get(Spatial).y, false, giveWillyHat);
			}
			if(event == _events.FOUND_VILLAIN)
			{
				CharUtils.moveToTarget(willy, getEntityById("door1").get(Spatial).x, getEntityById("door1").get(Spatial).y,false, exitWilly);
			}
		}
		
		private function exitWilly(entity:Entity):void
		{
			SceneUtil.lockInput(this, false);
			removeEntity(willy);
		}
		
		private function giveWillyHat(entity:Entity):void
		{
			shellApi.removeItem(_events.BLACK_HAT);
			SceneUtil.lockInput(this);
			SkinUtils.setSkinPart(willy, SkinUtils.HAIR, "bl_villain",true);
			Dialog(willy.get(Dialog)).sayById("at last");
		}
		
		private function setupCoffeeMachine():void
		{
			var machine:Entity = this.getEntityById("coffeeMachineInteraction");
			var clip:MovieClip = machine.get(Display).displayObject;
			
			TimelineUtils.convertClip(clip, this, machine);
			var timeline:Timeline = machine.get(Timeline);
			timeline.gotoAndStop(0);
			timeline.handleLabel("coffee", this.startParticles, false);
			timeline.handleLabel("end", this.stopParticles, false);
			
			var interaction:SceneInteraction = machine.get(SceneInteraction);
			interaction.triggered.add(Command.create(this.shakeMachine, timeline));
			interaction.approach = false;
			
			var steam:CoffeeSteam = new CoffeeSteam();
			steam.init();
			
			var coffee:Entity = EmitterCreator.create(this, this._hitContainer, steam, 0, 0, machine, "steam", null, false);
			
			var spatial:Spatial = coffee.get(Spatial);
			spatial.x = 1490;
			spatial.y = 362;
		}
		
		private function shakeMachine(player:Entity, machine:Entity, timeline:Timeline):void
		{
			shellApi.triggerEvent(_events.MACHINE_WORKING);
			timeline.gotoAndPlay("begin");
		}
		
		private function startParticles():void
		{
			var emitter:Emitter = this.getEntityById("steam").get(Emitter);
			emitter.start = true;
			emitter.emitter.counter.resume();
		}
		
		private function stopParticles():void
		{
			var emitter:Emitter = this.getEntityById("steam").get(Emitter);
			emitter.emitter.counter.stop();
		}
		
		private function setupMilk():void
		{
			for(var i:int = 1; i <= 2; i++)
			{
				var jug:Entity = this.getEntityById("jugInteraction" + i);
				
				TimelineUtils.convertClip(this._hitContainer["milk" + i], this, jug);
				
				var timeline:Timeline = jug.get(Timeline);
				
				var interaction:SceneInteraction = jug.get(SceneInteraction);
				interaction.triggered.add(Command.create(this.pourMilk, timeline));
				interaction.approach = false;
			}
		}
		
		private function pourMilk(player:Entity, jug:Entity, timeline:Timeline):void
		{
			shellApi.triggerEvent(_events.POUR);
			timeline.gotoAndPlay(0);
		}
		
		private var _coffeePopup:CoffeePopup;
		private var _events:BacklotEvents;
	}
}