package game.scenes.carnival.ridesEmpty
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Attack;
	import game.data.animation.entity.character.Chicken;
	import game.data.comm.PopResponse;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.CarnivalEvents;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class RidesEmpty extends PlatformerGameScene
	{
		private var _events:CarnivalEvents;
		private var trucks:Entity;
		private var tires:Vector.<Entity>;
		private var curtain:Entity;
		private var ringMaster:Entity;
		public function RidesEmpty()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/ridesEmpty/";
			
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
			ringMaster = getEntityById("ringmaster");
			_events = shellApi.islandEvents as CarnivalEvents;
			getEntityById("man").remove(Sleep);
			getEntityById("woman").remove(Sleep);

			shellApi.eventTriggered.add(handleEvents);
			if(!shellApi.checkEvent(_events.SET_MORNING)){
				shellApi.triggerEvent(_events.SET_MORNING, true);
			}
			if(!shellApi.checkHasItem(_events.MEDAL_CARNIVAL)){
				truckSetup();
				var edgar:Entity = getEntityById("edgar");
				SceneInteraction(edgar.get(SceneInteraction)).triggered.addOnce(lock);
				ringMaster.get(Display).moveToBack();
				//curtain = TimelineUtils.convertClip(_hitContainer["curtain"],this);
				//curtain.get(Timeline).stop();
			}else{
				hideCarnies();
			}
			
			if(shellApi.checkEvent(_events.INTRO_DAY_2)){
				if(!shellApi.checkEvent(_events.STARTED_BONUS_QUEST)){
					if( player.get(Spatial).x > 3000){
						enterMarnie(false);
					}
					else{
						enterMarnie();
					}
				}
				else{
					hideTownies();
				}
			}
			if(shellApi.checkEvent(_events.STARTED_BONUS_QUEST)){
				hideTownies();
			}
			
			super.loaded();
		}		
		
		private function lock(...p):void
		{
			SceneUtil.lockInput(this, true);
		}
		
		private function handleEvents(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(!shellApi.checkEvent(_events.STARTED_BONUS_QUEST)){
				if(event == "reveal_chicken_man"){
					showChickenMan();
				}
				else if(event == "gotItem_medal_carnival"){
					//shellApi.completedIsland();
					edLeaves();
				}
				else if(event == _events.INTRO_DAY_2){
					towniesLeave();
				}
			}
			if(event == "agree_to_day_2"){
				SceneUtil.lockInput(this, false, false);
				checkStartDay2();
			}
			
		}
		
		// check for member block on bonus quest
		private function checkStartDay2():void
		{
			var bonusPopup:BonusQuestPopup = super.addChildGroup( new BonusQuestPopup( super.overlayContainer )) as BonusQuestPopup;
			bonusPopup.id = "bonusQuest";
		}
		
		private function towniesLeave():void
		{
			var man:Entity = getEntityById("man");
			var woman:Entity = getEntityById("woman");
			var sissy:Entity = getEntityById("sissy");
			if(man)
			CharUtils.moveToTarget(man, 2000, 1740, false);
			if(woman)
			CharUtils.moveToTarget(woman, 2050, 1740, false, enterMarnie);
		}
		
		private function hideTownies():void
		{
			removeEntity(getEntityById("man"));
			removeEntity(getEntityById("woman"));
			removeEntity(getEntityById("sissy"));
		}
		
		private function enterMarnie(rightSide:Boolean = true):void
		{
			SceneUtil.lockInput(this,true);
			var playerSpatial:Spatial = player.get(Spatial);
			var marnie:Entity = getEntityById("marnie");
			if(rightSide){
				EntityUtils.position(marnie, playerSpatial.x + 700, 1600); 
				CharUtils.moveToTarget(marnie, playerSpatial.x +150, 1680, false, marnieTalk);
			}else{
				EntityUtils.position(marnie, playerSpatial.x - 700, 1600); 
				CharUtils.moveToTarget(marnie, playerSpatial.x -150, 1680, false, marnieTalk);
			}
			hideTownies();
		}
		
		private function marnieTalk(char:Entity = null):void
		{
			if(char.get(Spatial).x > player.get(Spatial).x){
				CharUtils.setDirection(player, true);
			}
			else{
				CharUtils.setDirection(player, false);
			}
			Dialog(char.get(Dialog)).sayById("day2");
		}
		
		private function edLeaves():void
		{
			var ed:Entity = getEntityById("edgar");
			if(ed)
			CharUtils.moveToTarget(ed,5300,1720,true,rollOut);
		}
		
		private function showChickenMan(...p):void
		{
			// pull curtain back
			var ed:Entity = getEntityById("edgar");
			CharUtils.setDirection(ed, true);
			CharUtils.setAnim(ed, Attack);
			// pull curtain
			Timeline(ed.get(Timeline)).handleLabel("trigger",pullCurtain,true);
			SceneUtil.setCameraTarget(this,ringMaster);
		}
		
		private function pullCurtain(...p):void
		{
			var tl:Timeline = curtain.get(Timeline);
			tl.gotoAndPlay("show");
			tl.handleLabel("end",cluck);
		}
		
		private function cluck(...p):void
		{
			//CharUtils.setAnim(ringMaster, Chicken);
			//ingMaster.get(Dialog).sayById("cluck");
			CharUtils.setDirection( getEntityById("edgar"),false);
		}
		
		// clean up npcs and leave scene
		private function rollOut(...p):void
		{
			SceneUtil.setCameraTarget(this,player);
			removeEntity(getEntityById("edgar"));
			removeEntity(getEntityById("ferrisWheel"));
			removeEntity(getEntityById("foodStand"));
			var ringMot:Motion = new Motion();
			ringMaster.add(ringMot);
			ringMot.acceleration.x = 80;
			// play sound, spin wheels, leave scene
			shellApi.triggerEvent("rollOut");
			trucks.get(Motion).acceleration.x = 80;
			var childs:Children = trucks.get(Children);
			for each (var tire:Entity in tires)
			{
				var tireMotion:Motion = tire.get(Motion);
				tireMotion.acceleration.x = 80;
				tireMotion.rotationAcceleration = 60;
			}
			SceneUtil.addTimedEvent(this,new TimedEvent(4,1,playerSayMyFriend));
		}
		
		private function playerSayMyFriend():void
		{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("myfriend");
		}
		private function truckSetup():void
		{
			addSystem(new ThresholdSystem());
			tires = new Vector.<Entity>();
			var clip:MovieClip = _hitContainer["trucks"];
			trucks = EntityUtils.createMovingEntity(this,convertToBitmapSprite(clip).sprite);
			var threshHold:Threshold = new Threshold("x", ">");
			threshHold.threshold = 6000;
			threshHold.entered.addOnce(removeTrucks);
			trucks.add(threshHold);
			var t:int = 0;
			while(t<28 && _hitContainer["tire"+t] != null){
				var tireClip:MovieClip = _hitContainer["tire"+t];
				var tire:Entity = EntityUtils.createMovingEntity(this,tireClip);
				tires.push(tire);
				t++;
			}
		}
		
		private function removeTrucks(...p):void
		{
			AudioUtils.getAudio(this,"sceneSound").stop("effects/tractor_01_L.mp3","effects");
			removeEntity(trucks);
			removeEntity(ringMaster);
			for each (var tire:Entity in tires) 
			{
				removeEntity(tire);
			}
			
			shellApi.completedIsland('', onCompletions);
		}

		private function onCompletions(response:PopResponse):void
		{			
			SceneUtil.lockInput(this, false);
			
			var islandEndingPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer);
			islandEndingPopup.hasBonusQuestButton = true;
			islandEndingPopup.popupRemoved.addOnce(startDay2);
			this.addChildGroup(islandEndingPopup);
			
			//SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, startDay2));
		}
		
		private function startDay2():void
		{
			// day 2 start
			goTalkToNpc(getEntityById("man"),null,null,true);
		}
		
		private function hideCarnies():void
		{
			removeEntity(getEntityById("edgar"));
			removeEntity(getEntityById("ferrisWheel"));
			removeEntity(getEntityById("foodStand"));
			removeEntity(ringMaster);
			//_hitContainer["curtain"].visible = false;
			_hitContainer["trucks"].visible = false;
			for (var i:int = 0; i < 28; i++) 
			{
				_hitContainer["tire"+i].visible = false;
			}
		}	
		
		// force talk to npc
		private function goTalkToNpc(npc:Entity, handleFinish:Function = null, handleReached:Function = null, lock:Boolean = false):void
		{
			var dialog:Dialog = npc.get(Dialog);
			if(npc!=null)
			{
				var interaction:Interaction = npc.get(Interaction);
				interaction.click.dispatch(npc);
				if(handleReached){
					SceneInteraction(npc.get(SceneInteraction)).reached.addOnce(handleReached);
				}
				if(handleFinish){
					dialog.complete.addOnce(handleFinish);
				}
				if(lock){
					SceneUtil.lockInput(this,true);
				}				
			}
		}
		
	};
};