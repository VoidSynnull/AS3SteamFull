package game.scenes.carnival.apothecary{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.hit.Platform;
	import game.components.hit.Wall;
	import game.components.motion.Destination;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.CarnivalEvents;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.SceneUtil;
	
	public class Apothecary extends PlatformerGameScene
	{
		private var _events:CarnivalEvents;
		public function Apothecary()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/apothecary/";
			
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
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			_events = new CarnivalEvents();
			
			initEntities();
			checkEvents();
			setDepths();
			setListeners();
			
			super._hitContainer["vent"].mouseEnabled = false;
			super._hitContainer["vent"].mouseChildren = false;
			
			// check vent
			if(!super.shellApi.checkEvent(_events.OPENED_VENT)){
				if(super.shellApi.sceneManager.previousScene == "game.scenes.carnival.autoRepair::AutoRepair" || Spatial(super.player.get(Spatial)).x > 1700){
					playerInVent();
				} else {
					// remove vent door
					super.removeEntity(super.getEntityById("doorAutoRepair"));
					
					// remove hits
					var ventPlatform:Entity = super.getEntityById("vent");
					ventPlatform.remove(Platform);
					
					var ventWall:Entity = super.getEntityById("ventWall");
					ventWall.remove(Wall);
				}
			} else {
				openVent();
			}
		}
		
		private function setListeners():void
		{
			// setup dialog listeners for DrDan and the Player
			if(!super.shellApi.checkEvent(_events.SET_NIGHT) && !super.shellApi.checkHasItem(_events.MEDAL_CARNIVAL)){
				Dialog(super.player.get(Dialog)).start.add(dialogStart);
				Dialog(super.getEntityById("drdan").get(Dialog)).start.add(dialogStart);
			}
		}		
		
		private function dialogStart($dialogData:DialogData):void
		{
			// lock controls upon the below ids
			switch($dialogData.id){
				case "helpWithOrder":
					SceneUtil.lockInput(this, true);
					break;
				case "saltWater":
					SceneUtil.lockInput(this, true);
					break;
				case "gotOsmium":
					SceneUtil.lockInput(this, true);
					break;
				case "askLab":
					SceneUtil.lockInput(this, true);
					break;
			}
			
			switch($dialogData.event){
				case "need_weight":
					SceneUtil.lockInput(this, true);
					break;
			}
		}		
		
		//---------- SCENE SETUP ------------
		
		private function initEntities():void
		{	
			// setup reactor (interactive - popup)
			_reactor = ButtonCreator.createButtonEntity(super._hitContainer["reactor"], this, onReactor);
			
			// setup poster (interactive - popup)
			_poster = ButtonCreator.createButtonEntity(super._hitContainer["biochemPoster"], this, onPoster);
			
			// setup colaMachine (interactive - gives item)
			_colaMachine = ButtonCreator.createButtonEntity(super._hitContainer["colaMachine"], this, onCola);
			
			// setup chems (interactive - items)
			_blueChem1 = ButtonCreator.createButtonEntity(super._hitContainer["blueChem1"], this, onChemical);
			_blueChem2 = ButtonCreator.createButtonEntity(super._hitContainer["blueChem2"], this, onChemical);
			_blueChem3 = ButtonCreator.createButtonEntity(super._hitContainer["blueChem3"], this, onChemical);
			_yellowChem1 = ButtonCreator.createButtonEntity(super._hitContainer["yellowChem1"], this, onChemical);
			_yellowChem2 = ButtonCreator.createButtonEntity(super._hitContainer["yellowChem2"], this, onChemical);
			_redChem1 = ButtonCreator.createButtonEntity(super._hitContainer["redChem1"], this, onChemical);	
			_purpleChem1 = ButtonCreator.createButtonEntity(super._hitContainer["purpleChem1"], this, onChemical);
			
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.AMBIENT_PATH + "AMB_freezerRoom.mp3", true, [SoundModifier.POSITION])
			entity.add(audio);
			entity.add(new Spatial(Spatial(_reactor.get(Spatial)).x, Spatial(_reactor.get(Spatial)).y-100));
			entity.add(new AudioRange(650, .2, .7, Quad.easeIn));
			entity.add(new Id("soundSource2"));
			super.addEntity(entity);
			
			_reactorHit = super.getEntityById("furnace");
			_reactorPlat = _reactorHit.get(Platform);
		}
		
		
		private function checkEvents():void
		{
			// DEV TEST
			
			// remove chems if already used
			if(super.shellApi.checkEvent(_events.SALT_GIVEN) || super.shellApi.checkHasItem(_events.SALT)){
				super.removeEntity(_blueChem1);
				super.removeEntity(_yellowChem1);
			}
			
			if(super.shellApi.checkEvent(_events.SUGAR_GIVEN) || super.shellApi.checkHasItem(_events.SUGAR)){
				super.removeEntity(_blueChem2);
				super.removeEntity(_purpleChem1);
			}
			
			if(super.shellApi.checkHasItem(_events.SODIUM_THIOPENTAL) || super.shellApi.checkHasItem(_events.MEDAL_CARNIVAL)){
				super.removeEntity(_blueChem3);
				super.removeEntity(_yellowChem2);
				super.removeEntity(_redChem1);
			}
			
			// show osmium cart?
			//if(!super.shellApi.checkEvent(_events.NEED_WEIGHT)){
			if(!super.shellApi.checkEvent(_events.SET_EVENING)){
				super._hitContainer["handTruck"].visible = false; // hide osmium
			}
			
			// night
			if(super.shellApi.checkEvent(_events.SET_NIGHT) || super.shellApi.checkHasItem(_events.MEDAL_CARNIVAL)){
				super.removeEntity(super.getEntityById("drdan"));
			}
		}
		
		private function setDepths():void
		{
			// set npc behind the counter
			if(!super.shellApi.checkEvent(_events.SET_NIGHT) && !super.shellApi.checkHasItem(_events.MEDAL_CARNIVAL)){
				var npc:Entity = super.getEntityById("drdan");
				//var counter:BitmapWrapper = super.convertToBitmapSprite(super._hitContainer["counter"], null, true);  // was removing the display object reference
				DisplayUtils.moveToOverUnder( super._hitContainer["counter"], Display(npc.get(Display)).displayObject);
				super._hitContainer.setChildIndex(super._hitContainer["handTruck"], super._hitContainer.numChildren-1);
				super._hitContainer.setChildIndex(super.player.get(Display).displayObject, super._hitContainer.numChildren-1);
			}
		}
		
		//---------- MISC METHODS ----------
		
		private function onCola($entity:Entity):void
		{
			CharUtils.moveToTarget(super.player, Spatial(_colaMachine.get(Spatial)).x, Spatial(_colaMachine.get(Spatial)).y, false, getCola);
		}
		
		private function getCola($entity:Entity):void{
			if(!super.shellApi.checkHasItem(_events.COLA)){
				if(super.shellApi.checkHasItem(_events.CHEMICAL_X_FORMULA)){
					super.shellApi.triggerEvent("soda");
					super.shellApi.getItem(_events.COLA, null, true);
				} else {
					Dialog(super.player.get(Dialog)).sayById("noSoda");
				}
			}
		}
		
		private function readyHandTruck():void{
			_handTruck = ButtonCreator.createButtonEntity(super._hitContainer["handTruck"], this, onHandTruck);
		}
		
		private function onHandTruck($entity:Entity):void
		{
			CharUtils.moveToTarget(super.player, Spatial(_handTruck.get(Spatial)).x, Spatial(_handTruck.get(Spatial)).y, false, reachedTruck);
		}
		
		private function reachedTruck($entity:Entity):void
		{
			// show osmium popup
			if(!super.shellApi.checkHasItem("vial")){
				var popup:OsmiumPopup = super.addChildGroup(new OsmiumPopup(super.overlayContainer)) as OsmiumPopup;
				popup.id = "osmiumPopup";
				popup.gotOsmium.addOnce(getOsmium);
			}
		}
		
		private function getOsmium():void{
			Dialog(super.player.get(Dialog)).sayById("gotOsmium");
		}
		
		public function playerInVent():void{
			// bring vent and newspapers to front
			_ventIndex = super._hitContainer.getChildIndex(super._hitContainer["vent"]);
			
			super._hitContainer.setChildIndex(super._hitContainer["vent"], super._hitContainer.numChildren - 1);
			super._hitContainer.setChildIndex(super._hitContainer["newspapers"], super._hitContainer.numChildren - 1);
			
			// position player
			Spatial(super.player.get(Spatial)).x = 1780;
			Spatial(super.player.get(Spatial)).y = 180;
			
			// create newspaper entity
			_newspapers = ButtonCreator.createButtonEntity(super._hitContainer["newspapers"], this, onNewspapers);
		}
		
		private function onNewspapers($entity:Entity):void{
			CharUtils.moveToTarget(super.player, Spatial(_newspapers.get(Spatial)).x, Spatial(_newspapers.get(Spatial)).y, false, atNewspapers);
		}
		
		private function atNewspapers($entity:Entity):void{
			SceneUtil.lockInput(this, true);
			Dialog(super.player.get(Dialog)).sayById("newspapers");
		}
		
		private function openVent():void{
			// remove newspapers
			if(_newspapers == null){
				super._hitContainer["newspapers"].visible = false;
			} else {
				super.removeEntity(_newspapers);
			}
			
			// remove vent cover
			super._hitContainer["vent"].grill.gotoAndStop(2);
			
			// remove hits
			var ventPlatform:Entity = super.getEntityById("vent");
			ventPlatform.remove(Platform);
			
			var ventWall:Entity = super.getEntityById("ventWall");
			ventWall.remove(Wall);
			
			// fix depths (if switched)
			if(_ventIndex != 0){
				super._hitContainer.setChildIndex(super._hitContainer["vent"], _ventIndex);
			}
			
			// remove autoRepair door
			super.removeEntity(super.getEntityById("doorAutoRepair"));
			
			super.shellApi.triggerEvent(_events.OPENED_VENT, true);
		}
		
		// -------- EVENT HANDLERS ---------
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if( _lastClickedChem == _checkingChem){
				switch(event){
					case "receiveSaltFormula":
						shellApi.getItem(_events.SALT_FORMULA, null, true);
						SceneUtil.lockInput(this, false);
						break;
					case "gave_salt":
						if(super.shellApi.checkHasItem(_events.SALT)){
							var itemGroup:ItemGroup = this.getGroupById( "itemGroup" ) as ItemGroup;
							itemGroup.takeItem(_events.SALT, "drdan" );
							shellApi.removeItem(_events.SALT);
						}
						SceneUtil.lockInput(this, false);
						break;
					case "makeSugar":
						SceneUtil.lockInput(this, false);
						break;
					case "removePapers":
						// open popup
						var popup:NewspapersPopup= super.addChildGroup(new NewspapersPopup(super.overlayContainer)) as NewspapersPopup;
						popup.id = "newspapersPopup";
						SceneUtil.lockInput(this, false);
						popup.finishSignal.addOnce(openVent);
						break;
					case "allowedOsmium":
						readyHandTruck();
						SceneUtil.lockInput(this, false);
						break;
					case "receiveOsmium":
						SceneUtil.lockInput(this, false);
						super.shellApi.getItem(_events.VIAL_OSMIUM, null, true);
						break;
					case "saltReagent":
						if(shellApi.checkHasItem(_events.SALT_FORMULA) && !shellApi.checkHasItem(_events.SALT)){
							_reactorFormula = "salt";
							// get item
							checkChem(_saltFormula);
						} else {
							// reject item
							rejectChemical();
						}
						break;
					case "sugarReagent":
						if(shellApi.checkHasItem(_events.SUGAR_FORMULA) && !shellApi.checkHasItem(_events.SUGAR) && shellApi.checkEvent(_events.SALT_GIVEN)){
							_reactorFormula = "sugar";
							// get item
							checkChem(_sugarFormula);
						} else {
							// reject item
							rejectChemical();
						}
						break;
					case "truthReagent":
						if(shellApi.checkHasItem(_events.FORMULA) && !shellApi.checkHasItem(_events.SODIUM_THIOPENTAL)){
							_reactorFormula = "sodiumThiopental";
							// get item
							checkChem(_truthFormula);
						} else {
							// reject item
							rejectChemical();
						}
						break;
					case "enteredChemX":
						// set formula for reactor
						_reactorFormula = "chemX";
						// ready reactor
						activateReactor(true);
						
						break;
					case "gotItem_vial":
						shellApi.removeEvent(_events.NEED_WEIGHT);
						break;
				}
			}
		}
		
		
		
		private function checkChem($formula:Array):void{
			//check if already have
			if(!inArray(_lastClickedChem, _currentFormula)){
				// add to _currentFormula
				_currentFormula.push(_lastClickedChem);
				
				// check if formula filled
				var filled:Boolean = true;
				for each(var chem:String in $formula){
					if(!inArray(chem, _currentFormula)){
						filled = false;
					}
				}
				
				_formulaFilled = filled;
				_reactorWaiting = true;
				
				gotoReactor();
			} else {
				
				// check if formula filled
				var filled2:Boolean = true;
				for each(var chem2:String in $formula){
					if(!inArray(chem2, _currentFormula)){
						filled = false;
					}
				}
				
				if(filled2){
					Dialog(super.player.get(Dialog)).sayById("haveAll");
				} else {
					Dialog(super.player.get(Dialog)).sayById("alreadyHave");
				}
				
				//Dialog(super.player.get(Dialog)).sayById("alreadyHave");
			}
			
		}
		
		private function onChemical($entity:Entity):void
		{
			if(!_formulaFilled)
			{
				_lastClickedEntity = $entity;
				_lastClickedChem = Id(_lastClickedEntity.get(Id)).id;
				var spatial:Spatial = _lastClickedEntity.get(Spatial)
				var destination:Destination = CharUtils.moveToTarget(super.player, spatial.x, spatial.y, false, reachedChem, new Point( 30, 100 )); // goto chemical
				destination.ignorePlatformTarget = true;
				destination.validCharStates = new <String>[ CharacterState.STAND, CharacterState.WALK ];
			} 
			else 
			{
				Dialog(super.player.get(Dialog)).sayById("useReactor");
			}
		}
		
		
		private function reachedChem($entity:Entity):void{
			//SceneUtil.lockInput(this, true);
			Dialog(super.player.get(Dialog)).allowOverwrite = true;
			Dialog(super.player.get(Dialog)).sayById(_lastClickedChem);
			_checkingChem = _lastClickedChem;
			//_reactorWaiting = true;
		}
		
		private function gotoReactor():void{
			super.removeEntity(_lastClickedEntity);
			SceneUtil.lockInput(this, false);
			super.shellApi.triggerEvent("bottle"); // play bottle sound
			_reactorHit.remove(Platform); // remove reactor platform (to ease player movement)
			CharUtils.moveToTarget(super.player, Spatial(_reactor.get(Spatial)).x, Spatial(_reactor.get(Spatial)).y, false, putInReactor); // goto reactor -- BUGGED: Doesn't go to reactor, follows your mouse cursor.
		}
		
		private function putInReactor($entity:Entity):void{
			_reactorWaiting = false;
			_reactorHit.add(_reactorPlat);
			if(_formulaFilled){
				Dialog(super.player.get(Dialog)).sayById("haveAll");
				activateReactor(true);
			} else {
				//Dialog(super.player.get(Dialog)).sayById("getIt");
				activateReactor();
			}
		}
		
		private function inArray($obj:*, $array:Array):Boolean{
			var found:Boolean = false;
			
			for each(var obj:* in $array){
				if(obj == $obj){
					found = true;
				}
			}
			
			return found;
		}
		
		private function rejectChemical():void{
			SceneUtil.lockInput(this, false);
			var randInt:int = Math.round(Math.random()*4)+1;
			Dialog(super.player.get(Dialog)).sayById("error"+randInt);
		}
		
		private function onPoster($entity:Entity):void
		{
			var popup:PosterPopup= super.addChildGroup(new PosterPopup(super.overlayContainer)) as PosterPopup;
			//var popup:DossierPopup = super.addChildGroup(new DossierPopup(super.overlayContainer)) as DossierPopup; // test works
			popup.id = "posterPopup";
		}
		
		private function onReactor($entity:Entity):void
		{
			CharUtils.moveToTarget(super.player, Spatial(_reactor.get(Spatial)).x, Spatial(_reactor.get(Spatial)).y, false, checkReactor);
		}
		
		public function testReactor($formula:String = null):void{
			super.shellApi.triggerEvent("powerOn");
			var popup:ReactorPopup = super.addChildGroup(new ReactorPopup(super.overlayContainer, $formula)) as ReactorPopup;
			popup.id = "reactorPopup";
			popup.getProduct.addOnce(waitForReactorClose);
		}
		
		private function getProduct():void{
			switch(_gotProduct){
				case "salt":
					// give salt
					shellApi.getItem(_events.SALT, null, true);
					break;
				case "sugar":
					// give sugar
					shellApi.getItem(_events.SUGAR, null, true);
					break;
				case "sodiumThiopental":
					// give truth serum
					shellApi.getItem(_events.SODIUM_THIOPENTAL, null, true);
					break;
				case "chemX":
					shellApi.getItem(_events.CHEMICAL_X, null, true);
					shellApi.removeItem(_events.COLA);
					shellApi.removeItem(_events.MUSHROOMS);
					shellApi.removeItem(_events.PICKLE_JUICE);
					Dialog(super.player.get(Dialog)).sayById("chemXFinish");
					break;
			}
			_currentFormula = [];
			_formulaFilled = false;
			resetReactor();
		}
		
		private function waitForReactorClose($popup:ReactorPopup, $product:String):void{
			resetReactor();
			_gotProduct = $product;
			$popup.popupRemoved.addOnce(getProduct);
		}
		
		private function checkReactor($entity:Entity):void
		{
			// check that you have formula and chems
			if(!_reactorWaiting){
				if(_reactorReady){
					super.shellApi.triggerEvent("powerOn");
					var popup:ReactorPopup = super.addChildGroup(new ReactorPopup(super.overlayContainer, _reactorFormula)) as ReactorPopup;
					popup.id = "reactorPopup";
					popup.getProduct.addOnce(waitForReactorClose);
				} else if(_reactorActive){
					Dialog(super.player.get(Dialog)).sayById("reactorNotReady2");
				} else if(super.shellApi.checkEvent(_events.STARTED_BONUS_QUEST)
					&& super.shellApi.checkHasItem(_events.CHEMICAL_X_FORMULA) 
					&& super.shellApi.checkHasItem(_events.MUSHROOMS)
					&& super.shellApi.checkHasItem(_events.COLA)
					&& super.shellApi.checkHasItem(_events.PICKLE_JUICE)) {
					// day 2
					Dialog(super.player.get(Dialog)).sayById("chemXReactor");
				} else {
					Dialog(super.player.get(Dialog)).sayById("reactorNotReady1");
				}
			} else {
				// deposit chemical
				putInReactor($entity);
			}
		}
		
		private function activateReactor($ready:Boolean = false):void{
			super.shellApi.triggerEvent("addReagent");
			if(!$ready){
				//Display(_reactor.get(Display)).displayObject.gotoAndStop(2);
				Timeline(_reactor.get(Timeline)).gotoAndStop(1);
				_reactorActive = true;
			} else {
				//Display(_reactor.get(Display)).displayObject.gotoAndStop(3);
				Timeline(_reactor.get(Timeline)).gotoAndStop(2);
				super.shellApi.triggerEvent("reactorReady");
				_reactorReady = true;
			}
		}
		
		private function resetReactor():void{
			Timeline(_reactor.get(Timeline)).gotoAndStop(0);
			_reactorActive = false;
			_reactorReady = false;
			_reactorFormula = null;
		}
		
		private var _ventIndex:int = 0;
		
		private var _lastClickedEntity:Entity;
		private var _lastClickedChem:String;
		private var _checkingChem:String;
		
		private var _handTruck:Entity;
		private var _newspapers:Entity;
		private var _reactor:Entity;
		private var _poster:Entity;
		private var _colaMachine:Entity;
		
		private var _blueChem1:Entity;
		private var _blueChem2:Entity;
		private var _blueChem3:Entity;
		
		private var _yellowChem1:Entity;
		private var _yellowChem2:Entity;
		
		private var _redChem1:Entity;
		
		private var _purpleChem1:Entity;
		
		private var _reactorFormula:String;
		private var _currentFormula:Array = [];
		private var _formulaFilled:Boolean = false;
		
		private var _saltFormula:Array = ["blueChem1","yellowChem1"];
		private var _sugarFormula:Array = ["blueChem2","purpleChem1"];
		private var _truthFormula:Array = ["blueChem3","yellowChem2","redChem1"];
		
		private var _reactorHit:Entity;
		private var _reactorPlat:Platform;
		
		private var _reactorWaiting:Boolean = false;
		private var _reactorActive:Boolean = false;
		private var _reactorReady:Boolean = false;
		private var _gotProduct:String;	
	}
}