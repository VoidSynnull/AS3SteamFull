package game.scenes.prison.messHall
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.Hazard;
	import game.components.hit.ValidHit;
	import game.components.hit.Wall;
	import game.components.hit.Zone;
	import game.components.motion.MotionControl;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Attack;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.Eat;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.PlacePitcher;
	import game.data.animation.entity.character.PointPistol;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Read;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Sleep;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Stomp;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.ItemGroup;
	import game.scenes.prison.PrisonScene;
	import game.scenes.prison.cellBlock.CellBlock;
	import game.scenes.prison.messHall.foodFight.FoodFightGroup;
	import game.scenes.prison.messHall.popups.PotatoSculptPopup;
	import game.scenes.prison.metalShop.particles.Smoke;
	import game.scenes.prison.roof1.Roof1;
	import game.scenes.prison.shared.VentPuzzleGroup;
	import game.scenes.prison.shared.ventPuzzle.VentEnding;
	import game.scenes.prison.yard.Yard;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.FollowAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.RemoveComponentAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.SetDirectionAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.SetSpatialAction;
	import game.systems.actionChain.actions.StopAudioAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.TriggerEventAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.actionChain.actions.ZeroMotionAction;
	import game.systems.entity.character.states.CharacterState;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MessHall extends PrisonScene
	{
		private var vents_on:Boolean = false;
		
		private var ventGroup:VentPuzzleGroup;
		
		private var foodFightGroup:FoodFightGroup;
		
		private var patches:Entity;
		private var ratchet:Entity;
		private var nightingale:Entity;
		private var les:Entity; 
		private var sal:Entity;
		private var florian:Entity;
		private var marion:Entity;
		private var flambe:Entity;
		
		private var kitchenZone:Entity;
		private var potatoPot:Entity;
		private var potatoBlock:Entity;
		private var pasta:Entity;
		private var ventIntake:Entity;
		private var outVents:Entity;
		private var vent1:Entity;
		private var vent2:Entity;
		private var vent3:Entity;
		private var vacumePotato:Entity;
		private var foodFightWall:Entity;
		
		private var stired_potatos:Boolean;	
		private var sucked_up_potatos:Boolean;
		private var escapePipe:Entity;
		private var pipeBurst:Entity;
		private var explode:Entity;
		private var escapeWall:Entity;
		private var escapeFloor:Entity;
		private var ventButton:Entity;
		private var seatClick1:Entity;
		private var seatClick2:Entity;
		private var ventLeak:Entity;
		private var taters_in_pot:Boolean = true;
		private var chefMixTimer:TimedEvent;
		
		public function MessHall()
		{
			this.mergeFiles = true;
			super();
		}
		
		override public function destroy():void
		{			
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/prison/messHall/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function eventTriggered(event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null):void
		{
			if(event == _events.MESS_VENT_OPEN_1){
				if(inVentArea()){
					SceneUtil.delay(this,1.0,Command.create(ventsLinkedResponse,event));
				}
			}
			else if(event == _events.MESS_VENT_OPEN_2){
				if(inVentArea()){
					SceneUtil.delay(this,1.0,Command.create(ventsLinkedResponse,event));
				}
			}
			else if(event == _events.MESS_VENT_OPEN_3){
				if(inVentArea()){
					SceneUtil.delay(this,1.0,Command.create(ventsLinkedResponse,event));
				}
			}
			else if(event == "use_mixer" && inVentArea()){
				useMixer();
			}
				/*			else if(event == "unlockKitchen")
				{
				if(shellApi.checkEvent(_events.TRADED_EGGS)){
				shellApi.removeEvent(_events.NEED_EGGS);
				// unblock kitchen wall
				unlockKitchen();
				}
				}*/
			else if(event == "gotItem_"+_events.MIXER)
			{
				if(!inVentArea())
				{
					shellApi.takePhotoByEvent("got_mixer_photo_" + shellApi.profileManager.active.gender,concludeFoodFight);
				}
			}
			else if(event == _events.USE_GUM)
			{
				if(!inVentArea()){
					useGum();
				}else{
					player.get(Dialog).sayById("cant_use_generic");
				}
			}
			else if(event == "use_plaster_cup")
			{
				if(!inVentArea()){
					usePlaster();
				}else{
					player.get(Dialog).sayById("cant_use_generic");
				}
			}
			else if(event == "second_spoon")
			{
				getSecondSpoon();
			}
			else if(event == "done_for_day"){
				checkSpoon();
			}
			else{
				super.eventTriggered(event,makeCurrent,init,removeEvent);
			}
		}
		
		private function useMixer():void
		{
			if(!shellApi.checkEvent(_events.DRILLED_PLATE)){
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				
				actions.addAction(new MoveAction(player,escapePipe, new Point(50,50)));
				actions.addAction(new WaitAction(0.05));
				actions.addAction(new SetSpatialAction(player,new Point(2539,224)));
				actions.addAction(new SetDirectionAction(player,true));
				
				actions.execute(openEscapeGrate);
			}
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			setupVents();
			
			setupFans();
			
			setupVentButtons();
			
			setupCharacters();		
			
			setupClickAreas();
			
			setupKitchen();
			
			setupMessIntro();
			
			setupFoodFight();
			
			setupEscapePipe();
		}
		
		private function setupCharacters():void
		{
			if(!inVentArea()){
				ratchet = getEntityById("ratchet");
				nightingale = getEntityById("nightingale");
				patches = getEntityById("patches");
				marion = getEntityById("marion");
				florian = getEntityById("florian");
				flambe = getEntityById("flambe");
				les = getEntityById("les");
				sal = getEntityById("sal");
				
				Dialog(patches.get(Dialog)).start.addOnce(Command.create(stopEating,patches,false));
				Dialog(marion.get(Dialog)).start.addOnce(Command.create(stopEating,marion,true));
				Dialog(les.get(Dialog)).start.addOnce(Command.create(stopEating,les,false));
				Dialog(sal.get(Dialog)).start.addOnce(Command.create(stopEating,sal,true));
				Dialog(florian.get(Dialog)).start.addOnce(Command.create(stopEating,florian,false));
			}else{
				removeEntity(getEntityById("ratchet"));
				removeEntity(getEntityById("nightingale"));
				removeEntity(getEntityById("patches"));
				removeEntity(getEntityById("marion"));
				removeEntity(getEntityById("florian"));
				removeEntity(getEntityById("flambe"));
				les = getEntityById("les");
				sal = getEntityById("sal");
				EntityUtils.position(les, -300,0);
				EntityUtils.position(sal, -400,0);
			}
		}
		
		private function stopEating(dd:DialogData, char:Entity, faceRight:Boolean = true):void
		{			
			// pause eat anim until talking ends
			if(!foodFightGroup.foodFightRunning()){
				var dailog:Dialog = char.get(Dialog);
				dailog.complete.addOnce(Command.create(resumeEating,char,faceRight));
				var timeline:Timeline = char.get(Timeline);
				timeline.gotoAndStop("eat");
			}
		}	
		
		private function resumeEating(dd:DialogData, char:Entity, faceRight:Boolean = true):void
		{
			if(!foodFightGroup.foodFightRunning()){
				var dailog:Dialog = char.get(Dialog);
				CharUtils.setDirection(char, faceRight);
				dailog.start.addOnce(Command.create(stopEating,char, faceRight));
				var timeline:Timeline = char.get(Timeline);
				timeline.gotoAndPlay("eat");
			}
		}
		
		private function setupClickAreas():void
		{
			var sceneInter:SceneInteraction;
			seatClick1 = getEntityById("seatInteraction1");
			sceneInter = seatClick1.get(SceneInteraction);
			sceneInter.validCharStates = new <String>[CharacterState.STAND];
			sceneInter.minTargetDelta = new Point(20,100);
			sceneInter.offsetX = 0;
			sceneInter.offsetY = 0;
			sceneInter.reached.add(sitAtTable);
			// sit with patches
			seatClick2 = getEntityById("seatInteraction2");
			// get rejected by florian
			sceneInter = seatClick2.get(SceneInteraction);
			sceneInter.validCharStates = new <String>[CharacterState.STAND];
			sceneInter.minTargetDelta = new Point(20,100);
			sceneInter.offsetX = 0;
			sceneInter.offsetY = 0;
			sceneInter.reached.add(rejectSitAtTable);
		}
		
		private function rejectSitAtTable(...p):void
		{
			CharUtils.setDirection(player,true);
			florian.get(Dialog).sayById("reject");
		}
		
		private function sitAtTable(...p):void
		{
			// sit at table, run intro from there
			if(shellApi.checkHasItem(_events.CAFE_SPOON) || shellApi.checkHasItem(_events.SPOON)){
				var target:Point;
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				target = EntityUtils.getPosition(patches);
				target.x -= 132;
				actions.addAction(new MoveAction(player,target));
				actions.addAction(new SetDirectionAction(player, true));
				actions.addAction(new CallFunctionAction(EntityUtils.position,player,target.x,986));
				actions.addAction(new CallFunctionAction(lock));
				actions.addAction(new AnimationAction(player,Sit)).noWait = true;
				actions.addAction(new WaitAction(0.4));
				actions.addAction(new SetSkinAction(player, SkinUtils.ITEM,"pr_spoon"));
				actions.addAction(new AnimationAction(player,Eat));
				actions.addAction(new CallFunctionAction(EntityUtils.position,player,target.x,1100));
				actions.addAction(new TalkAction(player, "yuck"));
				actions.addAction(new WaitAction(0.2));
				actions.addAction(new SetSkinAction(player, SkinUtils.ITEM,"empty"));
				if(!shellApi.checkEvent(_events.MESS_DAY_1_COMPLETE)){
					actions.addAction(new PanAction(sal, 0.05));
					actions.addAction(new TalkAction(les, "walls"));
					actions.addAction(new TalkAction(sal, "crumbling"));
					actions.addAction(new SetDirectionAction(les, false));
					actions.addAction(new PanAction(patches, 0.05));
					actions.addAction(new WaitAction(0.4));
					actions.addAction(new TalkAction(patches, "metal"));
					actions.addAction(new PanAction(player));
					actions.addAction(new TriggerEventAction(_events.MESS_DAY_1_COMPLETE, true));
				}
				else{
					actions.addAction(new WaitAction(0.3));	
				}
				actions.addAction(new CallFunctionAction(unlock));
				actions.execute();
			}else{
				Dialog(player.get(Dialog)).sayById("spoon");
			}
		}
		
		private function setupMessIntro():void
		{
			if(shellApi.checkEvent(_events.SPOON_DISTRACTION)){
				shellApi.removeEvent(_events.SPOON_DISTRACTION);
			}
			var target:Point;
			if(!inVentArea()){	
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				// give spoon
				target = EntityUtils.getPosition(ratchet);
				target.x += 110;
				actions.addAction(new MoveAction(player,target));
				actions.addAction(new TalkAction(ratchet, "spoon"));
				actions.addAction(new CallFunctionAction(getSpoon));
				actions.execute();
			}
		}
		
		private function unDistractGuards(...p):void
		{
			SceneUtil.lockInput(this, true);
			SceneUtil.setCameraTarget(this, ratchet);
			shellApi.removeEvent(_events.SPOON_DISTRACTION);
			Dialog(ratchet.get(Dialog)).sayById("return");
			Dialog(ratchet.get(Dialog)).complete.addOnce(returnGuards);
			SkinUtils.setEyeStates(patches,"open",null,true);
		}
		
		private function returnGuards(...p):void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player);
			CharUtils.moveToTarget(ratchet, 2353, 1075,false,faceRight);
			CharUtils.moveToTarget(nightingale, 2740, 1075,false,faceLeft);
		}
		
		private function faceLeft(ent:Entity):void
		{
			CharUtils.setDirection(ent,false);
		}
		
		private function faceRight(ent:Entity):void
		{
			CharUtils.setDirection(ent,true);
		}
		
		private function checkSpoon():void
		{
			var itemGroup:ItemGroup =ItemGroup(getGroupById(ItemGroup.GROUP_ID));
			if(shellApi.checkHasItem(_events.CAFE_SPOON)){
				// normal day, take spoon on exit
				itemGroup.takeItem(_events.CAFE_SPOON,"nightingale","",null, Command.create(this.openSchedule,this));
				shellApi.removeItem(_events.CAFE_SPOON);
			}
			else{
				// there is no spoon!
				SceneUtil.delay(this, 0.4, Command.create(this.openSchedule,this));
			}
		}
		
		private function getSpoon():void
		{		
			if(!shellApi.checkHasItem(_events.CAFE_SPOON)){
				shellApi.getItem(_events.CAFE_SPOON,null,true);
			}else{
				shellApi.showItem(_events.CAFE_SPOON,null);
			}
		}
		
		private function getSecondSpoon():void
		{
			// show spoon like you got one, allow leaving with spoon in hand	
			shellApi.triggerEvent(_events.SMUGGLED_SPOON, true);
			if(!shellApi.checkHasItem(_events.SPOON)){
				shellApi.getItem(_events.SPOON,null,true);
			}else{
				shellApi.showItem(_events.SPOON,null);
			}
			if(shellApi.checkEvent(_events.SPOON_DISTRACTION)){
				// return guards to default locations
				SceneUtil.delay(this, 1.0,unDistractGuards);
			}		
		}
		
		private function useGum():void
		{
			if(!shellApi.checkItemEvent(_events.SPOON) && shellApi.checkEvent(_events.MESS_DAY_1_COMPLETE))
			{
				EntityUtils.removeAllWordBalloons(this);
				CharUtils.moveToTarget(player, patches.get(Spatial).x-100, patches.get(Spatial).y, false, spoonDistraction, new Point(40,100)).ignorePlatformTarget = true;
			}
			else
			{
				Dialog(player.get(Dialog)).sayById("cant_use_gum");
			}
		}
		
		private function spoonDistraction(...p):void
		{					
			var targ:Point;
			// pay the iron price for patches' help
			var gumPrice:int = 3;	
			var action:ActionChain = new ActionChain(this);
			action.lockInput = true;
			action.addAction(new SetDirectionAction(player, true));
			action.addAction(new TalkAction(patches,"help2"));
			if(this.getGumCount() >= gumPrice){
				// patches fakes illness, guard runs over, other guard takes place, grab your second spoon
				action.addAction(new TalkAction(player,"gum"));
				action.addAction(new CallFunctionAction(this.removePlayerGum,gumPrice,"patches"));
				action.addAction(new TalkAction(patches,"help"));
				action.addAction(new TalkAction(patches,"fake"));
				action.addAction(new AnimationAction(patches, Grief));
				action.addAction(new CallFunctionAction(CharUtils.setAnim,patches, Sit, false,0,0,true,false));
				action.addAction(new PanAction(ratchet));
				action.addAction(new WaitAction(0.5));
				action.addAction(new TalkAction(ratchet,"take_over"));
				action.addAction(new WaitAction(0.5));
				action.addAction(new MoveAction(nightingale, ratchet));
				targ = EntityUtils.getPosition(patches);
				targ.x -= 100;
				action.addAction(new MoveAction(ratchet, targ));
				action.addAction(new SetDirectionAction(ratchet, true));
				action.addAction(new TalkAction(ratchet,"what"));
				action.addAction(new AnimationAction(patches, Grief));
				action.addAction(new PanAction(player));
				action.addAction(new TriggerEventAction(_events.SPOON_DISTRACTION, true));
				action.addAction(new CallFunctionAction(patchesMakesAScene));
			}else{
				action.addAction(new TalkAction(player,"more_gum"));
			}
			action.execute();
		}
		
		private function patchesMakesAScene(...p):void
		{	
			if(shellApi.checkEvent(_events.SPOON_DISTRACTION)){
				var action:ActionChain = new ActionChain(this);
				action.lockInput = true;
				
				action.addAction(new TalkAction(patches,"fake2"));
				action.addAction(new WaitAction(1.0));
				action.addAction(new AnimationAction(patches, Grief));
				action.addAction(new WaitAction(3.0));
				action.addAction(new AnimationAction(patches, Cry));
				action.addAction(new WaitAction(2.0));
				action.addAction(new CallFunctionAction(SceneUtil.delay, this, 8.0, patchesMakesAScene));
				
				action.execute();
				
				CharUtils.setAnim(patches, Sit, false,0,0,true,false);
			}
		}
		
		private function setupFans():void
		{
			for(var index:int = 1; index < 6; ++index)
			{
				var clip:MovieClip = this._hitContainer.getChildByName("fan" + index) as MovieClip;
				var name:String = clip.name;
				
				clip = clip.getChildByName("fan_blades") as MovieClip;
				
				var entity:Entity = EntityUtils.createMovingEntity(this, clip);
				entity.add(new Id(name));
				entity.add(new game.components.entity.Sleep(false,true));
				
				var motion:Motion = entity.get(Motion);
				motion.rotationFriction = 50;
				motion.rotationMaxVelocity = 400;
			}
		}
		
		private function setupKitchen():void
		{
			kitchenZone = this.getEntityById("kitchenZone");
			if(shellApi.checkEvent(_events.TRADED_EGGS))
			{
				unlockKitchen();
			}
			else
			{
				var zone:Zone = kitchenZone.get(Zone);
				zone.entered.add(onKitchenZoneEntered);
			}
			
			// stir ptotatos
			potatoPot = EntityUtils.createMovingTimelineEntity(this, _hitContainer["pot"]);
			var inter:Interaction = InteractionCreator.addToEntity(potatoPot, [InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.reached.add(stirPotatos);
			sceneInter.minTargetDelta = new Point(50,80);
			sceneInter.offsetY = 20;
			potatoPot.add(sceneInter);
			ToolTipCreator.addToEntity(potatoPot);
			
			// block o' potato
			potatoBlock = EntityUtils.createSpatialEntity(this, _hitContainer["potatoBlock"]);
			if(shellApi.checkEvent(_events.RUINED_POTATOS) && !shellApi.checkItemEvent(_events.DUMMY_HEAD)){
				enablePotatoBlock();
			}else{
				Display(potatoBlock.get(Display)).visible = false;
			}
			
			// pasta
			pasta = EntityUtils.createSpatialEntity(this, _hitContainer["pasta"]);
			inter = InteractionCreator.addToEntity(pasta, [InteractionCreator.CLICK]);
			sceneInter = new SceneInteraction();
			sceneInter.minTargetDelta = new Point(50,100);
			sceneInter.offsetY = 60;
			sceneInter.reached.add(getPasta);
			pasta.add(sceneInter);
			ToolTipCreator.addToEntity(pasta);
		}
		
		private function unlockKitchen(...p):void
		{
			//The eggs have been collected and given to Flambe for kitchen access.
			shellApi.removeEvent(_events.NEED_EGGS);
			this.removeEntity(kitchenZone);
			var valid:ValidHit = player.get(ValidHit);
			if(valid){
				valid.setHitValidState("kitchenBlocker", true);
				valid.inverse = true;
			}else{
				valid = new ValidHit();
				valid.setHitValidState("kitchenBlocker", true);
				valid.inverse = true;
				player.add(valid);
			}
			// flambe running around and making omelette, until you get the mixer in the food fight
			if(!shellApi.checkHasItem(_events.MIXER) && flambe){
				setFlambeActivity(true);
			}else{
				setFlambeActivity(false);
			}
		}
		
		private function setFlambeActivity(mixing:Boolean = false):void{
			if(mixing){
				// flambe running around and making omelette, until you get the mixer in the food fight
				flambeRunMixer();
			}else{
				// kill animations and go back to stand
				stopMixer();
			}
		}	
		
		private function flambeRunMixer(...p):void
		{
			EntityUtils.position(flambe, 800, 1035);
			CharUtils.setDirection(flambe, true);
			Dialog(flambe.get(Dialog)).faceSpeaker = false;
			CharUtils.setAnim(flambe, PlacePitcher, false, 0, 0, true, false);
			Timeline(flambe.get(Timeline)).handleLabel("trigger2", runMixer);
		}
		
		private function runMixer(...p):void
		{
			Timeline(flambe.get(Timeline)).gotoAndStop("trigger2");
			AudioUtils.playSoundFromEntity(flambe, SoundManager.EFFECTS_PATH+"blender_01_L.mp3", 500, 0.01, 0.5, Linear.easeIn, true);
			chefMixTimer = SceneUtil.delay(this, 3.0, Command.create(stopMixer,true));
		}
		
		private function stopMixer(loop:Boolean = false):void
		{
			if(flambe){
				var audio:Audio = flambe.get(Audio);
				if(audio){
					audio.stop(SoundManager.EFFECTS_PATH+"blender_01_L.mp3");
				}
				CharUtils.setAnim(flambe, Stand, false, 0, 0, true, true);
			}
			if(chefMixTimer){
				chefMixTimer.signal.removeAll();
				chefMixTimer.stop();
			}
			if(loop){
				chefMixTimer = SceneUtil.delay(this, 3.0, flambeRunMixer);
			}
		}
		
		
		
		private function getPasta(...p):void
		{
			if(!shellApi.checkItemEvent(_events.UNCOOKED_PASTA) && !shellApi.checkItemEvent(_events.PAINTED_PASTA)){
				shellApi.getItem(_events.UNCOOKED_PASTA,null,true);
			}else{
				Dialog(player.get(Dialog)).sayById("pasta");
			}
		}
		
		private function openPotatoPopup(...p):void
		{
			var potatoPopup:PotatoSculptPopup = this.addChildGroup(new PotatoSculptPopup(overlayContainer)) as PotatoSculptPopup;
			potatoPopup.removed.addOnce(closedPotatoPopup);
		}
		
		private function closedPotatoPopup(popup:PotatoSculptPopup):void
		{
			//comment, getItem
			if(popup.completed){
				shellApi.getItem(_events.DUMMY_HEAD,null,true);
				removeEntity(potatoBlock);
				Dialog(player.get(Dialog)).sayById("cant_use_dummy_head");
			}else{
				
			}
		}
		
		
		private function usePlaster():void
		{
			// use plaster on potato mix
			if(!shellApi.checkEvent(_events.RUINED_POTATOS)){
				if(GeomUtils.distPoint(EntityUtils.getPosition(player),EntityUtils.getPosition(potatoPot)) < 1000){
					var actions:ActionChain =  new ActionChain(this);
					actions.lockInput = true;
					actions.lockPosition = true;
					actions.addAction(new MoveAction(player, potatoPot));
					actions.addAction(new CallFunctionAction(EntityUtils.position,player,240,potatoPot.get(Spatial).y));
					actions.addAction(new SetDirectionAction(player, true));
					actions.addAction(new WaitAction(0.4));
					actions.addAction(new RemoveItemAction(_events.CUP_OF_PLASTER, "pot"));
					actions.addAction(new AnimationAction(player, Score, "", 0, false));
					actions.addAction(new TriggerEventAction(_events.USED_PLASTER,true));
					actions.addAction(new WaitAction(0.2));
					actions.addAction(new GetItemAction(_events.METAL_CUP,false));
					actions.execute();
				}
				else{
					player.get(Dialog).sayById("cant_use_plaster_cup");
				}
			}else{
				player.get(Dialog).sayById("blockPlaster");
			}
		}
		
		private function stirPotatos(...p):void
		{
			// TODO animate player, move potato spoon, update potatos poking out of pot from whole potatos to smooth creamy or dry blocks
			if(!stired_potatos){
				stired_potatos = true;
			}
			if(!sucked_up_potatos && taters_in_pot){
				if(!shellApi.checkHasItem(_events.MIXER)){
					var actions:ActionChain =  new ActionChain(this);
					actions.lockInput = true;
					actions.lockPosition = true;
					actions.addAction(new MoveAction(player, new Point(240,potatoPot.get(Spatial).y+20),new Point(50,100)));
					actions.addAction(new CallFunctionAction(EntityUtils.position,player,240,potatoPot.get(Spatial).y+20));
					actions.addAction(new SetDirectionAction(player, true));
					actions.addAction(new WaitAction(0.6));
					actions.addAction(new AnimationAction(player, Salute, "stop", 0, false));
					actions.addAction(new AudioAction(ventIntake, SoundManager.EFFECTS_PATH+"stir_mashed_potatoes_01.mp3",1,1,1));
					actions.addAction(new TimelineAction(potatoPot, "stir", "stirEnd"));
					actions.addAction(new WaitAction(0.15));
					actions.addAction(new StopAudioAction(ventIntake, SoundManager.EFFECTS_PATH+"stir_mashed_potatoes_01.mp3"));
					actions.addAction(new AnimationAction(player, Salute, "stop", 0, false));
					actions.addAction(new AudioAction(ventIntake, SoundManager.EFFECTS_PATH+"stir_mashed_potatoes_01.mp3",1,1,1));
					actions.addAction(new TimelineAction(potatoPot, "stir", "stirEnd"));
					actions.addAction(new WaitAction(0.15));
					actions.addAction(new StopAudioAction(ventIntake, SoundManager.EFFECTS_PATH+"stir_mashed_potatoes_01.mp3"));
					if(shellApi.checkEvent(_events.USED_PLASTER) && !shellApi.checkEvent(_events.RUINED_POTATOS)){
						// FLAMBE ANGRY	
						actions.addAction(new AnimationAction(player, Salute, "stop", 0, false));
						actions.addAction(new AudioAction(ventIntake, SoundManager.EFFECTS_PATH+"stir_mashed_potatoes_01.mp3",1,1,1));
						actions.addAction(new TimelineAction(potatoPot, "stir", "mixedHard"));
						actions.addAction(new WaitAction(0.15));
						actions.addAction(new StopAudioAction(ventIntake, SoundManager.EFFECTS_PATH+"stir_mashed_potatoes_01.mp3"));
						actions.addAction(new TalkAction(player, "block"));
						if(chefMixTimer){
							actions.addAction(new CallFunctionAction(stopMixer, false));
						}
						actions.addAction(new MoveAction(flambe, new Point(310,1000)));
						actions.addAction(new AnimationAction(flambe, Grief, "", 0, false));
						actions.addAction(new TalkAction(flambe, "rock"));
						actions.addAction(new AnimationAction(flambe, Score, "", 0, false));
						actions.addAction(new TimelineAction(potatoPot, "empty", "empty")).noWait = true;
						actions.addAction(new MoveAction(flambe, potatoBlock));
						actions.addAction(new SetDirectionAction(player, false));
						actions.addAction(new AnimationAction(flambe, Score, "", 0, false));
						actions.addAction(new CallFunctionAction(enablePotatoBlock));
						actions.addAction(new CallFunctionAction(unlock));
						actions.addAction(new MoveAction(flambe, new Point(800, 1000)));
						if(chefMixTimer){
							actions.addAction(new CallFunctionAction(flambeRunMixer));
						}
						taters_in_pot = false;
					}
					else if(vents_on){
						actions.addAction(new AnimationAction(player, Salute, "stop", 0, false));
						actions.addAction(new AudioAction(ventIntake, SoundManager.EFFECTS_PATH+"stir_mashed_potatoes_01.mp3",1,1,1));
						actions.addAction(new TimelineAction(potatoPot, "stir", "mixedSmooth"));
						actions.addAction(new WaitAction(0.15));
						actions.addAction(new StopAudioAction(ventIntake, SoundManager.EFFECTS_PATH+"stir_mashed_potatoes_01.mp3"));
						// suck up taters, flambe rages about wasting food
						actions.addAction(new WaitAction(0.5));
						actions.addAction(new CallFunctionAction(suckUpPotatos));
						actions.autoUnlock = false;
					}
					else{
						// FLAMBE PLEASED
						actions.addAction(new AnimationAction(player, Salute, "stop", 0, false));
						actions.addAction(new AudioAction(ventIntake, SoundManager.EFFECTS_PATH+"stir_mashed_potatoes_01.mp3",1,1,1));
						actions.addAction(new TimelineAction(potatoPot, "stir", "mixedSmooth"));
						actions.addAction(new StopAudioAction(ventIntake, SoundManager.EFFECTS_PATH+"stir_mashed_potatoes_01.mp3"));
						actions.addAction(new WaitAction(0.15));
						if(chefMixTimer){
							actions.addAction(new CallFunctionAction(stopMixer, false));
						}
						actions.addAction(new MoveAction(flambe, new Point(310,1000)));
						actions.addAction(new AnimationAction(flambe, Proud, "", 0, false));
						actions.addAction(new TalkAction(flambe, "good"));
						actions.addAction(new MoveAction(flambe, new Point(800, 1000)));
						if(chefMixTimer){
							actions.addAction(new CallFunctionAction(flambeRunMixer));
						}
					}
					actions.execute();
				}else{
					Dialog(player.get(Dialog)).sayById("mishap");
				}
			}
			else{
				Dialog(player.get(Dialog)).sayById("no_taters");
			}
		}
		
		private function enablePotatoBlock(...p):void
		{			
			potatoBlock.get(Display).visible = true;
			var inter:Interaction = InteractionCreator.addToEntity(potatoBlock, [InteractionCreator.CLICK]);
			var sceneInter:SceneInteraction = new SceneInteraction();
			sceneInter.reached.add(openPotatoPopup);
			potatoBlock.add(sceneInter);
			ToolTipCreator.addToEntity(potatoBlock);
			shellApi.triggerEvent(_events.RUINED_POTATOS,true);
		}
		
		
		private function onKitchenZoneEntered(zoneID:String, colliderID:String):void
		{
			if(colliderID == "player")
			{
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				actions.lockPosition = true;
				actions.addAction(new CallFunctionAction(player.remove,WallCollider));
				actions.addAction(new ZeroMotionAction(player));
				actions.addAction(new WaitAction(0.2));
				if(!shellApi.checkEvent(_events.MESS_DAY_1_COMPLETE)){
					actions.addAction(new TalkAction(flambe,"back_off"));
				}
				else
				{ 
					if(shellApi.checkEvent(_events.GOT_ALL_EGGS))
					{
						//actions.addAction(new TalkAction(flambe,"take_eggs"));
					}
					else if(shellApi.checkEvent(_events.NEED_EGGS))
					{
						actions.addAction(new TalkAction(flambe,"take_eggs"));
					}
					else
					{
						actions.addAction(new TalkAction(flambe,"back_off2"));
					}
				}
				actions.addAction(new MoveAction(player, new Point(1141, 1034),new Point(100,150), 800));
				actions.addAction(new SetSpatialAction(player, new Point(1141, 1034)));
				if(shellApi.checkEvent(_events.MESS_DAY_1_COMPLETE))
				{
					if(!shellApi.checkEvent(_events.NEED_EGGS)){
						actions.addAction(new TalkAction(player,"job"));
						actions.addAction(new TalkAction(flambe,"two_ways"));
						actions.addAction(new TalkAction(flambe,"omelette"));
						actions.addAction(new TalkAction(player,"eggs"));
					}
					else if(shellApi.checkEvent(_events.GOT_ALL_EGGS)){
						actions.addAction(new TalkAction(player,"give_eggs"));
						actions.addAction(new TalkAction(flambe,"take_eggs2"));
						actions.addAction(new RemoveItemAction(_events.EGGS,"flambe"));
						actions.addAction(new TalkAction(flambe,"start_work"));
						actions.addAction(new TalkAction(flambe,"mixer"));
						actions.addAction(new MoveAction(flambe, new Point(800, 1035)));
						actions.addAction(new CallFunctionAction(unlockKitchen));
					}
				}
				actions.addAction(new CallFunctionAction(player.add,new WallCollider()));
				actions.execute();
			}
		}
		
		private function setupVentButtons():void
		{
			var clip:MovieClip = this._hitContainer["ventButton"];
			ventButton = EntityUtils.createSpatialEntity(this, clip);
			ventButton.add(new Id(clip.name));
			TimelineUtils.convertClip(clip, this, ventButton, null, false);
			var interaction:Interaction = InteractionCreator.addToEntity(ventButton, [InteractionCreator.CLICK]);
			//interaction.click.add(this.ventButtonClicked);
			var sceneinter:SceneInteraction = new SceneInteraction();
			sceneinter.minTargetDelta = new Point(50,200);
			sceneinter.validCharStates = new <String>[CharacterState.STAND];
			sceneinter.offsetY = 60;
			sceneinter.reached.add(ventButtonClicked);
			ventButton.add(sceneinter);
			ToolTipCreator.addToEntity(ventButton);
			vents_on = false;
			Timeline(ventButton.get(Timeline)).gotoAndPlay("off");
		}
		
		
		private function ventButtonClicked(...p):void
		{
			CharUtils.setAnim(player, Score);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"switch_04.mp3",1.2);
			var fan:Entity;
			for(var index:int = 1; index < 6; ++index)
			{
				fan = this.getEntityById("fan" + index);
				if(vents_on){
					// off
					Timeline(ventButton.get(Timeline)).gotoAndPlay("off");
					fan.get(Motion).rotationAcceleration = 0;
				}else{
					// on
					Timeline(ventButton.get(Timeline)).gotoAndPlay("on");
					fan.get(Motion).rotationAcceleration = 200;
				}	
			}
			if(vents_on){
				vents_on = false;
				// SOUND
				Audio(ventIntake.get(Audio)).stop(SoundManager.EFFECTS_PATH+"vent_fan_01_loop.mp3");
			}else{
				vents_on = true;
				// SOUND
				AudioUtils.playSoundFromEntity(ventIntake, SoundManager.EFFECTS_PATH+"vent_fan_01_loop.mp3",500,0,1.0,null,true);
			}
		}
		
		private function inVentArea():Boolean
		{
			var result:Boolean = false;
			if(550 > EntityUtils.getPosition(player).y){
				result = true;
				shellApi.triggerEvent("in_the_roof");
			}
			else{
				result = false;
				shellApi.triggerEvent("in_the_hall");
			}
			return result;
		}
		
		private function setupVents():void
		{		
			inVentArea();
			// init each vent's available connections
			var flapLinkMap:Array = [
				["flap13", "flap11", null, "flap12"],//flap0
				["flap11", null, "flap2", "flap5"],//flap1
				["flap1",null,"flap3","flap6"],//flap2
				["flap2",null,"flap4","flap7"],//flap3
				["flap3",null,"flap10","flap8"],//flap4
				["flap12","flap1","flap6",null],//flap5
				["flap5","flap2","flap7","end"],//flap6
				["flap6","flap3","flap8","end"],//flap7
				["flap7","flap4","flap9","end"],//flap8
				["flap8","flap10",null,null],//flap9
				["flap4",null,null,"flap9"],//flap10
				[null,null,"flap1","flap0"],//flap11
				[null,"flap0","flap5",null],//flap12
				[null,null,"flap0","start"]//flap13
			];
			ventGroup = VentPuzzleGroup(this.addChildGroup(new VentPuzzleGroup(_hitContainer, flapLinkMap,"flap13",
				[new VentEnding("flap6",_events.MESS_VENT_OPEN_1),new VentEnding("flap7",_events.MESS_VENT_OPEN_2),new VentEnding("flap8",_events.MESS_VENT_OPEN_3)],
				_events.VENTS_FIELD_MESS, new RectangleZone(176,98,2430,447))));
			ventGroup.ventsReady.addOnce(ventsLoaded);
		}
		
		private function ventsLoaded():void
		{
			var outVent:Smoke;
			var targetEmitter:Entity;
			if(shellApi.checkEvent(_events.MESS_VENT_OPEN_1)){
				targetEmitter = vent1;
			}
			else if(shellApi.checkEvent(_events.MESS_VENT_OPEN_2)){
				targetEmitter = vent2;
			}
			else if(shellApi.checkEvent(_events.MESS_VENT_OPEN_3)){
				targetEmitter = vent3;
			}		
			if(targetEmitter){
				if(ventLeak){
					Emitter(ventLeak.get(Emitter)).stop = true;
					removeEntity(ventLeak);
				}
				outVent = new Smoke();
				outVent.init(7, 1, 0xffffff);		
				outVent.addInitializer( new Velocity( new LineZone( new Point( -30, 130), new Point( 30, 150 ) ) ) );
				ventLeak = EmitterCreator.create(this, hitContainer, outVent, 0,0, targetEmitter, "v", targetEmitter.get(Spatial));
				ventLeak.get(Display).moveToBack();
			}
		}
		
		private function ventsLinkedResponse(ventId:String):void
		{
			var targetEmitter:Entity;
			if(ventId == _events.MESS_VENT_OPEN_1){
				Dialog(player.get(Dialog)).sayById("vents1");
				targetEmitter = vent1;
			}
			else if(ventId == _events.MESS_VENT_OPEN_2){
				Dialog(player.get(Dialog)).sayById("vents2");
				targetEmitter = vent2;
			}
			else if(ventId == _events.MESS_VENT_OPEN_3){
				Dialog(player.get(Dialog)).sayById("vents3");
				targetEmitter = vent3;
			}
			if(targetEmitter != null){
				if(ventLeak){
					Emitter(ventLeak.get(Emitter)).stop = true;
					removeEntity(ventLeak);
				}
				var outVent:Smoke = new Smoke();
				outVent.init(7, 1, 0xffffff);
				outVent.addInitializer( new Velocity( new LineZone( new Point( -30, 130), new Point( 30, 150 ) ) ) );
				ventLeak = EmitterCreator.create(this, hitContainer, outVent, 0,0, targetEmitter, "v", targetEmitter.get(Spatial));
				ventLeak.get(Display).moveToBack();
			}
		}
		
		private function setupFoodFight():void
		{
			// potato blobs flying from eating area off screen, lock camera on kitchen area, flambe drops mixer somewhere, dodge flying stuff to get to mixer
			foodFightGroup = this.addChildGroup(new FoodFightGroup(_hitContainer,2400,760,1080,["foodfightwall"])) as FoodFightGroup;
			
			// temporary wall
			foodFightWall = getEntityById("foodfightwall");
			foodFightWall.remove(Wall);
			
			ventIntake = EntityUtils.createSpatialEntity(this, _hitContainer["ventIntake"]);
			outVents = EntityUtils.createSpatialEntity(this, _hitContainer["outVents"]);
			vent1 = EntityUtils.createMovingTimelineEntity(this, _hitContainer["vent1"]);
			vent2 = EntityUtils.createMovingTimelineEntity(this, _hitContainer["vent2"]);
			vent3 = EntityUtils.createMovingTimelineEntity(this, _hitContainer["vent3"]);
			vacumePotato = EntityUtils.createMovingTimelineEntity(this, _hitContainer["vacumePotato"]);
			Display(vacumePotato.get(Display)).visible = false;
		}
		
		// trigger food fight
		private function suckUpPotatos(...p):void
		{
			Dialog(florian.get(Dialog)).faceSpeaker = false;
			Dialog(ratchet.get(Dialog)).faceSpeaker = false;
			Dialog(flambe.get(Dialog)).faceSpeaker = true;
			
			if(!sucked_up_potatos){
				sucked_up_potatos = true;
				taters_in_pot = false;
				// suck non-hardened potatos into vents, pan over to exit vent, drop food on target table
				// start flying potatos, flambe drops mixer somewhere, dodge flying stuff to get to mixer
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				actions.lockPosition = true;
				
				actions.addAction(new CallFunctionAction(lock));
				if(chefMixTimer){
					actions.addAction(new CallFunctionAction(stopMixer, false));
				}
				actions.addAction(new PanAction(ventIntake));
				actions.addAction(new CallFunctionAction(showVac));
				actions.addAction(new AudioAction(ventIntake, SoundManager.EFFECTS_PATH+"chute_01.mp3",1,1.2,1.2));
				actions.addAction(new TimelineAction(vacumePotato,"suck","end"));
				if(shellApi.checkEvent(_events.MESS_VENT_OPEN_1)){
					actions.addAction(new PanAction(vent1,0.05));
					actions.addAction(new AudioAction(vent1, SoundManager.EFFECTS_PATH+"chute_03.mp3",1,1.2,1.2));
					actions.addAction(new TimelineAction(vent1,"suck","end"));
					actions.addAction(new AudioAction(vent1, SoundManager.EFFECTS_PATH+"splat_01.mp3",1,1.2,1.2));
					actions.addAction(new AnimationAction(les,Grief)).noWait = true;
					actions.addAction(new AnimationAction(sal,Grief));
					actions.addAction(new PanAction(les));
					actions.addAction(new TalkAction(les, "seconds"));
					actions.addAction(new TalkAction(sal, "seconds"));
					actions.addAction(new TimelineAction(potatoPot, "empty", "empty")).noWait = true;
					actions.addAction(new WaitAction(0.4));
					actions.addAction(new PanAction(flambe));
					actions.addAction(new MoveAction(flambe, new Point(310,1000)));
					actions.addAction(new AnimationAction(flambe, Grief, "", 0, false));
					actions.addAction(new TalkAction(flambe, "waste"));
					actions.addAction(new MoveAction(flambe, new Point(800, 1000)));
					if(chefMixTimer){
						actions.addAction(new CallFunctionAction(flambeRunMixer));
					}				
				}
				else if(shellApi.checkEvent(_events.MESS_VENT_OPEN_2)){
					actions.addAction(new PanAction(vent2,0.05));
					actions.addAction(new AudioAction(vent2, SoundManager.EFFECTS_PATH+"chute_03.mp3",1,1.2,1.2));
					actions.addAction(new TimelineAction(vent2,"suck","end"));
					actions.addAction(new AudioAction(vent2,SoundManager.EFFECTS_PATH + "splat_01.mp3", 1, 1.2,1.2));
					actions.addAction(new AnimationAction(patches,Grief)).noWait = true;
					actions.addAction(new AnimationAction(marion,Grief));
					actions.addAction(new PanAction(patches));
					actions.addAction(new TalkAction(patches, "seconds"));
					actions.addAction(new TimelineAction(potatoPot, "empty", "empty")).noWait = true;
					actions.addAction(new WaitAction(0.4));
					actions.addAction(new PanAction(flambe));
					actions.addAction(new MoveAction(flambe, new Point(310, 1000)));
					actions.addAction(new AnimationAction(flambe, Grief, "", 0, false));
					actions.addAction(new TalkAction(flambe, "waste"));
					actions.addAction(new MoveAction(flambe, new Point(800, 1000)));
					if(chefMixTimer){
						actions.addAction(new CallFunctionAction(flambeRunMixer));
					}					
				}
				else if(shellApi.checkEvent(_events.MESS_VENT_OPEN_3)){
					//START FOOD FIGHT
					var valid:ValidHit = flambe.get(ValidHit);
					if(valid){
						valid.setHitValidState("kitchenBlocker", true);
						valid.inverse = true;
					}else{
						valid = new ValidHit();
						valid.setHitValidState("kitchenBlocker", true);
						valid.inverse = true;
						flambe.add(valid);
					}
					Dialog(florian.get(Dialog)).complete.removeAll();
					Dialog(florian.get(Dialog)).start.removeAll();
					
					actions.addAction(new CallFunctionAction(lock));
					actions.addAction(new PanAction(vent3,0.05));
					actions.addAction(new AudioAction(vent3, SoundManager.EFFECTS_PATH+"chute_03.mp3",1,1.2,1.2));
					actions.addAction(new TimelineAction(vent3,"suck","end"));
					actions.addAction(new AudioAction(florian,SoundManager.EFFECTS_PATH + "splat_01.mp3", 1, 1.2, 1.2));
					actions.addAction(new PanAction(florian));
					actions.addAction(new TimelineAction(potatoPot, "empty", "empty")).noWait = true;
					actions.addAction(new CallFunctionAction(hidePotato));
					if(SkinUtils.getLookAspect(florian,SkinUtils.GENDER).value=="male"){
						actions.addAction(new SetSkinAction(florian,SkinUtils.HAIR,"pr_florian_potato"));
					}else{
						actions.addAction(new SetSkinAction(florian,SkinUtils.HAIR,"pr_florianf_potato"));
					}
					actions.addAction(new AnimationAction(florian,Grief));
					actions.addAction(new AnimationAction(florian,Stand)).noWait = true;
					actions.addAction(new TalkAction(florian, "dead"));
					actions.addAction(new SetDirectionAction(ratchet,false));
					actions.addAction(new TalkAction(ratchet, "sit"));
					actions.addAction(new SetDirectionAction(florian,true));
					actions.addAction(new TalkAction(florian, "make"));
					actions.addAction(new AnimationAction(florian,Attack,"trigger",0,false));
					actions.addAction(new CallFunctionAction(throwFood,florian,ratchet,true));
					actions.addAction(new AudioAction(ratchet,SoundManager.EFFECTS_PATH + "splat_01.mp3", 1, 1.2, 1.2));
					actions.addAction(new AnimationAction(ratchet,Dizzy,"",80));
					actions.addAction(new PanAction(sal,0.1));
					actions.addAction(new AnimationAction(les,Stand)).noWait = true;
					actions.addAction(new AnimationAction(sal,Stand)).noWait = true;
					actions.addAction(new TalkAction(les, "foodfight")).noWait = true;
					actions.addAction(new TalkAction(sal, "foodfight"));
					actions.addAction(new CallFunctionAction(startFoodFight));
					actions.addAction(new PanAction(player));
					actions.addAction(new MoveAction(flambe,new Point(505,1075),new Point(60,120)));
					actions.addAction(new TalkAction(flambe, "sweat"));
					actions.addAction(new AnimationAction(player, Grief));
					actions.addAction(new TalkAction(flambe, "literally"));
					actions.addAction(new TalkAction(flambe, "stop"));
					actions.addAction(new CallFunctionAction(raiseHand,flambe));
					actions.addAction(new MoveAction(flambe,new Point(1345,1075),new Point(60,120)));
					actions.addAction(new AudioAction(flambe,SoundManager.EFFECTS_PATH + "splat_01.mp3", 700, 0.9,1.2));
					actions.addAction(new WaitAction(0.2));
					actions.addAction(new AudioAction(flambe,SoundManager.EFFECTS_PATH + "squish_01.mp3", 700, 0.9,1.2));
					actions.addAction(new WaitAction(0.2));
					actions.addAction(new AudioAction(flambe,SoundManager.EFFECTS_PATH + "squish_02.mp3", 700, 0.9,1.2));
					actions.addAction(new WaitAction(0.4));
					actions.addAction(new CallFunctionAction(crippleChar,flambe));
					actions.addAction(new MoveAction(flambe,new Point(505,1075),new Point(60,120)));
					actions.addAction(new TalkAction(flambe, "save"));
					actions.addAction(new RemoveComponentAction(flambe, HazardCollider)).noWait =true;
					actions.addAction(new AnimationAction(flambe, game.data.animation.entity.character.Sleep,"",0,false)).noWait = true;
					actions.addAction(new WaitAction(0.4));
					actions.addAction(new PanAction(getEntityById("mixer")));
					actions.addAction(new WaitAction(0.6));
					actions.addAction(new TriggerEventAction(_events.STARTED_FOOD_FIGHT, true));
					//actions.addAction(new CallFunctionAction(startFoodFight,true));
				}
				actions.addAction(new PanAction(player));
				actions.addAction(new CallFunctionAction(unlock));
				
				
				actions.execute();
			}
		}
		
		private function showVac():void
		{
			Display(vacumePotato.get(Display)).visible = true;
		}
		
		private function hidePotato():void
		{
			// TODO Auto Generated method  stub
			vent3.get(Display).visible = false;
		}
		
		private function crippleChar(char:Entity):void
		{	
			// slow down walk speed, change animation
			CharacterMotionControl(player.get(CharacterMotionControl)).maxVelocityX = 250;
			CharacterMotionControl(char.get(CharacterMotionControl)).maxVelocityX = 160;			
			var rigAnim:RigAnimation = CharUtils.getRigAnim(char, 1);
			if(rigAnim == null)
			{
				var animationSlot:Entity = AnimationSlotCreator.create(char);
				rigAnim = animationSlot.get(RigAnimation) as RigAnimation;
			}
			rigAnim.next = Stand;
			SkinUtils.emptySkinPart(flambe,SkinUtils.ITEM);
		}
		
		private function raiseHand(char:Entity):void
		{
			var rigAnim:RigAnimation = CharUtils.getRigAnim(char, 1);
			if(rigAnim == null)
			{
				var animationSlot:Entity = AnimationSlotCreator.create(char);
				rigAnim = animationSlot.get(RigAnimation) as RigAnimation;
			}
			rigAnim.next = Read;
			rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.HAND_BACK);
		}
		
		private function throwFood(thrower:Entity, target:Entity, faceRight:Boolean = true):void
		{
			foodFightGroup.throwSingleFood(thrower, target, faceRight);
		}
		
		private function startFoodFight(hazardsEnabled:Boolean = true):void
		{
			// kill seat clicks
			removeEntity(seatClick1);
			removeEntity(seatClick2);
			// make wall hazard to keep player in area
			var hit:Hazard = new Hazard();
			hit.velocity = new Point(700,-250);
			hit.coolDown = 0.1;
			hit.interval = 0.05;
			hit.velocityByHitAngle = true;
			hit.slipThrough =false;
			hit.boundingBoxOverlapHitTest = true;
			foodFightWall.add(hit);
			foodFightWall.add(new Wall());
			// add mixer item to scene
			foodFightGroup.startFoodFight(hazardsEnabled);
			EntityUtils.position(florian, 2450, 1020); 
			removeEntity(les);
			removeEntity(sal);
			removeEntity(patches);
			EntityUtils.position(marion,1340,1012);
			CharUtils.setAnim(marion,DuckDown);
		}		
		
		private function concludeFoodFight(...p):void
		{			
			if(foodFightGroup.foodFightRunning()){
				foodFightGroup.stopFight();
				CharacterMotionControl(player.get(CharacterMotionControl)).maxVelocityX = 800;
				// end food fight, guards take away florian
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				
				actions.addAction(new MoveAction(player, new Point(645,1055),new Point(60,100)));
				actions.addAction(new SetDirectionAction(player,false));
				actions.addAction(new AnimationAction(flambe, Stand)).noWait = true;
				actions.addAction(new TalkAction(flambe,"prize"));
				actions.addAction(new TalkAction(flambe,"child"));
				actions.addAction(new AnimationAction(florian, Dizzy)).noWait = true;
				actions.addAction(new PanAction(ratchet,0.05));
				actions.addAction(new SetDirectionAction(ratchet,false));
				actions.addAction(new SetDirectionAction(florian,true));
				actions.addAction(new AnimationAction(ratchet, Stomp));
				actions.addAction(new TalkAction(ratchet,"cage"));
				actions.addAction(new WaitAction(1.0));
				actions.addAction(new TriggerEventAction(_events.ENDED_FOOD_FIGHT,true));
				actions.addAction(new CallFunctionAction(shellApi.loadScene,CellBlock));
				
				actions.execute();
			}
		}
		
		
		private function setupEscapePipe():void
		{
			// TODO: use drill to break open pipe, les & sal arrive, talk, return to cell
			pipeBurst =  EntityUtils.createMovingTimelineEntity(this, _hitContainer["pipeBurst"]);
			explode =  EntityUtils.createMovingTimelineEntity(this, _hitContainer["explode"]);
			escapePipe =  EntityUtils.createMovingTimelineEntity(this, _hitContainer["escapePipe"]);
			escapeWall = getEntityById("escapeWall");
			escapeFloor = getEntityById("escapeFloor");
			var valid:ValidHit = new ValidHit("escapeFloor","escapeAir");
			valid.inverse = true;
			les.add(valid);
			sal.add(valid);
			
			var inter:Interaction = InteractionCreator.addToEntity(escapePipe,[InteractionCreator.CLICK]);
			var sceneInt:SceneInteraction = new SceneInteraction();
			sceneInt.offsetY = 50;
			sceneInt.offsetX = 0;
			sceneInt.minTargetDelta = new Point(50,50);
			sceneInt.validCharStates = new <String>[CharacterState.STAND];
			sceneInt.autoSwitchOffsets = false;
			escapePipe.add(sceneInt);
			ToolTipCreator.addToEntity(escapePipe);
			
			if(!shellApi.checkEvent(_events.DRILLED_PLATE)){
				// examine plate or open it if you have all the parts
				sceneInt.reached.add(reachedPlate);
			}
			else{
				// ready for final escape sequence
				sceneInt.reached.add(startFinalEscape);
				Timeline(pipeBurst.get(Timeline)).gotoAndStop("inflated");
				Timeline(escapePipe.get(Timeline)).gotoAndStop("opened");
			}
			
		}
		
		private function reachedPlate(...p):void
		{
			//drill out plate
			//			if(shellApi.checkHasItem(_events.MIXER) && shellApi.checkHasItem(_events.DRILL_BIT)){
			//				openEscapeGrate();
			//			}
			//			else{
			Dialog(player.get(Dialog)).sayById("plate");
			//			}
		}		
		
		private function openEscapeGrate(...p):void
		{
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(player));
			escapePipe.remove(SceneInteraction);
			escapePipe.remove(Interaction);
			ToolTipCreator.removeFromEntity(escapePipe);
			Dialog(les.get(Dialog)).complete.removeAll();
			Dialog(les.get(Dialog)).start.removeAll();
			Dialog(sal.get(Dialog)).complete.removeAll();
			Dialog(sal.get(Dialog)).start.removeAll();
			CharUtils.setAnim(les, Stand, false, 0,0, true);
			CharUtils.setAnim(sal, Stand, false, 0,0, true);
			// drill grate, animate, les sal enter, talk, return to cell block
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			
			actions.addAction(new SetDirectionAction(player,true))
			actions.addAction(new SetSkinAction(player, SkinUtils.ITEM, "pr_mixer_drill"));
			actions.addAction(new CallFunctionAction(correctDrillHand));
			actions.addAction(new AnimationAction(player, PointPistol));
			// SOUND
			actions.addAction(new AudioAction(player,SoundManager.EFFECTS_PATH+"air_pump_release_01.mp3",1,1,1));
			actions.addAction(new WaitAction(0.5));
			actions.addAction(new AnimationAction(player, PlacePitcher));
			// SOUND
			actions.addAction(new AudioAction(player,SoundManager.EFFECTS_PATH+"air_pump_release_01.mp3",1,1,1));
			actions.addAction(new WaitAction(0.5));
			actions.addAction(new TimelineAction(escapePipe,"open","opened",true));
			actions.addAction(new TimelineAction(pipeBurst,"start","inflated",true));
			actions.addAction(new AnimationAction(les, Stand)).noWait = true;
			actions.addAction(new AnimationAction(sal, Stand)).noWait = true;
			actions.addAction(new SetSpatialAction(les, new Point(1500,370)));
			actions.addAction(new SetSpatialAction(sal, new Point(1400,370)));
			actions.addAction(new FollowAction(sal,les, new Point(100,50)));
			actions.addAction(new WaitAction(1.0));
			actions.addAction(new PanAction(les, 0.02)).noWait = true;
			actions.addAction(new MoveAction(les, new Point(2354,370)));
			actions.addAction(new WaitAction(0.5));
			actions.addAction(new SetDirectionAction(player,false));
			actions.addAction(new TalkAction(player,"what"));
			actions.addAction(new TalkAction(les,"swing"));
			actions.addAction(new TalkAction(sal,"outside"));
			actions.addAction(new TalkAction(player,"mean"));
			actions.addAction(new TalkAction(les,"raft"));
			actions.addAction(new TalkAction(sal,"night"));
			actions.addAction(new TalkAction(player,"escape"));
			actions.addAction(new TriggerEventAction(_events.DRILLED_PLATE,true));
			actions.addAction(new CallFunctionAction(addFinalDay));
			actions.addAction(new CallFunctionAction(shellApi.loadScene,Yard));
			
			actions.execute();
		}
		
		private function correctDrillHand():void
		{
			var item:Entity = SkinUtils.getSkinPartEntity(player, SkinUtils.ITEM);
			if(item){
				Spatial(item.get(Spatial)).rotation = 90;
			}
		}
		
		private function addFinalDay():void
		{
			currentDay++;
			shellApi.setUserField(_events.DAYS_IN_PRISON_FIELD, currentDay.toString(), shellApi.island, true);
		}
		
		
		private function startFinalEscape(...p):void
		{
			Dialog(les.get(Dialog)).complete.removeAll();
			Dialog(les.get(Dialog)).start.removeAll();
			Dialog(sal.get(Dialog)).complete.removeAll();
			Dialog(sal.get(Dialog)).start.removeAll();
			CharUtils.setAnim(les, Stand, false, 0,0, true);
			CharUtils.setAnim(sal, Stand, false, 0,0, true);
			escapeWall.remove(Wall);
			escapePipe.remove(SceneInteraction);
			escapePipe.remove(Interaction);
			ToolTipCreator.removeFromEntity(escapePipe);
			
			// les sal go in first run downwards, pipe explodes, talk, player goes up to roof
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			
			actions.addAction(new SetDirectionAction(player,true))
			actions.addAction(new SetSpatialAction(les, new Point(1500,370)));
			actions.addAction(new SetSpatialAction(sal, new Point(1400,370)));
			actions.addAction(new WaitAction(0.5));
			actions.addAction(new PanAction(les, 0.02)).noWait = true;
			actions.addAction(new MoveAction(les, new Point(2350,370))).noWait = true;
			actions.addAction(new MoveAction(sal, new Point(2250,370), new Point(80, 100)));
			actions.addAction(new WaitAction(0.5));
			actions.addAction(new SetDirectionAction(player,false));
			actions.addAction(new TalkAction(les,"bust"));
			actions.addAction(new TalkAction(sal,"first"));
			actions.addAction(new TalkAction(player,"okay"));
			actions.addAction(new PanAction(player));
			actions.addAction(new MoveAction(les, new Point(2565,220))).noWait = true;
			actions.addAction(new MoveAction(sal, new Point(2565,220), new Point(70, 100)));
			actions.addAction(new MoveAction(les, new Point(2612,220))).noWait = true;
			actions.addAction(new MoveAction(sal, new Point(2612,220), new Point(70, 100)));
			actions.addAction(new MoveAction(les, new Point(2800,380))).noWait = true;
			actions.addAction(new MoveAction(sal, new Point(2720,380), new Point(70, 100)));
			actions.addAction(new WaitAction(1.0));
			// SOUND
			// pipe burst
			actions.addAction(new TimelineAction(explode,"start","exploded")).noWait = true;
			actions.addAction(new TimelineAction(pipeBurst,"inflated","bursted"));
			actions.addAction(new WaitAction(1.0));
			actions.addAction(new TalkAction(player,"stuck"));
			actions.addAction(new TalkAction(sal,"toobad"));
			actions.addAction(new FollowAction(sal,les, new Point(100,50)));
			// les sal leave			
			actions.addAction(new MoveAction(les, new Point(3000,380)));
			actions.addAction(new MoveAction(player, new Point(2700,220)));
			actions.addAction(new MoveAction(player, new Point(2700,-150)));
			
			actions.addAction(new CallFunctionAction(shellApi.loadScene,Roof1));
			
			actions.execute();
		}
		
		private function lock(...p):void
		{
			SceneUtil.lockInput(this, true);
			MotionControl(player.get(MotionControl)).lockInput = true;
			CharacterMotionControl(player.get(CharacterMotionControl)).gravity = 0;
		}
		
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this, false);
			MotionControl(player.get(MotionControl)).lockInput = false;
			CharacterMotionControl(player.get(CharacterMotionControl)).gravity = 1700;
		}
		
		
		
		
		
	}
}