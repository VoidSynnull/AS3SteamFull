package game.scenes.time.greece2{
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.game.GameEvent;
	import game.scenes.time.TimeEvents;
	import game.data.scene.characterDialog.Conversation;
	import game.data.scene.characterDialog.DialogData;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.greece2.components.SmokeWisp;
	import game.scenes.time.greece2.components.smokePoint;
	import game.scenes.time.greece2.systems.SmokeWispSystem;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.scenes.time.shared.emitters.Fire;
	import game.scenes.time.shared.emitters.FireSmoke;
	import game.scenes.time.shared.emitters.FlickeringLight;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	
	public class Greece2 extends PlatformerGameScene
	{
		public function Greece2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/greece2/";
			
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
			addSystem(new SmokeWispSystem(),SystemPriorities.update);
			tEvents = events as TimeEvents;
			torchFlames();
			incenseSmoke();
			setupGreekTranslations();
			InitProphesyDialog();
			placeTimeDeviceButton();
		}
		
		private function setupGreekTranslations():void
		{ 
			var text:Entity = EntityUtils.createSpatialEntity(this, super._hitContainer["sign1"]);
			text = TimelineUtils.convertClip(super._hitContainer["sign1"], this, text);			
			var interaction:Interaction = InteractionCreator.addToEntity(text,[InteractionCreator.CLICK],super._hitContainer["sign1"]);
			interaction.click.add(toggleTextTrans);
			ToolTipCreator.addUIRollover(text,ToolTipType.CLICK);
		}
		
		private function toggleTextTrans(text:Entity):void
		{
			var txt:Timeline = (text.get(Timeline)as Timeline);
			if(txt.currentIndex == 0)
			{
				(text.get(Timeline)as Timeline).gotoAndStop("english");
			}
			else
			{
				(text.get(Timeline)as Timeline).gotoAndStop("greek");
			}		
		}

		public function torchFlames():void
		{
			var name:String = "fireInteraction";
			var fire:Fire = new Fire();
			fire.init(5, new RectangleZone(-13, -4, 13, -4));
			EmitterCreator.create(this, this._hitContainer[name], fire);
			var smoke:FireSmoke = new FireSmoke();
			smoke.init(9, new LineZone(new Point(-2, -20), new Point(2, -40)), new RectangleZone(-10, -5, 10, -5));
			EmitterCreator.create(this, this._hitContainer[name], smoke);			
			var fireEnt:Entity = getEntityById(name);
			SceneInteraction(fireEnt.get(SceneInteraction)).reached.add(fireComment);
			lightFlicker();
		}
		
		private function fireComment(entity:Entity, ent2:Entity):void{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("fireHot");
		}
		
		private function lightFlicker():void
		{
			var light:FlickeringLight = new FlickeringLight();
			light.init(300);
			EmitterCreator.create(this, super._hitContainer, light, 350, 557);
		}
		
		// init smoke wisps
		private function incenseSmoke():void
		{
			for (var i:int = 0; i < 5; i++) 
			{
				var smokeWisp:SmokeWisp = new SmokeWisp();
				smokeWisp.lineMc = _hitContainer["smoke"+i];
				smokeWisp.shiftRange = 20 + 5*i;
				smokeWisp.drawPoints = new Vector.<smokePoint>();
				//add
				var smokeEnt:Entity = EntityUtils.createSpatialEntity(this,smokeWisp.lineMc);
				smokeEnt.add(smokeWisp);
			}			
		}		
		
		private function switchAnswer(prophecies:Dialog, event:String):Boolean
		{
			if(shellApi.checkItemUsedUp(tEvents.GOLDEN_VASE)){
				var answer:String = "N";
				var dialog:* = DialogData(prophecies.getDialog(event + "R"));
				if(dialog != null){
					answer = dialog.dialog;
					Conversation(prophecies.current).questions[0].answer.dialog = answer;
					//Conversation(prophecies.current).questions[0].question.dialog = "Please Help Me!";
					if(answer != "N"){
						return true;
					}
				}
			}
			return false;
		}
		
		private function switchAnswers(prophecies:Dialog, items:Vector.<String>):Boolean
		{
			var answer:String;
			for each (var event:String in items) 
			{
				// cleanup answers
				switch(event)
				{
					// pick complete game events over other answers
					case GameEvent.HAS_ITEM + tEvents.MEDAL_TIME:
						switchAnswer(prophecies,event);
						return true;
						break;
					case tEvents.TIME_REPAIRED:
						switchAnswer(prophecies,event);
						return true;
						break;
					//cut out answerless item events
					case GameEvent.HAS_ITEM + tEvents.GLIDER:	
					case GameEvent.HAS_ITEM + tEvents.TIME_DEVICE:	
					case GameEvent.HAS_ITEM + tEvents.WARRIOR_MASK:	
					case GameEvent.HAS_ITEM+ tEvents.PRINTOUT:	
					case GameEvent.HAS_ITEM + tEvents.VIKINGSUIT:	
					case GameEvent.HAS_ITEM+ tEvents.GUNPOWDER:	
					// ignore vase
					case GameEvent.HAS_ITEM + tEvents.GOLDEN_VASE:
					case tEvents.RETURNED + tEvents.GOLDEN_VASE:	
						items.splice(items.indexOf(event),1);
						break;
				};
			}		
			if(items.length > 10){
				// give the last answer event that was completed
				switchAnswer(prophecies, items[items.length - 1]);
				return true;
			}else if(items.length > 0)
			{
				// pick random answer to give player
				var rand:int =  Math.random() *  (items.length - 1);
				switchAnswer(prophecies, items[rand]);
				return true;
			}			
			return false;
		}
		
		// set answer to correct prophecy for current events
		private function InitProphesyDialog():void
		{			
			var prophecies:Dialog = Dialog(getEntityById("char1").get(Dialog));
			var currEvents:Vector.<String> = shellApi.gameEventManager.getEvents(shellApi.island);
			var validEvents:Vector.<String> = new Vector.<String>();
			// collect possible answers for the oracle
			// return events are answers by default
			validEvents.push(tEvents.RETURNED + tEvents.AMULET); 
			validEvents.push(tEvents.RETURNED + tEvents.DECLARATION); 
			validEvents.push(tEvents.RETURNED + tEvents.GOGGLES); 
			validEvents.push(tEvents.RETURNED + tEvents.GOLDEN_VASE); 
			validEvents.push(tEvents.RETURNED + tEvents.NOTEBOOK); 
			validEvents.push(tEvents.RETURNED + tEvents.PHONOGRAPH); 
			validEvents.push(tEvents.RETURNED + tEvents.SALT_ROCKS); 
			validEvents.push(tEvents.RETURNED + tEvents.SILVER_MEDAL); 
			validEvents.push(tEvents.RETURNED + tEvents.STATUETTE); 
			validEvents.push(tEvents.RETURNED + tEvents.STONE_BOWL);
			validEvents.push(tEvents.RETURNED + tEvents.SUNSTONE);
			for each (var event:String in currEvents) 
			{
				if(event.substring(0,GameEvent.HAS_ITEM.length) == GameEvent.HAS_ITEM){
					validEvents.push(event);
				}
				
				if(event.substring(0,tEvents.RETURNED.length) == tEvents.RETURNED){
					// pull out actually returned items
					validEvents.splice(validEvents.indexOf(event),1);
				}
				
				/*
				if(super.shellApi.checkItemUsedUp(event))
				{
					validEvents.splice(validEvents.indexOf(event),1);
				}
				*/
				if(event == tEvents.TIME_REPAIRED){
					validEvents.push(event); 
				}
			}
			// change oracle's answer
			switchAnswers(prophecies, validEvents);
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
		
		private var tEvents:TimeEvents;
		private var timeButton:Entity;
	}
}