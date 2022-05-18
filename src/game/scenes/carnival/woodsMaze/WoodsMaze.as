package game.scenes.carnival.woodsMaze{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.ui.ButtonCreator;
	import game.scenes.carnival.CarnivalEvents;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.clearing.Clearing;
	import game.util.CharUtils;
	
	import org.osflash.signals.Signal;
	
	public class WoodsMaze extends PlatformerGameScene
	{
		private var carnivalEvents:CarnivalEvents;
		private var cluePositions:Array = [];
		private var doorRight:Entity;
		private var doorRightInt:Interaction;
		private var doorLeft:Entity;
		private var doorLeftInt:Interaction;
		private var doorClearing:Entity;
		private var doorClearingInt:Interaction;
		
		private var clueDoor:Number = 0;
		private var canNavigateMaze:Boolean = false;
		private var currClue:Number = 0;
		
		private var test:Entity;
		
		public function WoodsMaze()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/woodsMaze/";
			
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
			this.carnivalEvents = super.events as CarnivalEvents;
			
			setupClues();
			
			if( this.shellApi.checkEvent( this.carnivalEvents.TEENS_FRIGHTENED ) && !this.shellApi.checkEvent( this.carnivalEvents.MONSTERS_UNLEASHED )){//we can go through the maze
				//trace("CAN GO THROUGH MAZE");
				canNavigateMaze = true;
				if(super.shellApi.sceneManager.previousScene == "game.scenes.carnival.woodsMaze::WoodsMaze"){ //coming from maze
					checkClueFlags();
					setClue();
				}else{ //not coming from maze
					resetClues();
					setClue();
				}
			}
			setupDoorsRandom();
		}
		
		private function onClueDown(event:MouseEvent):void {
			Dialog(player.get(Dialog)).sayById("clue"+Math.ceil(Math.random()*3));
		}
		
		private function checkClueFlags():void {
			var flag1:Boolean = this.shellApi.checkEvent(carnivalEvents.CLUES_FLAG1);
			var flag2:Boolean = this.shellApi.checkEvent(carnivalEvents.CLUES_FLAG2);
			
			if(!flag1 && !flag2){ //on first clue
				currClue = 2;
			}else if(flag1 && !flag2){ //on second clue
				currClue = 3;
			}else if(!flag1 && flag2){ //on third clue
				currClue = 4;
			}else if(flag1 && flag2){ //on fourth clue
				currClue = 5;
			}
			//trace("Current Clue is "+currClue);
		}
		
		private function setClueFlags():void {
			switch(currClue){
				case 1:
					
					break;
				case 2:
					this.shellApi.completeEvent(carnivalEvents.CLUES_FLAG1);
					break;
				case 3:
					this.shellApi.removeEvent(carnivalEvents.CLUES_FLAG1);
					this.shellApi.completeEvent(carnivalEvents.CLUES_FLAG2);
					break;
				case 4:
					this.shellApi.completeEvent(carnivalEvents.CLUES_FLAG2);
					this.shellApi.completeEvent(carnivalEvents.CLUES_FLAG1);
					break;
				case 5:
					shellApi.loadScene(Clearing, 40, 760);
					break;
			}
		}
		
		private function setClue():void {
			var exit:Number = 0;
			var clue:Number = Math.ceil(Math.random()*8);
			
			if(player.get(Spatial).x < 700){
				if(currClue == 4){
					exit = 1;
				}else{
					exit = Math.ceil(Math.random()*2);
				}
			}else{ 
				if(player.get(Spatial).y > 650){
					exit = Math.ceil(Math.random()*2)-1;
				}else{
					if(currClue == 4){
						exit = 0;
					}else{
						var test:Number = Math.ceil(Math.random()*2);
						if(test == 1){
							exit = 0;
						}else{
							exit = 2
						}
					}
				}
			}
			
			if(currClue == 5){
				exit = 2;	
			}
			
			super.getEntityById("c_"+clue).get(Spatial).x = cluePositions[exit].x;
			super.getEntityById("c_"+clue).get(Spatial).y = cluePositions[exit].y;
			//_hitContainer["c_"+clue].x = cluePositions[exit].x
			//_hitContainer["c_"+clue].y = cluePositions[exit].y;
			clueDoor = exit;
			//trace("Clue door = "+exit);
		}
		
		private function clickRandomDoor(door:Entity):void {
			var exit:Number = Math.ceil(Math.random()*3)-1;
			if(canNavigateMaze){
				switch(door){
					case doorLeft:
						trace(clueDoor);
						if(clueDoor == 0){
							setClueFlags();
							if(currClue == 5){ return; }
						}else{
							resetClues();
						}
						break;
					case doorRight:
						if(clueDoor == 1){
							setClueFlags();
							if(currClue == 5){ return; }
						}else{
							resetClues();
						}
						break;
					case doorClearing:
						if(clueDoor == 2){
							setClueFlags();
							if(currClue == 5){ return; }
						}else{
							resetClues();
						}
						break;
				}
			}
			
			switch(exit){
				case 0:
					if(door == doorLeft){
						navigate("topRight", door);
					}else{
						navigate("topLeft", door);
					}
					break;
					
				case 1:
					if(door == doorRight){
						navigate("topLeft", door);
					}else{
						navigate("topRight", door);
					}
					break;
				case 2:
					if(door == doorClearing){
						navigate("topLeft", door);
					}else{
						navigate("bottomRight", door);
					}
					break;
			}
		}
		
		private function navigate(exit:String, door:Entity):void {
			switch(exit){
				case "topLeft":
					CharUtils.moveToTarget(player, door.get(Spatial).x, door.get(Spatial).y);
					shellApi.loadScene(WoodsMaze, 10, 365); //enter top left
					break;
				case "topRight":
					CharUtils.moveToTarget(player, door.get(Spatial).x, door.get(Spatial).y);
					shellApi.loadScene(WoodsMaze, 1384, 355); //enter top right
					break;
				case "bottomRight":
					CharUtils.moveToTarget(player, door.get(Spatial).x, door.get(Spatial).y);
					shellApi.loadScene(WoodsMaze, 1340, 768); //enter bottom right
					break;
			}
		}
		
		private function resetClues():void {
			this.shellApi.removeEvent(carnivalEvents.CLUES_FLAG1);
			this.shellApi.removeEvent(carnivalEvents.CLUES_FLAG2);
			currClue = 1;
		}
		
		private function setupDoorsRandom():void {
			doorLeft = super.getEntityById("doorWoodsMazeLeft");
			doorLeftInt = doorLeft.get(Interaction);
			doorLeftInt.click = new Signal();
			doorLeftInt.click.add(clickRandomDoor);
			
			doorRight = super.getEntityById("doorWoodsMazeRight");
			doorRightInt = doorRight.get(Interaction);
			doorRightInt.click = new Signal();
			doorRightInt.click.add(clickRandomDoor);
			
			doorClearing = super.getEntityById("doorClearing");
			doorClearingInt = doorClearing.get(Interaction);
			doorClearingInt.click = new Signal();
			doorClearingInt.click.add(clickRandomDoor);
		}
		
		private function setupClues():void {
			var pos1:Point = new Point(101, 381); //top left
			var pos2:Point = new Point(1298, 426); //top right
			var pos3:Point = new Point(1090, 745); //bottom right
			cluePositions.push(pos1);
			cluePositions.push(pos2);
			cluePositions.push(pos3);
			
			for(var i:uint = 1;i<9;i++){
				var clue:Entity = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["c_"+i]), this);
				trace(clue.get(Id).id);
				Display(clue.get(Display)).isStatic = false;
				var int:Interaction = clue.get(Interaction);
				int.downNative.add( Command.create( onClueDown ));
			}
		}
	}
}












