package game.scenes.arab1.palaceExterior
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Door;
	import game.components.hit.Zone;
	import game.components.scene.SceneInteraction;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Think;
	import game.scenes.arab1.Arab1Events;
	import game.scenes.arab1.palaceExterior.components.PalaceGuard;
	import game.scenes.arab1.palaceExterior.systems.PalaceGuardSystem;
	import game.scenes.arab1.shared.Arab1Scene;
	import game.scenes.arab1.shared.groups.SmokeBombGroup;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class PalaceExterior extends Arab1Scene
	{
		public function PalaceExterior()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab1/palaceExterior/";
			
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
			
			setupGuards();
			setupZones();
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event){
				case "gotoGuard":
					CharUtils.moveToTarget(_guard2, 750, 1280);
					break;
				case "splitGuard":
					CharUtils.moveToTarget(_guard2, 980, 1280);
					break;
				case "guardsLaugh":
					CharUtils.setAnim(_guard1, Laugh);
					CharUtils.setAnim(_guard2, Laugh);
					SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, endJoke));
					break;
				case "awkwardPause":
					CharUtils.setAnim(_guard1, Think);
					SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, backToWork));
					break;
				case "finishGossip":
					_loiters = 2; 
					break;
				case _events.GUARDS_STAND_DOWN:
					guardReturn(_guard1);
					guardReturn(_guard2);
					resetPlayer();
					break;
			}
		}
		
		private function backToWork(...p):void{
			Dialog(_guard2.get(Dialog)).sayById("bored12");
		}
		
		private function endJoke(...p):void{
			Dialog(_guard1.get(Dialog)).sayById("bet12");
		}
		
		private function setupTests():void
		{
			_smokeBombGroup.createTest(EntityUtils.createSpatialEntity(_smokeBombGroup, _hitContainer["bombTest"], _hitContainer), _smokeBombGroup.testBomb);
			_smokeBombGroup.createTest(EntityUtils.createSpatialEntity(_smokeBombGroup, _hitContainer["smokeTest"], _hitContainer), _smokeBombGroup.testSmoke);
			_smokeBombGroup.createTest(EntityUtils.createSpatialEntity(_smokeBombGroup, _hitContainer["genieTest"], _hitContainer), _smokeBombGroup.testGenie);
		}
		
		private function setupGuards():void
		{
			_guard1 = this.getEntityById("guard1");
			_guard2 = this.getEntityById("guard2");
			
			EntityUtils.removeInteraction(_guard1);
			EntityUtils.removeInteraction(_guard2);
			
			_guard1.add(new PalaceGuard());
			_guard2.add(new PalaceGuard());
			
			PalaceGuard(_guard1.get(PalaceGuard)).alert.add(alertGuard);
			PalaceGuard(_guard2.get(PalaceGuard)).alert.add(alertGuard);
			PalaceGuard(_guard1.get(PalaceGuard)).blind.add(blindGuard);
			PalaceGuard(_guard2.get(PalaceGuard)).blind.add(blindGuard);
			
			_palaceGuardSystem = new PalaceGuardSystem(this);
			
			this.addSystem(_palaceGuardSystem, SystemPriorities.checkCollisions);
			
			// lock door
			SceneInteraction(this.getEntityById("door1").get(SceneInteraction)).reached.removeAll();
			SceneInteraction(this.getEntityById("door1").get(SceneInteraction)).reached.add(reachedDoor);
			
			
		}
		
		private function reachedDoor(...p):void{
			// if both guards are blinded
			if(this.shellApi.checkEvent(_events.GUARDS_STAND_DOWN)){
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"openDoor_pushBar.mp3");
				Door(this.getEntityById("door1").get(Door)).open = true;
			}else if(PalaceGuard(_guard1.get(PalaceGuard)).blinded && PalaceGuard(_guard2.get(PalaceGuard)).blinded){
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"openDoor_pushBar.mp3");
				unlockDoor();
			}
		}

		private function unlockDoor():void {
			Door(this.getEntityById("door1").get(Door)).open = true;
		}
		
		private function blindGuard($entity):void{
			stopConversation();
		}
		
		private function alertGuard($entity, $saySomething:Boolean = true):void{
			stopConversation();
			
			if(!shellApi.checkEvent(_events.GUARDS_STAND_DOWN) && !PalaceGuard($entity.get(PalaceGuard)).alerted){
				
				if(!_alerted && $saySomething){
					Dialog($entity.get(Dialog)).say("What was that!?");
					_alerted = true;
				}
				
				PalaceGuard($entity.get(PalaceGuard)).alerted = true;
				PalaceGuard($entity.get(PalaceGuard)).alertDistance = 600; // alerted, can see player easier
				
			}
		}
		
		private function setupZones():void
		{
			var entity:Entity = super.getEntityById("zoneGuard");
			var zone:Zone = entity.get(Zone);
			zone.pointHit = true;
			zone.entered.add(handleZoneEntered);
			
			entity = super.getEntityById("zoneLoiter");
			zone = entity.get(Zone);
			zone.pointHit = true;
			zone.entered.add(handleZoneEntered);
		}
		
		private function handleZoneEntered(zoneId:String, characterId:String):void
		{
			if(characterId == "player" && zoneId == "zoneGuard" && !confront){
				switch(zoneId){
					case "zoneGuard":
						if(!PalaceGuard(_guard1.get(PalaceGuard)).blinded || !PalaceGuard(_guard2.get(PalaceGuard)).blinded){
							stopConversation();
							//stopPlayer();
							alertGuard(_guard1, false);
							alertGuard(_guard2, false);
						}
						break;
				}
			} else if(zoneId == "zoneLoiter" && !_inConvo && !confront){
				_convoTimer = new TimedEvent(2, 1, startGuardConversation);
				SceneUtil.addTimedEvent(this, _convoTimer);
			}
		}
		
		private function startGuardConversation(...p):void{
			_inConvo = true;
			
			Dialog(_guard1.get(Dialog)).start.add(faceEachOther);
			Dialog(_guard2.get(Dialog)).start.add(faceEachOther);
			
			if(_loiters <= 0){
				Dialog(_guard2.get(Dialog)).sayById("bored");
			} else if(_loiters < 2) {
				Dialog(_guard2.get(Dialog)).sayById("continue");
			} else {
				Dialog(_guard1.get(Dialog)).sayById("betM");
			}
			
			_loiters++;
		}
		
		private function stopConversation():void{
			if(_convoTimer){
				_convoTimer.stop();
				_convoTimer = null;
			}
			
			EntityUtils.removeAllWordBalloons(this);
			EntityUtils.removeAllWordBalloons(this, _guard1);
			EntityUtils.removeAllWordBalloons(this, _guard2);
		}
		
		private function faceEachOther(...p):void{
			if(_inConvo){
				CharUtils.setDirection(_guard1, true);
				CharUtils.setDirection(_guard2, false);
			}
		}
		
		public function stopPlayer():void{
			if(!this.shellApi.checkEvent(_events.GUARDS_STAND_DOWN)){
				// interupt conversation
				stopConversation();
				
				_inConvo = false;
				_palaceGuardSystem.pause = true;
				
				// set timer to allow player to come to a full stop (will develop a better system)
				SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, surroundPlayer));
				
				// stop player
				SceneUtil.lockInput(this);
				CharUtils.lockControls(this.player);
				_unlockFailsafe = new TimedEvent(12, 1, resetPlayer);
				SceneUtil.addTimedEvent(this, _unlockFailsafe);
				
				PalaceGuard(_guard1.get(PalaceGuard)).alerted = true;
				PalaceGuard(_guard2.get(PalaceGuard)).alerted = true;
			}
			
		}
		
		private function surroundPlayer(...p):void{
			
			var charMotionControl:CharacterMotionControl = _guard1.get(CharacterMotionControl);
			if(charMotionControl){
				charMotionControl.maxVelocityX = 800;
			}
			
			charMotionControl = _guard2.get(CharacterMotionControl);
			if(charMotionControl){
				charMotionControl.maxVelocityX = 800;
			}
			
			var playerSpatial:Spatial = this.player.get(Spatial);
			CharUtils.moveToTarget(_guard1, playerSpatial.x - 50, 1280, false, confrontPlayer);
			CharUtils.moveToTarget(_guard2, playerSpatial.x + 50, 1280, false, confrontPlayer);
		}
		
		private function confrontPlayer(...p):void{
			//escortPlayer();
			if(!shellApi.checkEvent(_events.ENTERED_PALACE)){
				if(!confront){
					// play random halt dialog
					if(Math.random() > .5){
						Dialog(_guard1.get(Dialog)).complete.addOnce(guardDialogComplete);
						Dialog(_guard1.get(Dialog)).sayById("halt");
					} else {
						Dialog(_guard2.get(Dialog)).complete.addOnce(guardDialogComplete);
						Dialog(_guard2.get(Dialog)).sayById("halt");
					}
					
					confront = true;
				}
			} else {
				Dialog(_guard1.get(Dialog)).sayById("wait");
			}
		}
		
		private function guardDialogComplete(...p):void
		{
			escortPlayer();
		}
		
		public function easter():void{
			_attempts = 4;
		}
		
		public function easter2():void{
			_loiters = 2;
		}
		
		private function escortPlayer():void{
			
			var charMotionControl:CharacterMotionControl = _guard1.get(CharacterMotionControl);
			charMotionControl.maxVelocityX = 400;
			
			charMotionControl = _guard2.get(CharacterMotionControl);
			charMotionControl.maxVelocityX = 400;
			
			charMotionControl = player.get(CharacterMotionControl);
			charMotionControl.maxVelocityX = 400;
			
			CharUtils.moveToTarget(_guard1, 2070, 1280, true, scoldPlayer);
			CharUtils.moveToTarget(_guard2, 2170, 1280, true);
			CharUtils.moveToTarget(player, 2120, 1280, true);
		}
		
		private function scoldPlayer($entity):void{
			var chance:Number = Math.random();
			
			if(_attempts != 4){
				
				switch(true){
					case chance > 0 && chance <= 0.3 :
						Dialog(_guard1.get(Dialog)).complete.addOnce(returnNPCs);
						Dialog(_guard1.get(Dialog)).say("The palace is not open to outsiders!");
						break;
					case chance > 0.3 && chance <= 0.6 :
						Dialog(_guard2.get(Dialog)).complete.addOnce(returnNPCs);
						Dialog(_guard2.get(Dialog)).say("Now, scram!");
						break;
					case chance > 0.6 && chance <= 1 :
						Dialog(_guard1.get(Dialog)).complete.addOnce(returnNPCs);
						Dialog(_guard1.get(Dialog)).say("Don't let us catch you here again!");
						break;
				}
				
			} else {
				
				// easter egg
				Dialog(_guard2.get(Dialog)).complete.addOnce(returnNPCs);
				Dialog(_guard2.get(Dialog)).say("No, the gift shop isn't here. There would be one to your right.");
			}
			
			_attempts++;
			
		}
		
		private function returnNPCs($entity):void{
			guardReturn(_guard1);
			guardReturn(_guard2);
			resetPlayer();
		}
		
		private function guardReturn($entity:Entity):void{
			PalaceGuard($entity.get(PalaceGuard)).alertDistance = 250;
			PalaceGuard($entity.get(PalaceGuard)).alerted = false;
			
			if(Id($entity.get(Id)).id == "guard1"){
				CharUtils.moveToTarget(_guard1, 650, 1280, false, resetGuard);
			} else {
				CharUtils.moveToTarget(_guard2, 980, 1280, false, resetGuard);
			}
		}
		
		private function resetGuard($entity:Entity):void{
			// reset back to default
			if(_unlockFailsafe){
				_unlockFailsafe.stop();
				_unlockFailsafe = null;
			}
			_alerted = false;
			_palaceGuardSystem.pause = false;
			_inConvo = false;
		}
		
		private function resetPlayer(...p):void{
			SceneUtil.lockInput(this, false);
			CharUtils.lockControls(this.player,false,false);
			confront = false;
			var charMotionControl:CharacterMotionControl = this.player.get(CharacterMotionControl);
			charMotionControl.maxVelocityX = 800;
		}
		
		private var _guard1:Entity;
		private var _guard2:Entity;
		
		private var _palaceGuardSystem:PalaceGuardSystem;
		
		private var _alerted:Boolean = false;
		
		private var _unlockFailsafe:TimedEvent;
		
		private var _attempts:uint = 0;
		private var _loiters:uint = 0;
		private var _inConvo:Boolean = false;
		
		private var _events:Arab1Events = new Arab1Events();
		
		private var confront:Boolean = false;
		
		private var _smokeBombGroup:SmokeBombGroup;
		private var _convoTimer:TimedEvent;
	}
}