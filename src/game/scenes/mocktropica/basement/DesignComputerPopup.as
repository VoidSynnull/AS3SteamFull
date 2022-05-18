package game.scenes.mocktropica.basement
{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.data.ui.ToolTipType;
	import game.data.ui.TransitionData;
	import game.scenes.mocktropica.basement.components.SnapSlot;
	import game.systems.timeline.TimelineClipSystem;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;

	
	public class DesignComputerPopup extends Popup
	{
		public var correctOrder:Vector.<String>;
		public var currentOrder:Vector.<String>;
		public var snapToPoints:Vector.<Entity>;
		public var hardware:Entity;
		public var locust:Entity;
		public var blimp:Entity;
		public var truck:Entity;
		public var popHQ:Entity;
		private var _events:MocktropicaEvents;
		public static const MOCK_LAYOUT:String = "mock_layout";
		
		public function DesignComputerPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "scenes/mocktropica/basement/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["designComputerPopup.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset("designComputerPopup.swf", true) as MovieClip;
			_events = shellApi.sceneManager.currentScene.events as MocktropicaEvents;
			// this loads the standard close button
			super.loadCloseButton();
			setupRenderWarning();
			setupDragDrop();
			setupSnapPoints();
			correctOrder = Vector.<String>["car","hardwareStore","statue","blueLocust"];
			currentOrder = getBuildingOrder();
			setupPositions();
			setupMenuButtons();
			setupCrate();
			super.loaded();
		}
		
		private function setupCrate():void
		{
			var utilPole:MovieClip = screen.content["phonePole"];
			var crate:Entity = EntityUtils.createSpatialEntity(this,screen.content["crate"]);
			crate = TimelineUtils.convertClip(screen.content["crate"],this, crate,null,false);
			crate.add(new Id("crate"));
			if(shellApi.checkEvent(_events.SMASHED_CRATE)){
				Timeline(crate.get(Timeline)).gotoAndStop("broken");
				utilPole.alpha = 0;
			}
			else if(shellApi.checkEvent(_events.FOCUS_HAS_CRATE)){
				var interact:Interaction = InteractionCreator.addToEntity(crate, [InteractionCreator.DOWN,InteractionCreator.UP,InteractionCreator.RELEASE_OUT]);
				interact.down.addOnce(grabCrate);
				interact.up.addOnce(dropCrate);
				interact.releaseOutside.addOnce(dropCrate);
				ToolTipCreator.addToEntity(crate);
				utilPole.alpha = 0;
			}
			else{
				EntityUtils.getDisplay(crate).visible=false;
				utilPole.alpha = 100;
			}
		}
		private function grabCrate(grabbed:Entity):void{
			var follow:FollowTarget = new FollowTarget(shellApi.inputEntity.get(Spatial),0.9,false);
			follow.properties = new Vector.<String>();
			follow.properties.push("y");
			grabbed.add(follow);
			shellApi.triggerEvent("grab");
		}
		
		private function dropCrate(dropped:Entity):void
		{
			dropped.remove(FollowTarget);
			var targX:Number = screen.content["snap5"].x;
			var targY:Number = screen.content["snap5"].y;
			var tween:Tween = new Tween();
			tween.to(dropped.get(Spatial), 0.3, {x:targX, y:targY, onComplete:explodeCrate});
			dropped.add(tween);
			shellApi.triggerEvent("drop");
		}
		
		private function explodeCrate(...p):void
		{
			var crate:Entity = getEntityById("crate");
			Timeline(crate.get(Timeline)).gotoAndStop("broken");
			crate.remove(Interaction);
			crate.remove(ToolTip);
			// kaboom
			shellApi.triggerEvent(_events.SMASHED_CRATE,true);
		}
		
		private function setupRenderWarning():void
		{
			var warning:Entity = EntityUtils.createSpatialEntity(this,screen.content.alert);
			warning.add(new Id("warning"));
			var yesButton:Entity = ButtonCreator.createButtonEntity(screen.content.alert["yesButton"],this,Command.create(menuClicked,"yes"));
			yesButton.add(new Id("warningYes"));
			var noButton:Entity = ButtonCreator.createButtonEntity(screen.content.alert["noButton"],this,Command.create(menuClicked,"no"));
			noButton.add(new Id("warningNo"));
			if(shellApi.checkEvent("used_des_computer")){
				EntityUtils.getDisplay(warning).visible = false;
			}else{
				shellApi.triggerEvent("alert");
			}
		}

		private function menuClicked(button:Entity, id:String = "yes"):void
		{
			var warning:Entity = getEntityById("warning");
			if(id=="yes"){
				EntityUtils.getDisplay(warning).visible = false;
			}
			else if(id=="no"){
				close();
			}
		}
				
		private function setupMenuButtons():void
		{
			for (var i:int = 0; i < 5; i++) 
			{
				var clip:MovieClip = MovieClip(super.screen.content["button"+i]);
				var button:Entity = ButtonCreator.createButtonEntity(clip, this, Command.create(activateButton, i));
				Timeline(button.get( Timeline )).gotoAndStop("up");
			}
		}
		
		private function activateButton(ent:Entity, index:int):void
		{
			shellApi.triggerEvent("click1");
			switch(index)
			{
				case 0:			
					//save&exit
					save();
					break;
				case 1:			
					// revert
					resetPositions();
					break;
				case 2:		
					//random
					randomizePositions();
					break;
				case 3:		
					//help
					showHelp();
					break;
				case 4:		
					// layer picker
					layerLocked();
					break;
			}
		}
		
		private function layerLocked():void
		{
			//TODO: play some locked out sounding beep, flash?
		}
		
		private function showHelp():void
		{
			//TODO: make some kind of text box to tell player what to do?
		}
		
		// make non-reapeating random sequence
		private function randomizePositions():void {
			var rand:Vector.<String> = new Vector.<String>();
			while (currentOrder.length > 0) {
				rand.push(currentOrder.splice(Math.round(Math.random() * (currentOrder.length - 1)), 1)[0]);
			}
			currentOrder = rand;
			setupPositions();
		}
		
		private function resetPositions():void
		{
			currentOrder = new <String>["hardwareStore","blueLocust","car","popStatue"];
			setupPositions();
		}
		
		private function getBuildingOrder():Vector.<String>
		{
			var vect:Array;
			// TODO :: Should we be getting this from the server? - bard
			var order:String = shellApi.getUserField(MOCK_LAYOUT,shellApi.island);
			if(order){
				vect = order.split(",");
				return Vector.<String>(vect);
			}
			if(!vect){
				// load default starting positions
				vect = ["hardwareStore","blueLocust","car","popStatue"];
				return Vector.<String>(vect);
			}
			return null;
		}
		
		private function save():void
		{
			//trace("SAVE")
			// prep save positions
			var saveStr:String = "";
			for (var i:int = 0; i < snapToPoints.length; i++) 
			{			
				var cur:String = snapToPoints[i].get(SnapSlot).snappedEnt.get(Id).id;
				saveStr += cur;
				if(i != snapToPoints.length-1){
					saveStr += ",";
				}
			}
			// TODO :: Should this userfield value be saved to the backend? - bard
			shellApi.setUserField(MOCK_LAYOUT,saveStr,shellApi.island, true);
			shellApi.triggerEvent("used_des_computer",true);
			this.close();
		}
		private function setupSnapPoints():void
		{
			snapToPoints = new Vector.<Entity>();
			for (var i:int = 0; i < 4; i++) 
			{
				snapToPoints.push(EntityUtils.createSpatialEntity(this,screen.content["snap"+i])
					.add(new Id("snap"+i))
					.add(new SnapSlot()));
			}
		}
		
		private function setupPositions():void
		{
			for (var i:int=0; i < currentOrder.length;i++) 
			{
				var bID:String = currentOrder[i];
				var building:Entity = getEntityById(bID);
				var buildingSpatial:Spatial = building.get(Spatial);
				var buildingSnap:SnapSlot = building.get(SnapSlot);
				var snap:Entity = snapToPoints[i];
				var snapSpatial:Spatial = snap.get(Spatial);
				var snapComp:SnapSlot = snap.get(SnapSlot);
				// bond the snapPoint and the building together
				EntityUtils.positionByEntity(building,snap);
				buildingSnap.snappedEnt = snap;
				buildingSnap.occupied = true;
				snapComp.snappedEnt = building;
				snapComp.occupied = true;
			}
		}
		private function updateSnapPositions():void
		{
			for (var i:int=0; i< currentOrder.length;i++) 
			{
				var ID:String = currentOrder[i];
				var building:Entity = getEntityById(ID);
				var buildingSpatial:Spatial = building.get(Spatial);
				var buildingSnap:SnapSlot = building.get(SnapSlot);
				for (var j:int=0; j< snapToPoints.length;j++) 
				{
					var snap:Entity = snapToPoints[j];
					var snapSpatial:Spatial = snap.get(Spatial);
					var snapComp:SnapSlot = snap.get(SnapSlot);
					if(EntityUtils.getDisplayObject(snap).hitTestPoint(buildingSpatial.x,buildingSpatial.y)){
						handleSnap(snap, building, snapComp, buildingSnap);
					}
				}
			}
		}
		
		private function handleSnap(snap:Entity, building:Entity, snapComp:SnapSlot, buildingSnap:SnapSlot):void
		{
			EntityUtils.positionByEntity(building,snap);
			if(snapComp.snappedEnt != building && buildingSnap.snappedEnt != snap){
				// save existing connection
				var tempBuilding:Entity = snapComp.snappedEnt;
				var tempSnap:Entity = buildingSnap.snappedEnt;
				var tempSnapComp:SnapSlot = new SnapSlot();
				var tempBuildingComp:SnapSlot = new SnapSlot();
				snapComp.snappedEnt = building;
				buildingSnap.snappedEnt = snap;
				// link up new connection
				EntityUtils.positionByEntity(tempBuilding,tempSnap);
				tempSnapComp.snappedEnt = tempBuilding;
				tempBuildingComp.snappedEnt = tempSnap;
				tempBuilding.add(tempBuildingComp);
				tempSnap.add(tempSnapComp);
			}
		}
		
		public function setupDragDrop():void
		{
			makeDraggableEntity(hardware,"hardwareStore");
			makeDraggableEntity(blimp,"popStatue");
			makeDraggableEntity(truck,"car");
			makeDraggableEntity(locust,"blueLocust");			
		}
		
		public function makeDraggableEntity(entity:Entity,clipName:String):void
		{
			entity = new Entity();
			entity.add(new Id(clipName));
			entity.add(new Display(screen.content[clipName]));
			entity.add(new Spatial(screen.content[clipName].x,screen.content[clipName].y));
			entity.add(new OwningGroup(this));
			entity.add(new SnapSlot());
			var interact:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			interact.down.add(grab);
			interact.up.add(drop);
			interact.releaseOutside.add(dropOut);
			ToolTipCreator.addToEntity(entity,ToolTipType.CLICK);
			addEntity(entity);
		}
		
		private function grab(grabbed:Entity):void{
			//trace("GRAB");
			var follow:FollowTarget = new FollowTarget(shellApi.inputEntity.get(Spatial),0.99,false);
			grabbed.add(follow);
			shellApi.triggerEvent("grab");
		}
		
		private function drop(grabbed:Entity):void{
			//trace("DROP");
			grabbed.remove(FollowTarget);
			updateSnapPositions();
			shellApi.triggerEvent("drop");
		}
		
		private function dropOut(grabbed:Entity):void{
			//trace("DROPOUT");
			grabbed.remove(FollowTarget);
			updateSnapPositions();
			shellApi.triggerEvent("drop");
		}
		
		
		
		
		
		
		
		
		
		
		
		
	};
};