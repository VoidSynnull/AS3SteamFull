package game.scenes.mocktropica.poptropicaHQ{
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.hit.Platform;
	import game.components.motion.FollowTarget;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Wave;
	import game.data.scene.characterDialog.DialogData;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scenes.mocktropica.mockLoadingScreen.MockLoadingScreen;
	import game.scenes.mocktropica.poptropicaHQ.components.Elevator;
	import game.scenes.mocktropica.poptropicaHQ.popups.StoryGenerator;
	import game.scenes.mocktropica.shared.AchievementGroup;
	import game.scenes.mocktropica.shared.AdvertisementGroup;
	import game.scenes.mocktropica.shared.MocktropicaScene;
	import game.systems.motion.ProximitySystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class PoptropicaHQ extends MocktropicaScene
	{
		private var mockEvents:MocktropicaEvents;
		private var basementDoor:Entity;
		private var basementDoorInt:Interaction;
		private var savedBasementDoor:Signal;
		private var savedFTIndex:Number;
		
		private var focusTester:Entity;
		private var safetyInspector:Entity;
		private var salesManager:Entity;
		private var costCutter:Entity;
		private var projectManager:Entity;
		private var kid1:Entity;
		private var kid2:Entity;
		private var kid3:Entity;
		private var kid4:Entity;
		private var cake1:Entity;
		private var cake2:Entity;
		private var cake3:Entity;
		private var cake4:Entity;
		private var story:Entity;
		private var elevatorFloor:Entity;
		private var storyInteraction:Interaction;
		private var elevatorUpBtn:Entity;
		private var elevatorDownBtn:Entity;
		private var hallUpBtn:Entity;
		private var hallDownBtn:Entity;
		private var elevator:Entity;
		
		private var yayCount:Number = 0;
		private var doorClosed:Boolean = false;
		private var canBuyAds:Boolean = false;
		
		private var platform:Platform;
		
		private var doorMainStreet:Entity;
		
		public function PoptropicaHQ()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/mocktropica/poptropicaHQ/";
			
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
			this.mockEvents = super.events as MocktropicaEvents;
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			super.addChildGroup( new AdvertisementGroup( this, _hitContainer ));
			
			this.focusTester = this.getEntityById("focusTester");
			this.safetyInspector = this.getEntityById("safetyInspector");
			this.salesManager = this.getEntityById("salesManager");
			this.costCutter = this.getEntityById("costCutter");
			this.projectManager = this.getEntityById("projectManager");
			this.kid1 = this.getEntityById("kid1");
			this.kid2 = this.getEntityById("kid2");
			this.kid3 = this.getEntityById("kid3");
			this.kid4 = this.getEntityById("kid4");
			this.elevatorFloor = this.getEntityById("elevatorFloor");
			this.doorMainStreet = this.getEntityById("doorMainStreet");
			
			Dialog(player.get(Dialog)).start.add(checkDialogStart);
			
			var plat:Entity = super.getEntityById("platform1"); //platform for focus tester in focus testing room
			platform = plat.get(Platform);
			plat.remove(Platform);
			
			this.setupFocusGroup();
			this.setupElevator();
			
			checkBasementDoor();
			checkDialog();		
		}
		
		private function checkDialogStart(dialogData:DialogData):void
		{
			if(dialogData.id == "workingOn" && dialogData.entityID == "salesManager"){
				CharUtils.lockControls(player, true, true);
				salesManager.get(Interaction).lock = true;
			}else if(dialogData.id == "crazyTalk" && dialogData.entityID == "focusTester"){
				SceneUtil.lockInput(this);
			}
		}
		
		private function checkDialog():void {
			if(this.shellApi.checkEvent(mockEvents.SPOKE_WITH_FOCUS_TESTER)){
				Dialog(focusTester.get(Dialog)).setCurrentById("cash");
			}
			if(this.shellApi.checkEvent(mockEvents.SPOKE_WITH_SAFETY_INSPECTOR)){
				Dialog(safetyInspector.get(Dialog)).setCurrentById("velcro");
			}
			if(this.shellApi.checkEvent(mockEvents.SPOKE_WITH_SALES_MANAGER)){
				Dialog(salesManager.get(Dialog)).setCurrentById("advertiseSomething");
			}
			if(this.shellApi.checkEvent(mockEvents.SPOKE_WITH_COST_CUTTER)){
				Dialog(costCutter.get(Dialog)).setCurrentById("sweet");
				setupStoryGenerator()
			}
			if(shellApi.checkEvent(mockEvents.ACHIEVEMENT_JUST_FOCUS) && !shellApi.checkEvent(mockEvents.PAYED_COIN)){
				this.removeEntity(this.getEntityById("focusTester"));
			}
			if(shellApi.checkEvent(mockEvents.DEVELOPER_RETURNED) && !shellApi.checkEvent(mockEvents.SMASHED_CRATE)){
				this.removeEntity(this.getEntityById("focusTester"));
			}
			if(this.shellApi.checkEvent(mockEvents.USED_COMPUTERS) && !this.shellApi.checkEvent(mockEvents.ACHIEVEMENT_ACHIEVER)){
				this.addSystem(new ProximitySystem());
				
				var proximity:Proximity = new Proximity(1500, this.player.get(Spatial));
				proximity.entered.addOnce(handleNearFocusTester);
				this.focusTester.add(proximity);
				
				focusTester.get(Spatial).x = 1500;
				focusTester.get(Spatial).y = 1640;
			}
			//worst ads ever introduced
			if(this.shellApi.checkEvent(mockEvents.WRITER_LEFT_CLASSROOM) && !this.shellApi.checkEvent(mockEvents.BOUGHT_ADS)){
				//Dialog(salesManager.get(Dialog)).setCurrentById("enoughMoney");
				canBuyAds = true;
			}
			if(this.shellApi.checkEvent(mockEvents.BOUGHT_ADS) && !this.shellApi.checkEvent(mockEvents.ELIMINATED_SERVERS)){
				setupCostCutterFinest();
			}
			if(this.shellApi.checkEvent( "gotItem_medal_mocktropica" )){
				this.removeEntity(this.getEntityById("focusTester"));
				this.removeEntity(this.getEntityById("safetyInspector"));
				this.removeEntity(this.getEntityById("salesManager"));
				this.removeEntity(this.getEntityById("costCutter"));
				this.removeEntity(this.getEntityById("projectManager"));
			}
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "showYou") {
				CharUtils.setDirection(focusTester, true);
				//SceneUtil.lockInput(this);
				CharUtils.moveToTarget(player, 300, 1685);
				CharUtils.followPath(focusTester, new <Point> [new Point(focusTester.get(Spatial).x + 140, focusTester.get(Spatial).y - 20)], ftReachedDoor1, true);
				var plat:Entity = super.getEntityById("platform1");
				plat.add(platform);
				//SceneUtil.setCameraTarget( this, _master );
			}else if (event == "hiKids"){
				Dialog(kid1.get(Dialog)).sayById("pets");
				Dialog(kid2.get(Dialog)).sayById("pets");
				Dialog(kid3.get(Dialog)).sayById("pets");
				Dialog(kid4.get(Dialog)).sayById("pets");
			}else if (event == "yay"){
				Dialog(kid1.get(Dialog)).sayById("yay");
				Dialog(kid2.get(Dialog)).sayById("yay");
				Dialog(kid3.get(Dialog)).sayById("yay");
				Dialog(kid4.get(Dialog)).sayById("yay");
				if(yayCount == 1){
					tweenCakes();
					CharUtils.setAnim(focusTester, game.data.animation.entity.character.Wave);
				}
			}else if (event == "yayOver"){
				yayCount++;
				if(yayCount == 1){
					Dialog(focusTester.get(Dialog)).sayById("hi_kids_3");
				}else{
					CharUtils.followPath(focusTester, new <Point> [new Point(540, 1685)], ftReachedDoor2, true);
				}
			}else if (event == "metFocusTester"){
				//get cake				
				SceneUtil.lockInput(this, false);
				shellApi.getItem(mockEvents.CAKE,null,true );
				//complete event
				this.shellApi.completeEvent(mockEvents.SPOKE_WITH_FOCUS_TESTER);
				//set dialog
				Dialog(focusTester.get(Dialog)).setCurrentById("cash");
				//check basement door
				checkBasementDoor();
			}else if (event == "metSafetyInspector"){
				//complete event
				this.shellApi.completeEvent(mockEvents.SPOKE_WITH_SAFETY_INSPECTOR);
				//set dialog
				Dialog(safetyInspector.get(Dialog)).setCurrentById("velcro");
				//check basement door
				checkBasementDoor();
			}else if (event == "newAd" && !super.shellApi.checkEvent( mockEvents.NEW_AD_UNIT )){
				//new ad pop up goes here
				super.shellApi.completeEvent( mockEvents.NEW_AD_UNIT );
				var adGroup:AdvertisementGroup = super.getGroupById( "mocktropicaAdvertisementGroup" ) as AdvertisementGroup;
				adGroup.createAdvertisement( mockEvents.ADVERTISEMENT_BOSS_1, completeAd1);
			}else if (event == "metSalesManager"){
				//complete event
				this.shellApi.completeEvent(mockEvents.SPOKE_WITH_SALES_MANAGER);
				SceneUtil.lockInput(this, false);
				CharUtils.lockControls(player, false, false);
				salesManager.get(Interaction).lock = false;
				//set dialog
				Dialog(salesManager.get(Dialog)).setCurrentById("advertiseSomething");
				//check basement door
				checkBasementDoor();
			}else if (event == "generator"){
				//use generator goes here
				var storyGenerator:StoryGenerator = super.addChildGroup( new StoryGenerator( super.overlayContainer )) as StoryGenerator;
				setupStoryGenerator();
				//complete event
				this.shellApi.completeEvent(mockEvents.SPOKE_WITH_COST_CUTTER);
				//set dialog
				Dialog(costCutter.get(Dialog)).setCurrentById("sweet");
				//check basement door
				checkBasementDoor();
			}else if (event == "basementOpen"){
				if(savedBasementDoor){
					basementDoorInt.click = savedBasementDoor;
				}
				//complete event
				this.shellApi.completeEvent(mockEvents.BASEMENT_OPEN);
				//projectManager.get(CharacterMotionControl).runSpeed = 15;
				CharUtils.followPath(projectManager, new <Point> [new Point(1700, 1685)], projectManagerExit, true);
			}else if (event == "achiever"){
				//complete event
				//this.shellApi.completeEvent(mockEvents.ACHIEVEMENT_ACHIEVER);
				SceneUtil.lockInput(this, false);
				var achievements:AchievementGroup = new AchievementGroup( this );
				this.addChildGroup( achievements );
				achievements.completeAchievement( mockEvents.ACHIEVEMENT_ACHIEVER );
				Dialog(focusTester.get(Dialog)).setCurrentById("loveIt");
				//make achievement here
			}else if (event == "usedCoin"){
				if(canBuyAds){
					if(player.get(Spatial).y > 450 && player.get(Spatial).y < 800){
						if(Dialog(salesManager.get(Dialog)).initiated || Dialog(salesManager.get(Dialog)).speaking){
							Dialog(salesManager.get(Dialog)).complete.addOnce(useCoinsAfterSpeech);
						}else{
							CharUtils.moveToTarget(player, 875, 793, false, buyAds);
						}
					}
				}
				else
				{
					shellApi.triggerEvent("wrong_coin_use");
				}
			}else if (event == "boughtAds"){
				//complete event
				this.shellApi.completeEvent(mockEvents.BOUGHT_ADS);
				Dialog(salesManager.get(Dialog)).setCurrentById("breaksMyHeart");
				setupCostCutterFinest();
			}else if (event == "eliminatedServers"){
				SceneUtil.lockInput(this, false);
				//complete event
				this.shellApi.completeEvent(mockEvents.ELIMINATED_SERVERS);
				setupDoor();
			}
		}
		
		private function useCoinsAfterSpeech(dialogData:DialogData):void
		{
			CharUtils.moveToTarget(player, 875, 793, false, buyAds);
		}
		
		private function setupDoor():void	{
			var doorInteraction:SceneInteraction = doorMainStreet.get(SceneInteraction);
			var doorInt:Interaction = doorMainStreet.get(Interaction);
			doorInteraction.offsetX = 0;
			doorInt.click = new Signal();
			doorInt.click.add(clickDoor);	
			
			basementDoor = super.getEntityById("doorBasement");
			var basementDoorInteraction:SceneInteraction = basementDoor.get(SceneInteraction);
			basementDoorInt = basementDoor.get(Interaction);
			basementDoorInteraction.offsetX = 0;
			basementDoorInt.click = new Signal();
			basementDoorInt.click.add(clickDoor);
		}
		
		private function clickDoor(door:Entity):void {
			shellApi.loadScene(MockLoadingScreen, -100, 520);
		}
		
		private function completeAd1( ):void
		{
			SceneUtil.lockInput(this);
			Dialog(salesManager.get(Dialog)).sayById("eightCents");
		}
		
		private function buyAds(entity:Entity):void
		{
			CharUtils.setDirection(player, false);
			CharUtils.setAnim(player, game.data.animation.entity.character.Salute);
			var te:TimedEvent = new TimedEvent(1, 1, finishBuyAds, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function finishBuyAds():void {
			Dialog(salesManager.get(Dialog)).sayById("enoughMoney");
		}
		
		private function faceLeft(entity:Entity):void
		{
			CharUtils.setDirection(player, false);
		}
		
		private function ftReachedDoor1(entity:Entity):void {
			CharUtils.setDirection(focusTester, false);
			focusTester.get(Display).displayObject.mask = this._hitContainer["focusMask"];
			
			focusTester.get(Spatial).y -= 30;
			savedFTIndex = this._hitContainer.getChildIndex(focusTester.get(Display).displayObject);
			var index:int = this._hitContainer.getChildIndex(this._hitContainer["table"]);
			this._hitContainer.setChildIndex(focusTester.get(Display).displayObject, index);
			
			CharUtils.followPath(focusTester, new <Point> [new Point(400, 1665)], ftReachedKids, true);
		}
		
		private function ftReachedKids(entity:Entity):void {
			CharUtils.setDirection(focusTester, false);
			Dialog(focusTester.get(Dialog)).sayById("hi_kids_1");
		}
		
		private function ftReachedDoor2(entity:Entity):void {
			var plat:Entity = super.getEntityById("platform1");
			plat.remove(Platform);
			Display(plat.get(Display)).visible = false;
			CharUtils.setDirection(focusTester, false);
			focusTester.get(Display).displayObject.mask = null;
			this._hitContainer.setChildIndex(focusTester.get(Display).displayObject, savedFTIndex);
			
			CharUtils.followPath(focusTester, new <Point> [new Point(400, 1685)], ftReachedStart, true);
		}
		
		private function ftReachedStart(entity:Entity):void {
			CharUtils.setDirection(focusTester, false);
			Dialog(focusTester.get(Dialog)).sayById("thats_the_way");
		}
		
		private function projectManagerExit(entity:Entity):void {
			this.removeEntity( this.getEntityById("projectManager" ) );
			SceneUtil.lockInput(this, false);
		}

		private function setupCostCutterFinest():void {
			costCutter.get(Spatial).x = 1500;
			costCutter.get(Spatial).y = 1640;
			this.addSystem(new ProximitySystem());
			
			var proximity:Proximity = new Proximity(500, this.player.get(Spatial));
			proximity.entered.addOnce(handleNearCostCutter);
			this.costCutter.add(proximity);
			CharUtils.setDialogCurrent(costCutter,"finestHour");
		}
		
		private function handleNearCostCutter(entity:Entity):void 
		{
			
			CharUtils.moveToTarget(player, costCutter.get(Spatial).x + 100, costCutter.get(Spatial).y, false, reachedCostCutter);
		}
		
		private function reachedCostCutter(entity:Entity):void 
		{
			SceneUtil.lockInput(this);
			CharUtils.setDirection(player, false);
			Dialog(costCutter.get(Dialog)).sayById("finestHour");	
		}
		
		private function checkBasementDoor():void {
			if(!this.shellApi.checkEvent(mockEvents.BASEMENT_OPEN)) {
				if(this.shellApi.checkEvent(mockEvents.SPOKE_WITH_FOCUS_TESTER) 
					&& this.shellApi.checkEvent(mockEvents.SPOKE_WITH_SAFETY_INSPECTOR) 
					&& this.shellApi.checkEvent(mockEvents.SPOKE_WITH_SALES_MANAGER) 
					&& this.shellApi.checkEvent(mockEvents.SPOKE_WITH_COST_CUTTER))
				{
					if(!doorClosed){
						setupClosedDoor();
					}
					setupProjectManagerAtBasement();
				}else{
					if(!doorClosed){
						setupClosedDoor();
					}
				}
			}else{
				
			}
		}
		
		private function setupProjectManagerAtBasement():void {
			shellApi.triggerEvent("basementReady");
			this.addSystem(new ProximitySystem());
			
			var proximity:Proximity = new Proximity(500, this.player.get(Spatial));
			proximity.entered.addOnce(handleNearProjectManager);
			this.projectManager.add(proximity);
		}
		
		private function handleNearProjectManager(entity:Entity):void {
			//Dialog(projectManager.get(Dialog)).sayById("thats_the_way");
			SceneUtil.lockInput(this);
			CharUtils.moveToTarget(player, projectManager.get(Spatial).x + 100, projectManager.get(Spatial).y, false, reachedProjectManager);
		}
		
		private function reachedProjectManager(entity:Entity):void {
			CharUtils.setDirection(player, false);
			Dialog(player.get(Dialog)).sayById("confused");	
		}
		
		private function handleNearFocusTester(entity:Entity):void
		{
			SceneUtil.lockInput(this);
			CharUtils.moveToTarget(player, focusTester.get(Spatial).x - 100, focusTester.get(Spatial).y, false, reachedFocusTester);
		}
		
		private function reachedFocusTester(entity:Entity):void
		{
			CharUtils.setDirection(player, true);
			Dialog(focusTester.get(Dialog)).sayById("achievements");	
		}
		
		private function setupStoryGenerator():void {
			story = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["storyGenerator"]), this);
			story.remove(Timeline);
			
			storyInteraction = story.get(Interaction);
			storyInteraction.downNative.add( Command.create( onStoryDown ));
		}
		
		private function onStoryDown(event:Event):void {
			var storyGenerator:StoryGenerator = super.addChildGroup( new StoryGenerator( super.overlayContainer )) as StoryGenerator;
		}
		
		private function setupClosedDoor():void	{
			basementDoor = super.getEntityById("doorBasement");
			var basementDoorInteraction:SceneInteraction = basementDoor.get(SceneInteraction);
			basementDoorInt = basementDoor.get(Interaction);
			basementDoorInteraction.offsetX = 0;
			savedBasementDoor = basementDoorInt.click;
			basementDoorInt.click = new Signal();
			basementDoorInt.click.add(clickClosedDoor);
			doorClosed = true;
		}
		
		private function clickClosedDoor(door:Entity):void {
			Dialog(player.get(Dialog)).sayById("locked");
		}
		
		private function tweenCakes():void {
			cake1.get(Display).alpha = 1;
			cake2.get(Display).alpha = 1;
			cake3.get(Display).alpha = 1;
			cake4.get(Display).alpha = 1;
			cake1.get(Tween).to(cake1.get(Spatial), 0.5, { x:108, ease:Sine.easeInOut });
			cake2.get(Tween).to(cake2.get(Spatial), 0.5, { x:166, ease:Sine.easeInOut });
			cake3.get(Tween).to(cake3.get(Spatial), 0.5, { x:255, ease:Sine.easeInOut });
			cake4.get(Tween).to(cake4.get(Spatial), 0.5, { x:321, ease:Sine.easeInOut });
		}
		
		private function setupFocusGroup():void
		{
			/**
			 * Focus groups are "laughable"!
			 * If you want them to stop laughing, just remove the animations in the npcs.xml.
			 * I just thought it was funny.
			 */
			var index:int = this._hitContainer.getChildIndex(this._hitContainer["table"]);
			
			cake1 = EntityUtils.createSpatialEntity(this, this._hitContainer["cake1"]);
			this._hitContainer.setChildIndex(cake1.get(Display).displayObject, index);
			cake1.get(Display).displayObject.mask = this._hitContainer["focusMask"];
			cake1.get(Display).alpha = 0;
			cake1.add(new Tween());
			
			cake2 = EntityUtils.createSpatialEntity(this, this._hitContainer["cake2"]);
			this._hitContainer.setChildIndex(cake2.get(Display).displayObject, index);
			cake2.get(Display).displayObject.mask = this._hitContainer["focusMask"];
			cake2.get(Display).alpha = 0;
			cake2.add(new Tween());
			
			cake3 = EntityUtils.createSpatialEntity(this, this._hitContainer["cake3"]);
			this._hitContainer.setChildIndex(cake3.get(Display).displayObject, index);
			cake3.get(Display).displayObject.mask = this._hitContainer["focusMask"];
			cake3.get(Display).alpha = 0;
			cake3.add(new Tween());
			
			cake4 = EntityUtils.createSpatialEntity(this, this._hitContainer["cake4"]);
			this._hitContainer.setChildIndex(cake4.get(Display).displayObject, index);
			cake4.get(Display).displayObject.mask = this._hitContainer["focusMask"];
			cake4.get(Display).alpha = 0;
			cake4.add(new Tween());
			
			for(var i:int = 1; i <= 4; i++) {
				var kid:Entity = this.getEntityById("kid" + i);
				var display:Display = kid.get(Display);
				this._hitContainer.setChildIndex(display.displayObject, index);
				
				kid.remove(Interaction);
				kid.remove(SceneInteraction);
				ToolTipCreator.removeFromEntity(kid);
			}			
		}
		
		private function setupElevator():void
		{
			var i:int;
			var spatial:Spatial;
			var target:FollowTarget;
			
			//Elevator
			elevator = EntityUtils.createSpatialEntity(this, this._hitContainer["elevator"]);
			elevator.add(new Id("elevator"));
			elevator.add(new Tween());
			
			var elev:Elevator = new Elevator(1);
			elev.floors.addAllAt(0, [1537, 1045, 646, 233]);
			elevator.add(elev);
			
			var elevatorSpatial:Spatial = elevator.get(Spatial);
			
			elevatorUpBtn = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["elevatorUpBtn"]), this);
			elevatorUpBtn.remove(Timeline);
			elevatorUpBtn.get(Interaction).downNative.add( Command.create( moveElevator ));
			Display(elevatorUpBtn.get(Display)).isStatic = false;
			
			elevatorDownBtn = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["elevatorDownBtn"]), this);
			elevatorDownBtn.remove(Timeline);
			elevatorDownBtn.get(Interaction).downNative.add( Command.create( moveElevator ));
			Display(elevatorDownBtn.get(Display)).isStatic = false;
			
			hallUpBtn = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["hallUpBtn"]), this);
			hallUpBtn.remove(Timeline);
			hallUpBtn.get(Interaction).downNative.add( Command.create( moveElevator ));
			
			hallDownBtn = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["hallDownBtn"]), this);
			hallDownBtn.remove(Timeline);
			hallDownBtn.get(Interaction).downNative.add( Command.create( moveElevator ));
			
			//Elevator platforms, walls, and ceilings
			var hits:Array = ["elevatorFloor", "elevatorWallLeft", "elevatorCeiling"];
			for(i = 0; i < hits.length; i++)
			{
				var hit:Entity = this.getEntityById(hits[i]);
			
				/**
				 * Displays for Hits are set to isStatic = true. This needs to be turned off in order for
				 * the entity's Spatial to move its Display when its following the elevator up and down.
				 */
				Display(hit.get(Display)).isStatic = false;
				spatial = hit.get(Spatial);
				
				target = new FollowTarget(elevatorSpatial);
				target.offset = new Point(spatial.x - elevatorSpatial.x, spatial.y - elevatorSpatial.y);
				hit.add(target);
			}
		}
		
		private function moveElevator(event:Event):void
		{
			var elev:Elevator = elevator.get(Elevator);
			var spatial:Spatial = elevator.get(Spatial);
			var tween:Tween = elevator.get(Tween);
			
			var isUp:Boolean;
			
			switch(event.currentTarget.name){
				case "elevatorUpBtn":
				case "hallUpBtn":
					isUp = true;
					break;
				case "elevatorDownBtn":
				case "hallDownBtn":
					isUp = false;
					break;
			}
			
			if(elev.isMoving) return;
			
			if(isUp)
			{
				if(elev.floor + 1 > elev.floors.size) return;
				elev.floor++;
			}
			else
			{
				if(elev.floor - 1 < 1) return;
				elev.floor--;
				if(event.currentTarget.name == "hallDownBtn"){
					elev.floor = 1;
				}
			}
			
			//Lock controls until the elevator reaches the next floor.
			SceneUtil.lockInput(this);
			elev.isMoving = true;
			var y:Number = elev.floors.itemAt(elev.floor - 1);
			var object:Object;
			if(isUp){
				object = { y:y, ease:Quad.easeInOut, onComplete:moveElevatorComplete, onUpdate:keepInElevator };
			}else{
				object = { y:y, ease:Quad.easeInOut, onComplete:moveElevatorComplete };
			}
			tween.to(spatial, 4, object);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "servo_large_01_L.mp3", 1, true);
		}
		
		private function keepInElevator():void {
			if(player.get(Spatial).x > 1930){
				player.get(Spatial).y = elevatorFloor.get(Spatial).y - 36;
			}
		}
		
		private function moveElevatorComplete():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "servo_large_01_L.mp3");
			elevatorUpBtn.get(Spatial).x = elevator.get(Spatial).x - 78;
			elevatorUpBtn.get(Spatial).y = elevator.get(Spatial).y + 64;
			elevatorDownBtn.get(Spatial).x = elevator.get(Spatial).x - 78;
			elevatorDownBtn.get(Spatial).y = elevator.get(Spatial).y + 89;
			
			SceneUtil.lockInput(this, false);
			elevator.get(Elevator).isMoving = false;
		}
	}
}