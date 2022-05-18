package game.scenes.con2.hallways
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTipActive;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.TimedEvent;
	import game.scenes.con2.Con2Events;
	import game.scenes.con2.lobby.Lobby;
	import game.scenes.con2.shared.Poptropicon2Scene;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Hallways extends Poptropicon2Scene
	{
		private var _events:Con2Events;
		
		private var DOOR_SOUND:String = SoundManager.EFFECTS_PATH + "openDoor_pushBar.mp3";
		
		private var sasha:Entity;
		
		private var doors:Array	= null;
		private var sashaClones:Array 	= null;
		private var npcPositions:Array = null;
		
		private var doorIndex:int = 0;
		private var correctDoorIndex:int = 0;
		private var stage:int = 0;
		private var stageCount:int = 3;
		private var firstVisit:Boolean = true;
		private var center:Entity;
		
		public function Hallways()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con2/hallways/";
			//showHits = true;
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
			setupBGClutter();
			setupDecorativeNpcs();
			setupDoorPuzzle();
			
			super.loaded();
		}
		
		private function setupDecorativeNpcs():void
		{
			var char:Entity;
			var positions:Array = shuffleArray([691,520,760,250,420,170]);
			var chars:Array = shuffleArray([getEntityById("person5"),getEntityById("person6"),getEntityById("person7"),getEntityById("person8"),getEntityById("person9"),getEntityById("person10")]);
			var visibleCount:int = GeomUtils.randomInt(2,4);
			for each (var e:Entity in chars) 
			{
				hideNpc(e);
			}
			for (var i:int = 0; i < visibleCount; i++) 
			{
				var spatial:Spatial = chars[i].get(Spatial);
				spatial.x = positions[i];
				showNpc(chars[i]);
			}	
		}
		
		private function setupDoorPuzzle(...p):void
		{
			center = EntityUtils.createSpatialEntity(this, _hitContainer["center"], _hitContainer);
			SceneUtil.setCameraTarget(this,center);
			
			SceneUtil.lockInput(this,true);
			//shuffle doors
			doors = shuffleArray([getEntityById("door2"),getEntityById("door3"),getEntityById("door4")]);
			correctDoorIndex = GeomUtils.randomInt(1,doors.length-1);
			
			setupNpcs();
			
			var door:Entity;
			var anim:Entity;
			for (var i:int = 2; i <= 4; i++) 
			{
				door = getEntityById("door"+i);
				SceneInteraction(door.get(SceneInteraction)).reached.removeAll();
				
				anim = getEntityById("animdoor"+i);
				if(!anim){
					anim = TimelineUtils.convertClip(_hitContainer["animdoor"+i],this,null,null,false);
				}
			}
			if(shellApi.checkEvent(_events.SASHA_LEFT_EXPO)){
				SceneUtil.addTimedEvent(this, new TimedEvent(1.4,1,runDoorPuzzle));
			}else{
				runNoPuzzle()
				returnPlayerControl();
				SceneUtil.addTimedEvent(this, new TimedEvent(1,1,sayMazeComment));
			}
		}
		
		private function sayMazeComment():void
		{
			var comment:int = 0;
			if(firstVisit){
				firstVisit = false;
				comment = 0;
			}else{
				comment = GeomUtils.randomInt(1,5);
			}
			Dialog(player.get(Dialog)).sayById("maze"+comment);
		}
		
		// set random posters and background stuff
		private function setupBGClutter():void
		{
			for (var i:int = 0; i < 5; i++) 
			{
				var entity:Entity = getEntityById("clutter"+i);
				if(entity == null){
					entity = EntityUtils.createDisplayEntity(this,_hitContainer["clutter"+i],_hitContainer);
					entity = BitmapTimelineCreator.convertToBitmapTimeline(entity);
					entity.add(new Id("clutter"+i));
				}
				Timeline(entity.get(Timeline)).gotoAndStop(GeomUtils.randomInt(0,5));
			}
		}
		
		private function setupNpcs():void
		{
			npcPositions = shuffleArray([165,455,735]);
			sasha = getEntityById("sasha");
			sasha.add(new LinkedEntity(doors[correctDoorIndex]));
			// npcs that aren't sasha
			sashaClones = shuffleArray([getEntityById("person1"),getEntityById("person2"),getEntityById("person3"),getEntityById("person4")]);
			for each (var e:Entity in sashaClones) 
			{
				hideNpc(e);
			}
			if(shellApi.checkEvent(_events.SASHA_LEFT_EXPO)){
				if(stage <= stageCount){
					if(stage > 0){
						if(stage > 2){
							sashaClones = sashaClones.slice(0,2);
						}else{
							sashaClones = sashaClones.slice(0,stage);
						}
						//position
						var ent:Entity;
						sasha.get(Spatial).x = npcPositions[0];
						for (var i:int = 0; i < sashaClones.length; i++)
						{
							ent = sashaClones[i];
							ent.get(Spatial).x = npcPositions[i+1];
							if(doorIndex == correctDoorIndex){
								doorIndex++;
							}
							// npc goes to door at same index
							ent.add(new LinkedEntity(doors[doorIndex]));
							doorIndex++;
							showNpc(ent);
						}
					}
					else{
						sashaClones = [];
					}
				}
			}
			else
			{
				// no sasha =  no puzzle
				hideNpc(sasha);
			}
			
		}
		
		private function runDoorPuzzle(...p):void
		{
			// set target door destination
			for(var i:int = 0; i<doors.length;i++){
				SceneInteraction(doors[i].get(SceneInteraction)).reached.removeAll();
				if(i == correctDoorIndex){
					SceneInteraction(doors[i].get(SceneInteraction)).reached.add(correctDoorReached);
				}else{				
					SceneInteraction(doors[i].get(SceneInteraction)).reached.add(wrongDoorReached);
				}
			}
			// start moving an npc
			sashaClones.splice(GeomUtils.randomInt(0,sashaClones.length-1),0,sasha);
			for (var j:int = 0; j < sashaClones.length; j++) 
			{
				moveToDoor(sashaClones[j],sashaClones[j].get(LinkedEntity).link,Command.create(npcDoorReached,j));
			}
		}
		
		// sets all doors to loop, no way to reach lobby
		private function runNoPuzzle(...p):void
		{
			for(var i:int = 0; i<doors.length;i++){
				SceneInteraction(doors[i].get(SceneInteraction)).reached.removeAll();				
				SceneInteraction(doors[i].get(SceneInteraction)).reached.add(wrongDoorReached);
			}
		}
		
		private function npcDoorReached(char:Entity, index:int):void
		{
			hideNpc(char);
			AudioUtils.play(this, DOOR_SOUND,1);
			var doorAnim:Entity = getEntityById( "anim"+char.get(LinkedEntity).link.get(Id).id);
			Timeline(doorAnim.get(Timeline)).play();
			index++;
			if(index >= sashaClones.length){
				//done
				if(shellApi.checkEvent(_events.HALLWAY_STARTED)){
					shellApi.completeEvent(_events.HALLWAY_STARTED);
				}
				if(stage == 0 && shellApi.checkEvent(_events.SASHA_LEFT_EXPO)){
					Dialog(player.get(Dialog)).sayById("wait");
				}
				returnPlayerControl();
			}
		}
		
		private function moveToDoor(char:Entity, door:Entity, reached:Function):void
		{			
			var doorSpatial:Spatial = door.get(Spatial);
			CharUtils.moveToTarget(char,doorSpatial.x,doorSpatial.y,null,reached);
		}
		
		private function correctDoorReached(door:Entity, char:Entity):void
		{
			AudioUtils.play(this, DOOR_SOUND,1);
			if(stage < stageCount){
				stage++;
				fadeOut(true);
			}else{
				loadNextScene();
			}
		}
		
		private function wrongDoorReached(door:Entity, char:Entity):void
		{
			AudioUtils.play(this, DOOR_SOUND,1);
			fadeOut(false);
		}
		
		// shuffle doors, one char goes to each door
		private function shuffleArray(arrayToShuffle:Array):Array {
			var shuffledArray:Array = [];
			while (arrayToShuffle.length > 0) {
				shuffledArray.push(arrayToShuffle.splice(Math.round(Math.random() * (arrayToShuffle.length - 1)), 1)[0]);
			}
			return shuffledArray;
		}
		
		private function returnPlayerControl():void
		{
			SceneUtil.lockInput(this,false);
			SceneUtil.setCameraTarget(this,player);
		}
		
		private function hideNpc(npc:Entity):void
		{
			npc.get(Display).visible = false;
			Children(npc.get(Children)).children[0].remove(ToolTipActive);
			npc.add(new Sleep(true));
			Character(npc.get(Character)).costumizable = false;
		}		
		
		private function showNpc(npc:Entity):void
		{
			npc.get(Display).visible = true;
			Children(npc.get(Children)).children[0].add(new ToolTipActive());
			npc.add(new Sleep(false));
			Character(npc.get(Character)).costumizable = true;
		}
		
		private function fadeOut(succeeded:Boolean):void
		{
			// TODO fade to black and back, then shuffle doors/npcs again
			SceneUtil.lockInput(this, true);
			this.screenEffects.fadeToBlack(0.8, Command.create(resetDoorPuzzle,succeeded));
		}
		
		private function resetDoorPuzzle(succeeded:Boolean):void
		{
			EntityUtils.removeAllWordBalloons(this);
			for each (var i:Entity in sashaClones) 
			{
				showNpc(i);
				Display(i.get(Display)).moveToFront();
			}
			doorIndex = 0;
			player.get(Spatial).x = 50;
			this.screenEffects.fadeFromBlack(1,Command.create(progressComment,succeeded));
			setupBGClutter();
			setupDoorPuzzle();
			setupDecorativeNpcs();
		}
		
		private function progressComment(succeeded:Boolean):void
		{
			if(succeeded){
				Dialog(player.get(Dialog)).sayById("there");
			}
			else{
				if(shellApi.checkEvent(_events.SASHA_LEFT_EXPO)){
					Dialog(player.get(Dialog)).sayById("where");
				}else{
					randomComment();
				}
			}
		}
		
		private function randomComment():void
		{
			Dialog(player.get(Dialog)).sayById("maze"+GeomUtils.randomInt(0,5));
		}
		
		private function loadNextScene():void
		{
			shellApi.completeEvent(_events.HALLWAY_CLEARED);
			shellApi.loadScene(Lobby);
		}
		
		
	}
}


