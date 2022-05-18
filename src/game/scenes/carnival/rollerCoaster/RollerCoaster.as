package game.scenes.carnival.rollerCoaster
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.hit.Zone;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Drink;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Stand;
	import game.scenes.carnival.CarnivalEvents;
	import game.particles.emitter.GreenSmoke;
	import game.particles.emitter.PoofBlast;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.counters.Blast;
	
	public class RollerCoaster extends PlatformerGameScene
	{
		private var _events:CarnivalEvents;
		private var dan:Entity;
		private var talkZone:Entity;
		private var shrooms:Entity;
		private var potionUsed:Boolean = false;
		private var danDialog:Dialog;
		private var greenSmoke:GreenSmoke;
		private var delta:Point = new Point(25,30);
		
		public function RollerCoaster()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/rollerCoaster/";
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
			addSystem(new ThresholdSystem());
			_events = events as CarnivalEvents;
			shellApi.eventTriggered.add(handleEvents);
			dan = getEntityById("dan");
			danDialog = dan.get(Dialog);
			if(!shellApi.checkHasItem(_events.CHEMICAL_X_FORMULA)){
				SceneUtil.addTimedEvent(this, new TimedEvent(1.5,1,findDan));
				SceneUtil.lockInput(this, true);
			}
			setupTalkTrigger();
			setupShrooms();
			super.loaded();
		}
		
		private function findDan():void
		{
			player.get(Dialog).sayById("where");
			player.get(Dialog).complete.addOnce(seeDan);
		}
		
		private function seeDan(...p):void
		{
			SceneUtil.setCameraTarget(this,dan);
			SceneUtil.addTimedEvent(this, new TimedEvent(2,1,lookPlayer));
		}
		
		private function lookPlayer():void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this,player);
		}
		
		private function handleEvents(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event)
			{
				case _events.DAN_SHOW_TAIL:
					makePoof(EntityUtils.getPosition(dan));
					break;
				case "gotItem_"+_events.CHEMICAL_X_FORMULA:
					SceneUtil.lockInput(this,false,false);
					break;
				case "use_chemical_x":
					talkToDan("","",true);
					break;
				case "dan_drink_potion":
					drinkPotion();
					break;
				case "dan_show_horns":
					makePoof(EntityUtils.getPosition(dan));
					SkinUtils.setSkinPart(dan,SkinUtils.HAIR,"mc_dan2",true);
					break;
				case "enter_search_party":
					SceneUtil.addTimedEvent(this, new TimedEvent(0.5,1,enterSearchParty));
					break;
				case "exit_search_party":
					SceneUtil.setCameraTarget(this, player);
					SceneUtil.addTimedEvent(this, new TimedEvent(1,1,exitSearchParty));
					break;
			}
		}
		
		private function setupTalkTrigger():void
		{
			talkZone = getEntityById("zone1");
			if(!shellApi.checkEvent(_events.DAY_2_COMPLETE)&&!shellApi.checkHasItem(_events.CHEMICAL_X_FORMULA)){
				var zone:Zone = talkZone.get(Zone);
				zone.entered.addOnce(talkToDan);
			}
		}
		
		private function talkToDan(zone:String="", thing:String="", giveItem:Boolean = false):void
		{
			SceneUtil.lockInput(this,true,false);
			var interaction:Interaction = dan.get(Interaction);
			interaction.click.dispatch(dan);
			if(giveItem){
				dan.get(SceneInteraction).reached.addOnce(giveChemicalX);
			}
		}
		
		private function setupShrooms():void
		{
			shrooms = getEntityById("shroomInteraction");
			shrooms = TimelineUtils.convertClip(shrooms.get(Display).displayObject, this, shrooms,null,false);
			if(!shellApi.checkHasItem(_events.MUSHROOMS)){
				var inter:SceneInteraction = shrooms.get(SceneInteraction);
				inter.reached.addOnce(harvestShrooms);
				shrooms.get(Timeline).gotoAndStop("start");
			}else{
				shrooms.get(Timeline).gotoAndStop("picked");
			}
		}
		
		private function harvestShrooms(...p):void
		{
			shrooms.get(Timeline).gotoAndStop("picked");
			shellApi.triggerEvent("pick_shroom");
			shellApi.getItem(_events.MUSHROOMS,null,true);
		}
		
		public function makePoof(pos:Point):void
		{
			var puff:PoofBlast = new PoofBlast();
			puff.init(25,7,0x6FC970);
			EmitterCreator.create(this,_hitContainer,puff,pos.x,pos.y);		
			//poof sound
			shellApi.triggerEvent("poof_sound");
		}
		
		private function giveChemicalX(...p):void
		{
			shellApi.removeItem(_events.CHEMICAL_X);
			ItemGroup(getGroupById("itemGroup")).takeItem(_events.CHEMICAL_X,"dan","");
			shellApi.triggerEvent("gave_potion");
		}
		
		private function drinkPotion():void
		{
			SceneUtil.lockInput(this, true);
			CharUtils.setAnim(dan, Drink, false, 0, 0, false);
			CharUtils.getTimeline(dan).handleLabel("setColor",Command.create(shellApi.triggerEvent,"dan_drank_potion"));
			danDialog.complete.addOnce(potionFailed);
			//fancy particles
			greenSmoke = new GreenSmoke();
			greenSmoke.init();
			EmitterCreator.create( this, EntityUtils.getDisplayObject(dan), greenSmoke, 0, -20 );
		}
		
		private function potionFailed(...p):void
		{
			if(!potionUsed){
				potionUsed = true;
				greenSmoke.counter = new Blast(10);
				CharUtils.setAnim(dan, Stand, false, 0, 0, true);
				SceneUtil.addTimedEvent(this, new TimedEvent(1.4,1,potionFailed2));
			}
		}
		
		private function potionFailed2():void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(1.6,1,Command.create(danDialog.sayById,"dan_potion_failed")));
			SceneUtil.addTimedEvent(this, new TimedEvent(1.6,1,Command.create(CharUtils.setAnim, dan, Grief,false)));
			shellApi.triggerEvent("dan_show_horns");
		}
		
		private function enterSearchParty():void
		{
			SceneUtil.setCameraPoint(this, _hitContainer["cam"].x,_hitContainer["cam"].y);
			// more npcs, great...
			SceneUtil.lockInput(this, true);
			var marnie:Entity = getEntityById("marnie");
			var man:Entity = getEntityById("man");
			var woman:Entity = getEntityById("woman");
			var bubby:Entity = getEntityById("bubby");
			var sissy:Entity = getEntityById("sissy");
			var speak:Function = Command.create(marnieSpeaks,marnie,man,woman,bubby);
			CharUtils.moveToTarget(marnie,_hitContainer["nav0"].x, _hitContainer["nav0"].y,false,null,delta);
			CharUtils.moveToTarget(man,_hitContainer["nav1"].x, _hitContainer["nav1"].y,false,null,delta);
			CharUtils.moveToTarget(woman,_hitContainer["nav2"].x, _hitContainer["nav2"].y,false,null,delta);
			CharUtils.moveToTarget(bubby,_hitContainer["nav3"].x, _hitContainer["nav3"].y,false,null,delta);
			CharUtils.moveToTarget(sissy,_hitContainer["nav4"].x, _hitContainer["nav4"].y,false,speak,delta);
		}
		
		private function marnieSpeaks(...p):void
		{
			for each (var char:Entity in p) 
			{
				CharUtils.setDirection(char, true);
			}
			p[1].get(Dialog).sayById("startEnd");
		}
		
		private function exitSearchParty():void
		{
			// more npcs, great...
			var man:Entity = getEntityById("man");
			var woman:Entity = getEntityById("woman");
			var bubby:Entity = getEntityById("bubby");
			var sissy:Entity = getEntityById("sissy");
			var path:Vector.<Point> = new <Point>[new Point(_hitContainer["nav4"].x, _hitContainer["nav4"].y),new Point(_hitContainer["nav5"].x, _hitContainer["nav5"].y)];
			var thresh:Threshold = new Threshold("y","<");
			thresh.threshold = _hitContainer["nav5"].y+5;
			thresh.entered.addOnce(Command.create(removeChar,man));
			CharUtils.followPath(man, path, null,true,false,delta);
			man.add(thresh);
			thresh = new Threshold("y","<");
			thresh.threshold = _hitContainer["nav5"].y+5;
			thresh.entered.addOnce(Command.create(removeChar,woman));
			CharUtils.followPath(woman, path, null,true,false,delta);
			woman.add(thresh);
			thresh = new Threshold("y","<");
			thresh.threshold = _hitContainer["nav5"].y+5;
			thresh.entered.addOnce(Command.create(removeChar,sissy));
			CharUtils.followPath(sissy, path, null,true,false,delta);
			sissy.add(thresh);
			thresh = new Threshold("y","<");
			thresh.threshold = _hitContainer["nav5"].y+5;
			thresh.entered.addOnce(Command.create(removeChar,bubby,true));
			CharUtils.followPath(bubby, path, null,true,false,delta);
			bubby.add(thresh);
		}
		
		private function removeChar(char:Entity, last:Boolean = false, isDan:Boolean = false):void
		{
			removeEntity(char);
			if(last){
				danDialog.sayById("keep");
				danDialog.complete.addOnce(danLeaves);
			}else if(isDan){
				// end bonus quest
				shellApi.triggerEvent(_events.DAY_2_COMPLETE, true);
				SceneUtil.lockInput(this, false);
			}
		}		
		
		private function danLeaves(...p):void
		{
			var marnie:Entity = getEntityById("marnie");
			var thresh:Threshold = new Threshold("y","<");
			thresh.threshold = _hitContainer["nav5"].y+5;
			thresh.entered.addOnce(Command.create(removeChar,marnie));
			var path:Vector.<Point> = new <Point>[new Point(_hitContainer["nav1"].x, _hitContainer["nav1"].y),new Point(_hitContainer["nav4"].x, _hitContainer["nav4"].y),new Point(_hitContainer["nav5"].x, _hitContainer["nav5"].y)];
			CharUtils.followPath(marnie, path, null,true,false,delta);
			marnie.add(thresh);
			thresh = new Threshold("y","<");
			thresh.threshold = _hitContainer["nav5"].y+5;
			thresh.entered.addOnce(Command.create(removeChar,dan,false,true));
			CharUtils.followPath(dan, path, null,true,false,delta);
			dan.add(thresh);
		}		
		
		
	};
};