package game.scenes.mocktropica.basement{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.character.Character;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.collider.HazardCollider;
	import game.components.motion.Edge;
	import game.components.motion.MotionTarget;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.KeyboardTyping;
	import game.data.animation.entity.character.SitSleepLoop;
	import game.data.animation.entity.character.Stand;
	import game.data.game.GameEvent;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.particles.emitter.SwarmingFlies;
	import game.scene.template.ItemGroup;
	import game.scenes.mocktropica.poptropicaHQ.TrashCanPopup;
	import game.scenes.mocktropica.shared.MocktropicaScene;
	import game.scenes.mocktropica.shared.MocktropicanHUD;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ProximitySystem;
	import game.ui.hud.Hud;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class Basement extends MocktropicaScene
	{
		private var designer1:Entity;
		private var designer2:Entity;
		private var programmer1:Entity;
		private var programmer2:Entity;
		private var costCutter:Entity;
		private var leadDesigner:Entity;
		private var hertz:Entity;
		private var leadDeveloper:Entity;
		private var guy:Entity;
		private var sleepingProgrammer:Entity;
		private var lock:Entity;
		private var can:Entity;
		private var bag:Entity;
		private var desScreenAnim:Entity;
		private var devScreenAnim:Entity;
		
		private var canInteraction:Interaction;
		private var bagInteraction:Interaction;
		private var bagToolTip:ToolTip;
		
		private var mockEvents:MocktropicaEvents;
		private var firstConversation:Array = [0, 0, 0, 0];
		private var guyShouldFallDownStairs:Boolean = true;
		
		private var _fliesEntity:Entity;
		private var machine:Entity;
		private var flash:Entity;
		
		private var matrixDissolveEmitter:MatrixDissolveEmitter;
		private var matrixDissolve:Entity;
		private var isDay2:Boolean = false;
		
		private var bagMoved:Boolean = false;
		
		public function Basement()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/mocktropica/basement/";
			
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
			//shellApi.triggerEvent("layout_blueLocust,hardwareStore,popStatue,car,popBuilding",true);
			super.shellApi.eventTriggered.add(handleEventTriggered);
			this.mockEvents = super.events as MocktropicaEvents;
			this.designer1 = this.getEntityById("designer1");
			this.designer2 = this.getEntityById("designer2");
			this.programmer1 = this.getEntityById("programmer1");
			this.programmer2 = this.getEntityById("programmer2");
			this.costCutter = this.getEntityById("costCutter");
			this.leadDesigner = this.getEntityById("leadDesigner");
			this.hertz = this.getEntityById( "hertz" );
			this.leadDeveloper = this.getEntityById("leadDeveloper");
			this.guy = this.getEntityById("guy");
			this.sleepingProgrammer = this.getEntityById("sleepingProgrammer");
			
			var stool1:MovieClip = _hitContainer["stool1"];
			var stool2:MovieClip = _hitContainer["stool2"];
			
			setupBag();
			setupDevComputers();
			
			if(this.shellApi.checkEvent( "gotItem_medal_mocktropica" )){
				if(this.shellApi.checkEvent( this.mockEvents.DEFEATED_MFB)){
					this.removeEntity( this.getEntityById("sleepingProgrammer" ) );
					this.removeEntity( this.getEntityById("costCutter" ) );
					this.removeEntity( this.getEntityById("programmer1" ) );
					this.removeEntity( this.getEntityById("programmer2" ) );
					this.removeEntity( this.getEntityById("designer1" ) );
					this.removeEntity( this.getEntityById("designer2" ) );
					this.removeEntity( this.getEntityById("leadDesigner" ) );
					guyShouldFallDownStairs = false;
					devScreenAnim.get(Display).alpha = 1;
					
					Dialog(leadDeveloper.get(Dialog)).setCurrentById("wellDone");
					if( !this.shellApi.checkEvent( GameEvent.GOT_ITEM + this.mockEvents.BUCKET_BOT_COSTUME ))
					{
						SceneUtil.lockInput( this );
						Dialog(leadDeveloper.get( Dialog )).sayById( "welcomeBack" );	
					}	
				}else{
					player.get(Spatial).x = leadDeveloper.get(Spatial).x + 100; 
					player.get(Spatial).y = leadDeveloper.get(Spatial).y; 
					CharUtils.setDirection(player, false);
					guyShouldFallDownStairs = false;
					
					this.removeEntity( hertz );
					this.removeEntity( this.getEntityById("leadDesigner" ) );
					this.removeEntity( this.getEntityById("sleepingProgrammer" ) );
					this.removeEntity( this.getEntityById("costCutter" ) );
					this.removeEntity( this.getEntityById("programmer1" ) );
					this.removeEntity( this.getEntityById("programmer2" ) );
					this.removeEntity( this.getEntityById("designer1" ) );
					this.removeEntity( this.getEntityById("designer2" ) );
					this.removeEntity( this.getEntityById("leadDesigner" ) );	
					
					Dialog(leadDeveloper.get(Dialog)).sayById("backDoor");
					Dialog(leadDeveloper.get(Dialog)).setCurrentById("backDoor");
					isDay2 = true;
				}
			}else if(this.shellApi.checkEvent( this.mockEvents.SPOKE_WITH_SLEEPER)){
				if(!this.shellApi.checkHasItem( this.mockEvents.SCRIPT)){
					setupTrashCan();
				}
				stool1.alpha = 0;
				stool2.alpha = 0;
				setupTwoDeepEmployees();
				bag.get(Timeline).gotoAndStop("endFalling");
				this.removeEntity( this.getEntityById("costCutter" ) );
				this.removeEntity( this.getEntityById("sleepingProgrammer" ) );
				this.removeEntity( hertz );
				
			}else if(this.shellApi.checkEvent( this.mockEvents.TWO_DEEP_STARTED)){
				setupTwoDeepEmployees();
				setBagBreathing();
				stool1.alpha = 0;
				stool2.alpha = 0;
				
				this.removeEntity( this.getEntityById("costCutter" ) );
				this.removeEntity( hertz );
				setupSleeper();
				
			}else if(this.shellApi.checkEvent( this.mockEvents.WRITER_ASKED_SCRIPT)){
				setupTwoDeepEmployees();
				setBagBreathing();
				stool1.alpha = 0;
				stool2.alpha = 0;
				
				//proximity to cost cutter starts dialog
				this.addSystem(new ProximitySystem());
				var proximity:Proximity = new Proximity(500, this.player.get(Spatial));
				proximity.entered.addOnce(handleNearCostCutter);
				this.costCutter.add(proximity);
				this.removeEntity( hertz );
				setupSleeper();
			
			}else if ( this.shellApi.checkEvent( this.mockEvents.SAW_INVENTORY_FIXED ) ) {	
				this.removeEntity( this.getEntityById("sleepingProgrammer" ) );
				this.removeEntity( this.getEntityById("costCutter" ) );
				this.removeEntity( hertz );
				this.setupTypingEmployees();
			}else if ( this.shellApi.checkEvent( this.mockEvents.DEVELOPER_RETURNED ) ) {	
				player.get(Spatial).x = leadDeveloper.get(Spatial).x + 100; 
				player.get(Spatial).y = leadDeveloper.get(Spatial).y; 
				CharUtils.setDirection(player, false);
				guyShouldFallDownStairs = false;
				Dialog(leadDeveloper.get(Dialog)).sayById("fix");
				this.removeEntity( this.getEntityById("sleepingProgrammer" ) );
				this.removeEntity( this.getEntityById("costCutter" ) );
				this.removeEntity( hertz );
				this.setupTypingEmployees();
				this.shellApi.completeEvent( this.mockEvents.SAW_INVENTORY_FIXED )
			}else if (this.shellApi.checkEvent(this.mockEvents.CRITICAL_BUG_OCCURRED) ) {	
				this.removeEntity( this.getEntityById("sleepingProgrammer" ) );
				this.removeEntity( this.getEntityById("costCutter" ) );
				this.removeEntity( this.getEntityById("leadDeveloper" ) );
				this.removeEntity( hertz );
				this.setupTypingEmployees();
			}else if (this.shellApi.checkEvent(this.mockEvents.MOUNTAIN_FINISHED) ) {	
				this.removeEntity( this.getEntityById("sleepingProgrammer" ) );
				this.removeEntity( this.getEntityById("costCutter" ) );
				this.removeEntity( this.getEntityById("leadDeveloper" ) );
				this.removeEntity( hertz );
				this.setupTypingEmployees();
			}else if ( this.shellApi.checkEvent( this.mockEvents.RESCUED_DESIGNER ) ) {	
				SceneUtil.lockInput( this );
				
				player.get(Spatial).x = leadDesigner.get(Spatial).x + 100; 
				player.get(Spatial).y = leadDesigner.get(Spatial).y; 
				CharUtils.setDirection(player, false);
				guyShouldFallDownStairs = false;
				Dialog(leadDesigner.get(Dialog)).sayById("mountainFinished");
				this.removeEntity( this.getEntityById("sleepingProgrammer" ) );
				this.removeEntity( hertz );
				this.removeEntity( this.getEntityById("costCutter" ) );
				this.removeEntity( this.getEntityById("leadDeveloper" ) );
				this.setupTypingEmployees();
			}else{ 
				// First time coming into basement //
				this.removeEntity( this.getEntityById("leadDesigner" ) );
				this.removeEntity( this.getEntityById("sleepingProgrammer" ) );
				this.removeEntity( this.getEntityById("costCutter" ) );
				this.removeEntity( hertz );
				this.removeEntity( this.getEntityById("leadDeveloper" ) );
				this.setupTypingEmployees();
			}
			//if we aren't using coins yet
			if ( !this.shellApi.checkEvent( this.mockEvents.ACHIEVEMENT_JUST_FOCUS ) ) { 
				
				lock.get(Display).visible = false;
				var sign:MovieClip = _hitContainer["bathroomSign"];
				sign.alpha = 0;
			}else{
				ToolTipCreator.addUIRollover(lock, ToolTipType.CLICK);
			}
			
			this.setupAnimations();
			checkDialog();
			setupFlies();
			
			if(guyShouldFallDownStairs){
				//finishKnockGuyDownStairs();
				knockGuyDownStairs();
				//CharUtils.followPath(guy, new <Point> [new Point(guy.get(Spatial).x, guy.get(Spatial).y)], knockGuyDownStairs, true);
			}else{
				this.removeEntity( this.getEntityById("guy" ) );
			}
		}
		
		private function handleNearCostCutter(entity:Entity):void {
			SceneUtil.lockInput(this);
			CharUtils.moveToTarget(player, costCutter.get(Spatial).x + 100, costCutter.get(Spatial).y, false, reachedCostCutter);
		}
		
		private function reachedCostCutter(entity:Entity):void {
			CharUtils.setDirection(player, false);
			Dialog(player.get(Dialog)).sayById("laps");
		}
		
		private function knockGuyDownStairs(entity:Entity=null):void {
		//	SceneUtil.lockInput(this);
			var npc:Entity = super.getEntityById("guy");
			
			trace(npc.getAll());
			npc.add(new Tween());
			npc.add(new SpatialOffset());
			
			
			npc.get(Tween).to(npc.get(Spatial), 1, { delay:.2, x:2372, y:600, rotation:"720", ease:Linear.easeNone, onComplete:finishKnockGuyDownStairs });
			guy.get(Tween).to(guy.get(SpatialOffset), .3, { delay:.2, y:-200, ease:Sine.easeInOut, onComplete:endBounce });
	
			CharUtils.setState(npc, CharacterState.HURT);
			CharUtils.setAnim(guy, game.data.animation.entity.character.Hurt);
			
			//var collider:HazardCollider = npc.get(HazardCollider);
			//collider.isHit = true;
			//collider.velocity = new Point(2000, -800);
			//CharUtils.setState(npc, CharacterState.HURT);
			Dialog(guy.get(Dialog)).sayById("oof");
			
			//var te:TimedEvent = new TimedEvent(1, 1, finishKnockGuyDownStairs, true);
			//SceneUtil.addTimedEvent(this, te);
			
			playSound("ouchSound");
		}
		
		private function endBounce():void {
			guy.get(Tween).to(guy.get(SpatialOffset), 1, { delay:.5, y:0, ease:Bounce.easeOut });
		}
		
		private function finishKnockGuyDownStairs():void {
			playSound("fallSound");
			CharUtils.followPath(guy, new <Point> [new Point(2372, 630)], dazed, true);
			CharUtils.stateDrivenOff(guy);
			//dazed(guy);
		}
		
		private function dazed(entity:Entity):void {
			playSound("fallSound");
			guy.get(Spatial).rotation = 0;
			CharUtils.setAnim(guy, game.data.animation.entity.character.Dizzy);
			SceneUtil.lockInput(this, false);
		}
		
		private function useBathroom(character:Entity, interactionEntity:Entity):void
		{
			trace("use bathroom");
		}
		
		private function checkDialog():void {
			if(this.shellApi.checkEvent(mockEvents.GOT_BADGES)){
				if(this.getEntityById("leadDesigner") != null){
					Dialog(designer1.get(Dialog)).setCurrentById("found_staff");
				}
				this.makeComputersAvailable();
			}
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if( event == "bucketBotCard" ) {
				enterCostume();
			} else if( event == "getCostume" ){
				getCostume();
			}else if(event == "designer1") {
				firstConversation[0] = 1;
				checkFirstConversation();
			} else if(event == "designer2") {
				firstConversation[1] = 1;
				checkFirstConversation();
			} else if(event == "programmer1") {
				firstConversation[2] = 1;
				checkFirstConversation();
			} else if(event == "programmer2") {
				firstConversation[3] = 1;
				checkFirstConversation();
			}else if(event == "findThem") {
				SceneUtil.lockInput(this);
			}else if(event == "getBadges") {
				//get badge cards
				var te:TimedEvent = new TimedEvent(0.2, 1, getDevID, true);
				SceneUtil.addTimedEvent(this, te);
				shellApi.getItem(mockEvents.DESIGNER_ID,null,true );
				this.shellApi.completeEvent(mockEvents.GOT_BADGES);
				this.makeComputersAvailable();
				Dialog(designer1.get(Dialog)).setCurrentById("found_staff");
			}else if(event == "questOn") {
				
			}else if(event == "mountainFinished") {
				if(!this.shellApi.checkEvent(this.mockEvents.MOUNTAIN_FINISHED)){	
					this.shellApi.completeEvent(this.mockEvents.SET_NIGHT);
					this.shellApi.completeEvent(this.mockEvents.SET_RAIN);
					this.shellApi.completeEvent(this.mockEvents.MOUNTAIN_FINISHED);	
					triggerCriticalBug();
				}
			}else if(event == "findHim") {
				SceneUtil.lockInput(this, false);
			}else if(event == "twoDeep") {
				CharUtils.followPath(costCutter, new <Point> [new Point(2000, 900)], removeCostCutter, true);
			}else if(event == "inventoryFixed") {
				this.shellApi.completeEvent(this.mockEvents.INVENTORY_FIXED);
			}else if(event == "backToSleep") {
				SkinUtils.setEyeStates(sleepingProgrammer, "closed");
			}else if(event == "spokeToSleeper") {
				Dialog(sleepingProgrammer.get(Dialog)).setCurrentById("mother");
				SkinUtils.setEyeStates(sleepingProgrammer, "closed");
			}else if(event == "cake_used") {
				if(bagMoved && !this.shellApi.checkEvent(this.mockEvents.SPOKE_WITH_SLEEPER)){
					if(Dialog(sleepingProgrammer.get(Dialog)).initiated || Dialog(sleepingProgrammer.get(Dialog)).speaking){
						Dialog(sleepingProgrammer.get(Dialog)).complete.addOnce(useCakeAfterSpeech);
					}else{
						SceneUtil.lockInput(this);				
						CharUtils.moveToTarget(player, sleepingProgrammer.get(Spatial).x - 100, 900, false, giveCake);
					}
				}else{
					this.shellApi.triggerEvent("wrong_cake_use");
				}
			}else if(event == "jumpUp") {
				CharUtils.setAnim(sleepingProgrammer, Stand);
				Dialog(sleepingProgrammer.get(Dialog)).sayById("cake");
			}else if(event == "runOut") {
				var index:int = this._hitContainer.getChildIndex(this._hitContainer["bag"]);
				var display:Display = sleepingProgrammer.get(Display);
				this._hitContainer.setChildIndex(display.displayObject, index+2);
				CharUtils.followPath(sleepingProgrammer, new <Point> [new Point(1500, 900)], removeSleepingProgrammer, true);
			}else if(event == "faceLeft") {
				faceLeft(player);
			}else if(event == mockEvents.USED_DES_COMPUTER){
				shellApi.triggerEvent(mockEvents.MAINSTREET_FINISHED,true);
			}else if(event == "openHud"){
				var hud:Hud = super.getGroupById( Hud.GROUP_ID ) as Hud;
				hud.hideButton(Hud.INVENTORY, false);
				hud.openHud(true);
			}
		}
		
		private function useCakeAfterSpeech(dialogData:DialogData):void
		{
			SceneUtil.lockInput(this);				
			CharUtils.moveToTarget(player, sleepingProgrammer.get(Spatial).x - 100, 900, false, giveCake);
		}
		
		private function giveCake(entity:Entity):void
		{
			CharUtils.setDirection(player, true);
			(super.getGroupById( "itemGroup" ) as ItemGroup).takeItem( mockEvents.CAKE, "sleepingProgrammer", "", null, saySmellCake );
			shellApi.removeItem( mockEvents.CAKE );
		}
		
		private function saySmellCake():void
		{
			Dialog(sleepingProgrammer.get(Dialog)).sayById("smell");
		}
		
		private function getDevID():void {
			shellApi.getItem(mockEvents.DEVELOPER_ID,null,true );
			var te:TimedEvent = new TimedEvent(0.2, 1, getWriterID, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function getWriterID():void {
			shellApi.getItem(mockEvents.WRITER_ID,null,true );
			SceneUtil.lockInput(this, false);
		}
		
		private function removeSleepingProgrammer(entity:Entity):void {
			this.removeEntity( this.getEntityById("sleepingProgrammer" ) );
			SceneUtil.lockInput(this, false);
			this.shellApi.completeEvent(this.mockEvents.SPOKE_WITH_SLEEPER);
		}
		
		private function removeCostCutter(entity:Entity):void {
			this.removeEntity( this.getEntityById("costCutter" ) );
			SceneUtil.lockInput(this, false);
			this.shellApi.completeEvent(this.mockEvents.TWO_DEEP_STARTED);
		}
		
		private function setupSleeper():void {
			if(!this.shellApi.checkHasItem( this.mockEvents.CAKE)){
				setupTrashCan();
				this.shellApi.getItem( this.mockEvents.CAKE);
			}
			CharUtils.setAnim(sleepingProgrammer, SitSleepLoop);
			
			var dialog:Dialog = sleepingProgrammer.get(Dialog);
			dialog.faceSpeaker = false;
			
			var index:int = this._hitContainer.getChildIndex(this._hitContainer["bag"]);
			var display:Display = sleepingProgrammer.get(Display);
			this._hitContainer.setChildIndex(display.displayObject, index);
		}
		
		private function checkFirstConversation():void {
			if(!this.shellApi.checkEvent(mockEvents.GOT_BADGES)){
				if(firstConversation[0] == 1 && firstConversation[1] == 1 && firstConversation[2] == 1 && firstConversation[3] == 1){
					CharUtils.moveToTarget(player, 1164, 900, false, faceLeft);
					Dialog(designer1.get(Dialog)).sayById("without");
					Dialog(designer1.get(Dialog)).setCurrentById("quest");
				}
			}
		}
		
		private function faceLeft(entity:Entity):void
		{
			CharUtils.setDirection(player, false);
		}
		
		private function setupCustomDialog():void
		{
			lock = new Entity();
			var dialog:Dialog = new Dialog()
			dialog.faceSpeaker = true;     // the display will turn towards the player if true.
			dialog.dialogPositionPercents = new Point(0, 1);  // set the percent of the bounds that the dialog is offset.  The current arts will cause it to be offset 0% on x axis and 100% on y (66px).
			
			lock.add(dialog);
			lock.add(new Id("bathroomPerson"));
			lock.add(new Spatial());
			lock.add(new Display(_hitContainer["bathroomLock"]));
			lock.add(new Edge(33, 66, 33, 0));   //set the distance from the characters registration point.
			lock.add(new Character());           //allows this entity to get picked up by the characterInteractionSystem for dialog on click
			
			InteractionCreator.addToEntity(lock, [InteractionCreator.DOWN]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.offsetX = 120;
			sceneInteraction.offsetY = 0;
			lock.add(sceneInteraction);
			
			super.addEntity(lock);
		}
		
		override protected function addCharacterDialog(container:Sprite):void
		{
			// custom dialog entity MUST be added here so that dialog from the xml gets assigned to it.
			setupCustomDialog();
			super.addCharacterDialog(container);
		}
		
		private function setupDevComputers():void
		{
			// dev popup
			var dev:Entity = getEntityById("devCompInteraction");
			var devInteraction:SceneInteraction = dev.get( SceneInteraction );
			devInteraction.reached.removeAll();
			devInteraction.offsetX = 30;
			devInteraction.offsetY = 140;				// design popup
			ToolTipCreator.removeFromEntity( dev );
			dev.remove(Interaction);
			
			var des:Entity = getEntityById("designCompInteraction");			
			var desInteraction:SceneInteraction = des.get( SceneInteraction );
			desInteraction.reached.removeAll();
			desInteraction.offsetX = 30;
			desInteraction.offsetY = 140;	
			ToolTipCreator.removeFromEntity( des );
			des.remove(Interaction);
			
			
			var flashClip:MovieClip = MovieClip(_hitContainer)["flash"];
			flash = TimelineUtils.convertClip( flashClip, this, flash );
			flash.get(Timeline).gotoAndStop(1);
			
			var clip:MovieClip = _hitContainer["desScreenAnim"];
			desScreenAnim = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			desScreenAnim.add(spatial);
			desScreenAnim.add(new Display(clip));
			desScreenAnim.get(Display).alpha = 0;
			desScreenAnim.add(new Tween());
			
			super.addEntity(desScreenAnim);	
			
			var clip2:MovieClip = _hitContainer["devScreenAnim"];
			devScreenAnim = new Entity();
			var spatial2:Spatial = new Spatial();
			spatial2.x = clip2.x;
			spatial2.y = clip2.y;
			
			devScreenAnim.add(spatial2);
			devScreenAnim.add(new Display(clip2));
			devScreenAnim.get(Display).alpha = 0;
			devScreenAnim.add(new Tween());
			
			super.addEntity(devScreenAnim);	
		
		}
		
		private function makeComputersAvailable():void 
		{
			var dev:Entity = getEntityById("devCompInteraction");
			var des:Entity = getEntityById("designCompInteraction");
			ToolTipCreator.addToEntity( dev );
			ToolTipCreator.addToEntity( des );
			var devInteraction:SceneInteraction = dev.get( SceneInteraction );
			var desInteraction:SceneInteraction = des.get( SceneInteraction );
			devInteraction.reached.add( devPopup );
			desInteraction.reached.add( designPopup );
			InteractionCreator.addToEntity(dev, [InteractionCreator.CLICK]);
			InteractionCreator.addToEntity(des, [InteractionCreator.CLICK]);

			desScreenAnim.get(Tween).to(desScreenAnim.get(Display), 1, { alpha:1, ease:Sine.easeInOut });
			devScreenAnim.get(Tween).to(devScreenAnim.get(Display), 1, { alpha:1, ease:Sine.easeInOut });
		}
		
		private function designPopup(character:Entity, interactionEntity:Entity):void
		{
			var popup:DesignComputerPopup = super.addChildGroup( new DesignComputerPopup( super.overlayContainer )) as DesignComputerPopup;
			popup.id = "design";
		}
		private function devPopup(character:Entity, interactionEntity:Entity):void
		{
			if(!isDay2){
				//var te:TimedEvent = new TimedEvent(0.7, 1, afterDevComputer, true);
				//SceneUtil.addTimedEvent(this, te);
				
				var popup:DeveloperComputerPopup = super.addChildGroup( new DeveloperComputerPopup( super.overlayContainer )) as DeveloperComputerPopup;
				popup.popupRemoved.addOnce(afterDevComputer);
				popup.id = "development";
			}else{
				startDissolve();
			}
		}
		
		private function afterDevComputer():void{
			var mountainIsFullyRendered:Boolean = shellApi.checkEvent(mockEvents.MOUNTAIN_FINISHED);
			var criticalBugOccurred:Boolean = shellApi.checkEvent(mockEvents.CRITICAL_BUG_OCCURRED);
			var weatherIsClear:Boolean = shellApi.checkEvent(mockEvents.SET_CLEAR);
			
			if (weatherIsClear) {	// maybe player just turned off the rain, trying to get to Billy Jordan up top
				if (mountainIsFullyRendered) {	// we know they have rescued the designer
					if (! criticalBugOccurred) {
						trace("for some reason, the Critical Bug has not yet occurred, even though the mountain is fully rendered. Sounds foolish, I know - but we need that Critical Bug!");
						triggerCriticalBug();
						return;
					}
				}
			}

			Dialog(player.get(Dialog)).sayById("easy");	
		}
		
		// this is where we trigger the breakage animation
		private function triggerCriticalBug():void
		{
			SceneUtil.lockInput(this);
			this.shellApi.completeEvent(mockEvents.CRITICAL_BUG_OCCURRED);
			var hud:MocktropicanHUD = super.getGroupById( "hud" ) as MocktropicanHUD;
			hud.shouldDemonstrateCriticalBug = true;
			hud.openHud(true);
			hud.demonstrationCompleted.addOnce( criticalBugDialog);
		}
		
		private function criticalBugDialog():void 
		{
			CharUtils.setDirection(player, true);
			Dialog(designer2.get(Dialog)).sayById("bug");
		}
		
		private function setupTrashCan():void {
			can = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["trashCan"]), this);
			can.remove(Timeline);
			
			canInteraction = can.get(Interaction);
			canInteraction.downNative.add( Command.create( onCanDown ));
		}
		
		private function onCanDown(event:Event):void {
			if(!this.shellApi.checkEvent( "gotItem_script" )){
				SceneUtil.lockInput(this);
				CharUtils.moveToTarget(player, can.get(Spatial).x - 100, 900, false, openCan);
			}else{
				canInteraction.downNative.removeAll();
				can.remove(ToolTip);
			}
		}
		
		private function openCan(entity:Entity):void
		{
			CharUtils.setDirection(player, true);
			SceneUtil.lockInput(this, false);
			var popup:TrashCanPopup = super.addChildGroup( new TrashCanPopup( super.overlayContainer )) as TrashCanPopup;
		}
		
		private function setupBag():void {
			bag = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["bag"]), this);
			bag.get(Timeline).gotoAndStop(1);
			bagToolTip = bag.get(ToolTip);
			bag.remove(ToolTip);
		}
		
		private function setBagBreathing():void {
			//bag = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["bag"]), this);
			bag.add(bagToolTip);
			bag.get(Timeline).gotoAndPlay("breathing");
			bagInteraction = bag.get(Interaction);
			bagInteraction.downNative.addOnce( Command.create( onBagDown ));
		}
		
		private function onBagDown(event:Event):void {
			bag.get(Timeline).gotoAndPlay("falling");
			playSound("bagSound");
			setupTrashCan();
			bagMoved = true;
			bag.remove(ToolTip);
		}
		
		private function setupAnimations():void
		{
			var animations:Array = ["poptropicaInteraction", "foldoutInteraction", "fridge1Interaction", "microwave1Interaction", "machineInteraction"];
			for(var i:int = 0; i < animations.length; i++)
			{
				var entity:Entity = this.getEntityById(animations[i]);
				
				if(animations[i] == "fridge1Interaction")
					TimelineUtils.convertClip(this._hitContainer[animations[i]]["fridge"], this, entity);
				else TimelineUtils.convertClip(this._hitContainer[animations[i]], this, entity);
				
				var id:String = Id(entity.get(Id)).id;
				if(id.indexOf("microwave") > -1)
				{
					var spatial:Spatial = entity.get(Spatial);
					
					var smoke:MicrowaveSmoke = new MicrowaveSmoke();
					smoke.init();
					
					EmitterCreator.create(this, this._hitContainer, smoke, -30, 20, null, "smoke" + id.charAt(9), spatial);
				}
				if(id.indexOf("machine") > -1)
				{
					machine = entity;
				}
				var interaction:SceneInteraction = entity.get(SceneInteraction);
				
				interaction.approach = false;
				
				/**
				 * The animations array is set up so that all of the one-time use interactions are first. Anything
				 * that gets triggered once is <= 2 (foldout), and anything after is done every time it's clicked.
				 */
				if(i <= 1) interaction.triggered.addOnce(playAnimation);
				else interaction.triggered.add(playAnimation);
			}
		}
		
		private function playAnimation(player:Entity, interaction:Entity):void
		{
			var id:String = Id(interaction.get(Id)).id;
			if(id.indexOf("machine") > -1){
				if ( this.shellApi.checkEvent( this.mockEvents.ACHIEVEMENT_JUST_FOCUS ) ) { 
					runMachine();
				}else{
					Dialog(player.get(Dialog)).sayById("money");
				}
			}else{
				var timeline:Timeline = interaction.get(Timeline);
				if(timeline.playing) return;
				timeline.gotoAndPlay(0);
			}
			
			if(id.indexOf("fridge") > -1){
				timeline.handleLabel("trigger", makeCockroach);
				playSound("openFridgeSound");
				timeline.handleLabel("end", playCloseFridge);
			} else if(id.indexOf("microwave") > -1){
				timeline.handleLabel("trigger", burnFood);
				playSound("microwaveSound");
			}else if(id.indexOf("foldout") > -1){
				playSound("foldoutSound");
			}else if(id.indexOf("poptropica") > -1){
				playSound("poptropicaSound");
			}
		}
		
		private function playCloseFridge():void
		{
			playSound("closeFridgeSound");
		}
		
		private function runMachine():void
		{
			//SceneUtil.lockInput(this);
			CharUtils.moveToTarget(player, 349, 900, false, insertCoin);
		}
		
		private function insertCoin(entity:Entity):void {
			CharUtils.setDirection(player, true);
			CharUtils.setAnim(player, game.data.animation.entity.character.Salute);
			var te:TimedEvent = new TimedEvent(1, 1, runMachine2, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function runMachine2():void {
			playSound("drinkSound");
			
			var timeline:Timeline = machine.get(Timeline);
			if(timeline.playing) return;
			timeline.gotoAndPlay(0);
		}
		
		private function makeCockroach():void
		{
			
		}
		
		private function burnFood():void
		{
			var emitter:Entity = this.getEntityById("smoke" + 1);
			Emitter(emitter.get(Emitter)).emitter.start();
		}
		
		private function setupTypingEmployees():void
		{
			var employees:Array = ["programmer1", "programmer2", "designer1", "designer2"];
			for(var i:int = 0; i < employees.length; i++)
			{
				var employee:Entity = this.getEntityById(employees[i]);
				
				//SkinUtils.setRandomSkin(employee);
				
				var dialog:Dialog = employee.get(Dialog);
				dialog.faceSpeaker = false;
				
				var rigAnim:RigAnimation = CharUtils.getRigAnim(employee, 1);
				if (rigAnim == null)
				{
					var slot:Entity = AnimationSlotCreator.create(employee);
					rigAnim = slot.get( RigAnimation ) as RigAnimation;
				}
				rigAnim.next = KeyboardTyping;
				rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.HAND_BACK);
			}
			
			//positional typing sound
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "keyboard_typing_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			
			entity.add(audio);
			entity.add(new Spatial(950, 750));
			entity.add(new AudioRange(1000, 0, 0.6, Quad.easeIn));
			entity.add(new Id("typingSource"));
			super.addEntity(entity);
		}
		private function setupTwoDeepEmployees():void
		{
			var employees:Array = ["programmer1", "programmer2", "designer1", "designer2"];
			
			for(var i:int = 0; i < employees.length; i++)
			{
				var employee:Entity = this.getEntityById(employees[i]);
				
				var dialog:Dialog = employee.get(Dialog);
				dialog.faceSpeaker = false;
				
				var rigAnim:RigAnimation = CharUtils.getRigAnim(employee, 1);
				if (rigAnim == null)
				{
					var slot:Entity = AnimationSlotCreator.create(employee);
					rigAnim = slot.get( RigAnimation ) as RigAnimation;
				}
				if(i == 1 || i == 3){
					employee.get(Spatial).rotation += 20;
					employee.get(Spatial).x += 34;
				}else{
					employee.get(Spatial).x += 330;
					CharUtils.setDirection(employee, false);
					rigAnim.next = KeyboardTyping;
				}
				rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.HAND_BACK);
			}
		}
		
		private function setupFlies():void {
			var fliesEmitter:SwarmingFlies = new SwarmingFlies();
			_fliesEntity = EmitterCreator.create(this, super._hitContainer, fliesEmitter, 0, 0);
			fliesEmitter.init(new Point(2310, 727));

			//positional flies sound
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "insect_flies_02_L.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			//entity.add(new Display(super._hitContainer["soundSource"]));
			entity.add(audio);
			entity.add(new Spatial(2310, 727));
			entity.add(new AudioRange(500, 0, 0.6, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
		}
		
		public function startDissolve():void {
			matrixDissolveEmitter = new MatrixDissolveEmitter(); 
			matrixDissolve = EmitterCreator.create(this, super._hitContainer, matrixDissolveEmitter, 0, 0, player, "dissolveEntity", player.get(Spatial));
			this.getEntityById("dissolveEntity").get(Display).alpha = .8;
			matrixDissolveEmitter.init();
			
			player.add(new Tween());
			player.get(Tween).to(player.get(Display), 1.8, { alpha:0, ease:Sine.easeInOut, onComplete:goInComputer });
		}
		
		private function goInComputer():void {
			player.get(Tween).to(player.get(Spatial), .2, { x:714, y:765, ease:Sine.easeInOut, onComplete:inComputer });
			flash.get(Timeline).gotoAndPlay(2);
		}
		
		private function inComputer():void {
			var te:TimedEvent = new TimedEvent(1, 1, openBonusQuestPopup, true);
			SceneUtil.addTimedEvent(this, te);
		}
		
		private function openBonusQuestPopup():void {
			SceneUtil.lockInput(this);
			var te:TimedEvent = new TimedEvent(0.5, 1, restorePlayer, true);
			SceneUtil.addTimedEvent(this, te);
			
			var popup:BonusQuestPopup = super.addChildGroup( new BonusQuestPopup(super.overlayContainer )) as BonusQuestPopup;
		}
		
		private function restorePlayer():void
		{
			player.get(Spatial).x = leadDeveloper.get(Spatial).x + 100; 
			player.get(Spatial).y = leadDeveloper.get(Spatial).y; 
			player.get(Display).alpha = 1;
			CharUtils.setDirection(player, false);
			SceneUtil.lockInput(this, false);
		}
		
		public function playSound(sound:String):void {
			switch(sound){
				case "drinkSound":
					super.shellApi.triggerEvent("drinkSound");
					break;
				case "openFridgeSound":
					super.shellApi.triggerEvent("openFridgeSound");
					break;
				case "closeFridgeSound":
					super.shellApi.triggerEvent("closeFridgeSound");
					break;
				case "microwaveSound":
					super.shellApi.triggerEvent("microwaveSound");
					break;
				case "foldoutSound":
					super.shellApi.triggerEvent("foldoutSound");
					break;
				case "poptropicaSound":
					super.shellApi.triggerEvent("poptropicaSound");
					break;
				case "ouchSound":
					super.shellApi.triggerEvent("ouchSound");
					break;
				case "fallSound":
					super.shellApi.triggerEvent("fallSound");
					break;
				case "bagSound":
					super.shellApi.triggerEvent("bagSound");
					break;
			}
		}
		
		private function enterCostume():void
		{
			var dialog:Dialog = hertz.get( Dialog );
			dialog.complete.removeAll();
			
			SceneUtil.lockInput( this );
			var entity:Entity = EntityUtils.createMovingEntity( this, _hitContainer[ "bucketBotCostume" ]);
			entity.add( new Id( "bucketBotCostume" ));
			Display( entity.get( Display )).alpha = 0;
			var spatial:Spatial = entity.get( Spatial );
			
			var dissolveEmitter:MatrixDissolveEmitter = new MatrixDissolveEmitter(); 
			var dissolve:Entity = EmitterCreator.create(this, super._hitContainer, dissolveEmitter, 0, 0, entity, "dissolveEntity", entity.get(Spatial));
			this.getEntityById("dissolveEntity").get(Display).alpha = .8;
			dissolveEmitter.init();
			
			var tween:Tween = new Tween();
			entity.add( tween );
			tween.to( spatial, 1, { x : 969, y : 874, onComplete : fadeInCostume, onCompleteParams : [ entity ]});
		}
		
		private function fadeInCostume( entity:Entity ):void
		{
			var display:Display = entity.get( Display );
			var tween:Tween = entity.get( Tween );
			
			tween.to( display, 1, { alpha : 1, onComplete : readNote });
		}
		
		private function readNote():void
		{
			var dialog:Dialog = leadDeveloper.get( Dialog );
			dialog.sayById( "theresANote" );
			
			CharUtils.setDirection( hertz, true );
		}
		
		private function getCostume():void
		{
			CharUtils.moveToTarget( player, 969, 874, false, pickupCostume );
		}
		
		private function pickupCostume( entity:Entity ):void
		{
			super.removeEntity( getEntityById( "bucketBotCostume" ));
			super.shellApi.getItem( "bucket_bot_costume", null, true );
			SceneUtil.lockInput( this, false );
		}
	}
}



