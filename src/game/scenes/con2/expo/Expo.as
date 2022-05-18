package game.scenes.con2.expo
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterWander;
	import game.components.hit.Door;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.game.GameEvent;
	import game.data.tutorials.ShapeData;
	import game.data.tutorials.StepData;
	import game.data.tutorials.TextData;
	import game.data.ui.ToolTipType;
	import game.scene.template.ItemGroup;
	import game.scenes.con2.hallways.Hallways;
	import game.scenes.con2.lobby.Lobby;
	import game.scenes.con2.shared.Poptropicon2Scene;
	import game.systems.motion.ProximitySystem;
	import game.ui.costumizer.Costumizer;
	import game.ui.costumizer.CostumizerPop;
	import game.ui.hud.Hud;
	import game.ui.tutorial.TutorialGroup;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class Expo extends Poptropicon2Scene
	{
		private var forrest:Entity;
		private var stan:Entity;
		private var sasha:Entity;
		private var costume:Entity;
		private var comicClick:Entity;
		private var comicInteraction:Interaction;
		private var card:Entity;
		private var animdoor:Entity;
		//private var doorHallwayInt:Interaction;
		private var tornado:Entity;
		
		private var _tutorialGroup:TutorialGroup;
		private const TUTORIAL_ALPHA:Number = .85;
		private var doorHallwayInteraction:SceneInteraction;
		
		public function Expo()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con2/expo/";
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
			this.addSystem(new ProximitySystem());
			
			this.forrest = this.getEntityById("forrest");
			this.stan = this.getEntityById("stan");
			this.sasha = this.getEntityById("sasha");
			this.costume = this.getEntityById("costume");
			
			//_events = shellApi.islandEvents as Con2Events;
			super.shellApi.eventTriggered.add(handleEventTriggered);
			getEntityById("costumeInteraction").get(SceneInteraction).reached.add(clickedCloset);
			
			if(!this.shellApi.checkHasItem( _events.OMEGON_COSTUME ))
			{
				var proximity:Proximity = new Proximity(1500, this.player.get(Spatial));
				if(this.shellApi.checkEvent( _events.OMEGON_BODY_PHOTO ) && this.shellApi.checkEvent( _events.OMEGON_CAPE_PHOTO ) && this.shellApi.checkEvent( _events.OMEGON_MASK_PHOTO )){
					//var proximity:Proximity = new Proximity(1500, this.player.get(Spatial));
					proximity.entered.addOnce(handleNearForrest);
					forrest.add(proximity);
					
				}else if(this.shellApi.checkEvent( GameEvent.GOT_ITEM + _events.CELL_PHONE )){
					Dialog(forrest.get(Dialog)).setCurrentById("get_photos");
				}
				else
				{
					proximity.entered.addOnce(becomeASpy);
					forrest.add(proximity);
					
					var door:Entity = getEntityById("doorDemo");
					var interaction:SceneInteraction = door.get(SceneInteraction);
					interaction.reached.removeAll();
					interaction.reached.add(openDemoDoor);
				}
				
			}else{
				Dialog(forrest.get(Dialog)).setCurrentById("nice_costume");
			}
			
			if(!this.shellApi.checkItemEvent( _events.COMIC )){
				setupComic();
			}
			
			if(!this.checkHasCard(_events.TRASH_COLLECTOR))
			{
				setupCard();
			}
			else
			{
				_hitContainer.removeChild(_hitContainer["card"]);
			}	
			
			setupDoor();
			
			if(!this.shellApi.checkEvent( _events.SASHA_LEFT_EXPO )){
				//setupClosedDoor();
				var clip:MovieClip = _hitContainer["animdoor"];
				animdoor = TimelineUtils.convertClip(_hitContainer["animdoor"],this,null,null,false);
				var spatial:Spatial = new Spatial();
				spatial.x = clip.x;
				spatial.y = clip.y;
				animdoor.add(spatial);
			}else{
				this.removeEntity( this.getEntityById("sasha" ));
				_hitContainer["animdoor"].visible = false;
				Dialog(stan.get(Dialog)).setCurrentById("everyone");
			}
			
			if(this.shellApi.checkEvent( _events.HALLWAY_CLEARED )){
				setupLobbyDoor();
			}
			
			if(!this.shellApi.checkEvent( _events.SAW_TUTORIAL )){
				Dialog(costume.get(Dialog)).setCurrentById("ask_tutorial");
			}
			setupTornado();
			
			super.loaded();
		}
		
		private function openDemoDoor(entity:Entity, door:Entity):void
		{
			if(!shellApi.checkEvent( GameEvent.GOT_ITEM + _events.CELL_PHONE ))
				becomeASpy(entity);
			else
				Door(door.get(Door)).open = true;
		}
		
		private function becomeASpy(entity:Entity):void
		{
			SceneUtil.lockInput(this);
			var interaction:SceneInteraction = forrest.get(SceneInteraction);
			interaction.activated = true;
			interaction.reached.addOnce(comere);
			forrest.remove(CharacterWander);
			CharUtils.moveToTarget( forrest, 1588, 935, true );
		}
		
		private function comere(...args):void
		{
			Dialog(forrest.get(Dialog)).sayById("comere");
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( event == "givePhone" ) {
				itemGroup.showAndGetItem( _events.CELL_PHONE, null, afterGetPhone );
			}else if(event == "give_back_phone"){
				itemGroup.takeItem( _events.CELL_PHONE, "forrest", "", null, afterGivePhoneBack);
			}else if( event == "getCostume" ) {
				var targetX:Number = forrest.get(Spatial).x - 700;
				//Sleep(tornado.get(Sleep)).ignoreOffscreenSleep = true;
				tornado.get(Spatial).x = forrest.get(Spatial).x;
				tornado.get(Display).visible = true;
				forrest.get(Display).visible = false;
				tornado.get(Timeline).gotoAndPlay(1);
				tornado.get(Tween).to(tornado.get(Spatial), 2, { x:targetX, ease:Sine.easeInOut, onComplete:returnTornado });
			}else if( event == "giveCostume" ) {
				itemGroup.showAndGetItem( _events.OMEGON_COSTUME, null, afterGetCostume );
				SceneUtil.lockInput(this, false);
			}else if( event == "turn_stan" ) {
				SceneUtil.lockInput(this, true);
				stan.get(Dialog).faceSpeaker = false;
				CharUtils.setDirection(stan, true);
			}else if( event == "show_sasha" ) {
				sasha.remove(CharacterWander);
				MotionUtils.zeroMotion(sasha);
				super.shellApi.camera.target = super.getEntityById("doorHallway").get(Spatial);
				CharUtils.moveToTarget(sasha, 3812, 935, false, sashaReachedDoor);
			}else if(event == "start_tutorial") {
				shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
				var hud:Hud = getGroupById(Hud.GROUP_ID) as Hud;
				
				var stepDatas:Vector.<StepData> = new Vector.<StepData>();
				var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
				var texts:Vector.<TextData> = new Vector.<TextData>();
				
				var hudButton:Entity = hud.getButtonById(Hud.HUD);
				var hudButtonSpatial:Spatial = hudButton.get(Spatial);
				
				shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(hudButtonSpatial.x, hudButtonSpatial.y), 60, 60, "greenShirt", null, null, hudButton.get(Interaction)));
				texts.push(new TextData("First, click on the menu button to open the costumizer.", "tutorialwhite", new Point(400*shellApi.viewportWidth/960, 100*shellApi.viewportHeight/640)));
				var clickHud:StepData = new StepData("hud", TUTORIAL_ALPHA, 0x000000, 1.5, true, shapes, texts);
				stepDatas.push(clickHud);	
				
				shapes = new Vector.<ShapeData>();
				texts = new Vector.<TextData>();
				shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(shellApi.viewportWidth - 200, 42), 40, 40, "npc", null, costumizerLoaded, null, hud.openingHudElement));
				texts.push(new TextData("Then, click on the green shirt to open the costumizer.", "tutorialwhite", new Point(500*shellApi.viewportWidth/960, 100*shellApi.viewportHeight/640)));
				var clickCostumizer:StepData = new StepData("greenShirt", TUTORIAL_ALPHA, 0x000000, 2, true, shapes, texts);
				stepDatas.push(clickCostumizer);
				
				_tutorialGroup = new TutorialGroup(overlayContainer, stepDatas);
				_tutorialGroup.complete.addOnce(tutorialFinished);
				this.addChildGroup(_tutorialGroup);
				_tutorialGroup.start();
			} else if(event == "no_tutorial") {
				CharUtils.lockControls(player, false ,false);
				getEntityById("costume").get(Interaction).lock = false;
				shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
			}
		}
		
		private function costumizerLoaded():void
		{
			var costumizer:Costumizer = getGroupById(Costumizer.GROUP_ID) as Costumizer;
			var costumeNPC:Entity = getEntityById("costume");
			var costumeUILoc:Point = DisplayUtils.localToLocal(costumeNPC.get(Display).displayObject, overlayContainer);
			costumeUILoc.x -= 52;
			costumeUILoc.y -= 105;
			
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			shapes.push(new ShapeData(ShapeData.RECTANGLE, costumeUILoc, 115, 155, "hatsOrParts", null, null, null, costumizer.onNPCSelected));
			texts.push(new TextData("Click on me to copy part of my outfit.", "tutorialwhite", new Point(200*shellApi.viewportWidth/960, 420*shellApi.viewportHeight/640)));
			var clickLady:StepData = new StepData("npc", TUTORIAL_ALPHA, 0x000000, 3, true, shapes, texts);
			_tutorialGroup.addStep(clickLady);
			
			costumizer.onNPCSelected.addOnce(Command.create(charSelected, costumizer));
		}
		
		private function charSelected(char:Entity, costumizer:Costumizer):void
		{
			costumizer.allCharsLoaded.addOnce(costumizerReady);
		}
		
		private function costumizerReady(group:Group):void
		{	
			var costumizer:Costumizer = group as Costumizer;
			
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();var char:Entity = costumizer.getEntityById(costumizer.MODEL);
			var scarf:Entity = SkinUtils.getSkinPartEntity(char, SkinUtils.OVERSHIRT);
			var rect:Rectangle = EntityUtils.getDisplayObject(scarf).getBounds(costumizer.screen.content.panel_L);
			shapes.push(new ShapeData(ShapeData.ELLIPSE, rect.topLeft, rect.width, rect.height, "accept", "partTray", null, null, costumizer.onNPCPartSelected));
			shapes.push(new ShapeData(ShapeData.RECTANGLE, new Point(5, shellApi.viewportHeight - 200), 100, 100, "partTray", null, null, costumizer.partsTrayButton.get(Interaction)));
			texts.push(new TextData("Click on my scarf to costumize it...", "tutorialwhite", new Point(160*shellApi.viewportWidth/960, 200*shellApi.viewportHeight/640)));
			texts.push(new TextData("Or click this to see what you can costumize from me.", "tutorialgreen", new Point(150*shellApi.viewportWidth/960, 460*shellApi.viewportHeight/640)));
			var clickHatOrParts:StepData = new StepData("hatsOrParts", TUTORIAL_ALPHA, 0x000000, 2, true, shapes, texts);
			_tutorialGroup.addStep(clickHatOrParts);
			
			shapes = new Vector.<ShapeData>();
			texts = new Vector.<TextData>();
			shapes.push(new ShapeData(ShapeData.RECTANGLE, new Point(shellApi.viewportWidth -733, shellApi.viewportHeight - 90), 100, 90, "accept", null, null, null, costumizer.onPartTraySelected));
			texts.push(new TextData("Here you can select the scarf.", "tutorialwhite", new Point(shellApi.viewportWidth-810, shellApi.viewportHeight - 190)));
			var partsHat:StepData = new StepData("partTray", TUTORIAL_ALPHA, 0x000000, 2, true, shapes, texts);
			_tutorialGroup.addStep(partsHat);
			
			var acceptSpatial:Spatial = costumizer.acceptButton.get(Spatial);
			var cancelSpatial:Spatial = costumizer.cancelButton.get(Spatial);
			shapes = new Vector.<ShapeData>();
			texts = new Vector.<TextData>();
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(acceptSpatial.x, acceptSpatial.y), 50, 50, null,  null, null, costumizer.acceptButton.get(Interaction)));
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(cancelSpatial.x, cancelSpatial.y), 50, 50, null,  null, null, costumizer.cancelButton.get(Interaction)));
			texts.push(new TextData("Click the checkmark to accept your changes.", "tutorialwhite", new Point(350*shellApi.viewportWidth/960, 150*shellApi.viewportHeight/640)));
			texts.push(new TextData("Click the X to cancel your changes.", "tutorialwhite", new Point(600*shellApi.viewportWidth/960, 250*shellApi.viewportHeight/640)));
			var accept:StepData = new StepData("accept", TUTORIAL_ALPHA, 0x000000, .5, true, shapes, texts);
			_tutorialGroup.addStep(accept);
		}
		
		private function tutorialFinished(group:DisplayGroup):void
		{
			CharUtils.lockControls(player, false ,false);
			this.removeGroup(group);
			
			var costume:Entity = getEntityById("costume");
			costume.get(Interaction).lock = false;
			costume.get(Dialog).sayById("tutorial_done");
			Dialog(costume.get(Dialog)).setCurrentById("tutorial_done");
			this.shellApi.completeEvent( _events.SAW_TUTORIAL );
		}
		
		private function returnTornado():void {
			var targetX:Number = forrest.get(Spatial).x;
			tornado.get(Tween).to(tornado.get(Spatial), 2, { x:targetX, ease:Sine.easeInOut, onComplete:giveCostume });
		}
		
		private function giveCostume():void {
			tornado.get(Display).visible = false;
			forrest.get(Display).visible = true;
			Dialog(forrest.get(Dialog)).sayById("here_you_go");
		}
		
		private function setupTornado():void {
			tornado = EntityUtils.createSpatialEntity(this, _hitContainer["tornado"], _hitContainer);
			BitmapTimelineCreator.convertToBitmapTimeline(tornado);
			
			tornado.add(new Tween());
			
			tornado.get(Timeline).gotoAndStop(0);
			tornado.get(Display).visible = false;
		}
		
		private function sashaReachedDoor(entity:Entity):void {
			animdoor.get(Timeline).gotoAndPlay("open");
			this.removeEntity( this.getEntityById("sasha" ));
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, resetPan, true));
			this.shellApi.completeEvent( _events.SASHA_LEFT_EXPO );
			Dialog(stan.get(Dialog)).setCurrentById("everyone");
			setupOpenDoor();
		}
		
		private function resetPan():void {
			SceneUtil.lockInput(this, false);
			super.shellApi.camera.target = player.get(Spatial);
		}
		
		private function setupDoor():void {
			var doorHallway:Entity = super.getEntityById("doorHallway");
			doorHallwayInteraction = SceneInteraction(doorHallway.get(SceneInteraction));
			//doorHallwayInt = doorHallway.get(Interaction);
			//doorHallwayInteraction.offsetX = 0;
		}
		
		private function setupOpenDoor():void {
			//doorHallwayInt.click = new Signal();
			//doorHallwayInt.click.add(clickHallwayDoor);
			doorHallwayInteraction.reached.removeAll();
			doorHallwayInteraction.reached.add(useHallwayDoor);
		}
		
		private function setupLobbyDoor():void {
			//doorHallwayInt.click = new Signal();
			//doorHallwayInt.click.add(clickLobbyDoor);
			doorHallwayInteraction.reached.removeAll();
			doorHallwayInteraction.reached.add(useLobbyDoor);
		}
		
		private function setupClosedDoor():void	{
			//doorHallwayInt.click = new Signal();
			//doorHallwayInt.click.add(clickClosedDoor);
			doorHallwayInteraction.reached.removeAll();
			doorHallwayInteraction.reached.add(clickClosedDoor);
		}
		//		
		//		private function clickHallwayDoor(door:Entity):void {
		//			CharUtils.moveToTarget(player, 3812, 935, false, useHallwayDoor);
		//		}
		//		
		//		private function clickLobbyDoor(door:Entity):void {
		//			CharUtils.moveToTarget(player, 3812, 935, false, useLobbyDoor);
		//		}
		
		private function useLobbyDoor(...p):void {
			shellApi.loadScene(Lobby);    //JEK - Add ad scene here - connects to lobby
		}
		
		private function useHallwayDoor(...p):void {
			shellApi.loadScene(Hallways, 50, 570, "right");
		}
		
		private function clickClosedDoor(...p):void {
			Dialog(player.get(Dialog)).sayById("locked");
		}
		
		private function afterGetPhone():void {
			Dialog(forrest.get(Dialog)).setCurrentById("get_photos");
			returnControls();
		}
		
		private function afterGetCostume():void {
			Dialog(forrest.get(Dialog)).setCurrentById("nice_costume");
		}
		
		private function afterGivePhoneBack():void {
			Dialog(forrest.get(Dialog)).sayById("scoop");
		}
		
		private function handleGetCard(entity:Entity):void 
		{
			addCardToDeck(_events.TRASH_COLLECTOR);
			super.removeEntity( card );
		}
		
		private function handleNearForrest(entity:Entity):void
		{
			SceneUtil.lockInput(this);
			CharUtils.moveToTarget(player, forrest.get(Spatial).x + 130, forrest.get(Spatial).y, false, reachedFocusTester);
			forrest.remove(CharacterWander);
			MotionUtils.zeroMotion(forrest);
		}
		
		private function reachedFocusTester(entity:Entity):void
		{
			CharUtils.setDirection(player, false);
			CharUtils.setDirection(forrest, true);
			Dialog(player.get(Dialog)).sayById("gotIt");	
		}
		
		private function setupCard():void 
		{
			card = EntityUtils.createSpatialEntity(this, _hitContainer["card"]);
			
			var proximity2:Proximity = new Proximity(100, this.player.get(Spatial));
			proximity2.entered.addOnce(handleGetCard);
			card.add(proximity2);
		}
		
		private function setupComic():void {
			//click for suit
			comicClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["comicClick"]), this);
			comicClick.remove(Timeline);
			comicInteraction = comicClick.get(Interaction);
			comicInteraction.downNative.add( Command.create( clickComic ));
		}
		
		private function clickComic(event:Event):void {
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			itemGroup.showAndGetItem( _events.COMIC, null, removeComicClick );
		}
		
		private function removeComicClick():void {
			comicInteraction.downNative.removeAll();
			comicClick.remove(ToolTip);
			comicClick.get(Display).visible = false;
		}
		
		private function clickedCloset(entity:Entity, clicker:Entity):void
		{
			this.pause(true, true);
			var costumizer:CostumizerPop = new CostumizerPop( null, null, false, true );
			addChildGroup( costumizer );
			costumizer.unpause(true, true);
			costumizer.init(this.overlayContainer);
			costumizer.popupRemoved.addOnce(costumizerClosed)
		}
		
		private function costumizerClosed():void
		{
			this.unpause(true, true);
		}
	}
}