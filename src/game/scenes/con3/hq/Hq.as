package game.scenes.con3.hq
{	
	import com.greensock.easing.Bounce;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.group.TransportGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Sleep;
	import game.data.animation.entity.character.Soar;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Tremble;
	import game.data.character.LookAspectData;
	import game.scene.template.CharacterGroup;
	import game.scenes.con2.shared.popups.CardDeck;
	import game.scenes.con3.Con3Scene;
	import game.scenes.con3.expo.Expo;
	import game.scenes.con3.shared.Comic178Popup;
	import game.scenes.con3.shared.Comic367Popup;
	import game.scenes.con3.shared.PortalGroup;
	import game.scenes.con3.throneRoom.ThroneRoom;
	import game.scenes.custom.AdMiniBillboard;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.MultiAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.motion.ProximitySystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	public class Hq extends Con3Scene
	{
		private var omegon:Entity;
		private var hench0:Entity;
		private var hench1:Entity;
		private var leader:Entity;
		private var fan:Entity;
		private var goldFace:Entity;
		private var elfArcher:Entity;
		private var worldGuy:Entity;
		
		private var survivor1:Entity;
		
		private var _portalGroup:PortalGroup;
		//		private var portal:Entity;
		//private var pyramid:Entity;
		
		public var colorGlow:GlowFilter = new GlowFilter( 0x00FF00, 0, 40, 40, 1, 1 );
		private var oMotion:Motion;
		private var hMotion0:Motion;
		private var hMotion1:Motion;
		private var _transportGroup:TransportGroup;
		private var survivor2:Entity;
		private var dealer:Entity;
		//	private var flash:Entity;
		private var multiplayerDoor:Entity;
		
		public function Hq()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con3/hq/";
			
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
			// TEMP: FORCE PLAYER TO EXPO IF MEDAL GOT
			if(shellApi.checkHasItem(_events.MEDAL_CON3)){
				SceneUtil.addTimedEvent(this, new TimedEvent(0.1, 1, Command.create(shellApi.loadScene,Expo)));
			}
			
			super.loaded();
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(620, 135));	

			multiplayerDoor = EntityUtils.createMovingTimelineEntity(this, _hitContainer["multi"]);
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(multiplayerDoor));
			if(PlatformUtils.isDesktop){
				Timeline(multiplayerDoor.get(Timeline)).gotoAndStop("web");
			}
			else
			{
				Timeline(multiplayerDoor.get(Timeline)).gotoAndStop("mobile");
			}
			
			leader = getEntityById("leader");
			fan = getEntityById("fan");
			goldFace = getEntityById("goldFace");
			elfArcher = getEntityById("elfArcher");
			worldGuy = getEntityById("worldGuy");
			
			survivor1 = getEntityById("survivor1");
			survivor2 = getEntityById("survivor2");
			
			dealer = getEntityById("dealer");
			
			var clip:MovieClip = _hitContainer["portal"];
			if(shellApi.checkEvent(_events.WORLD_GUY_RESCUED)){
				
				_portalGroup = addChildGroup( new PortalGroup()) as PortalGroup;
				_portalGroup.createPortal( this, _hitContainer );
				//	portal = makeTimeline(clip);
				//	clip = _hitContainer["flash"];
				//	flash = EntityUtils.createSpatialEntity(this, clip);
				//	Display(flash.get(Display)).alpha = 0;
				//	Timeline(portal.get(Timeline)).handleLabel("flash0",Command.create(flashLights,0.3));
				//	Timeline(portal.get(Timeline)).handleLabel("flash1",Command.create(flashLights,0.6));
				//	Timeline(portal.get(Timeline)).handleLabel("flash2",Command.create(flashLights,0.8));
			}else{
				_hitContainer.removeChild(clip);
				//			clip = _hitContainer["flash"];
				//			_hitContainer.removeChild(clip);
			}
			
			setupSoda();
			
			if(!shellApi.checkEvent(_events.INTRO_COMPLETE))
			{
				setupIntroConv();
				SceneUtil.addTimedEvent(this, new TimedEvent(0.4,1,showIntroPopup));
				cardManager.updateDeck("",shellApi.island);
			}
			
			makeTimeline(_hitContainer["drip"]);
			makeTimeline(_hitContainer["lamp0"]);
			makeTimeline(_hitContainer["lamp1"]);
			
			//setupDealerDialog();
			
			if(!shellApi.checkHasItem(_events.BOW)){
				var look:LookAspectData = SkinUtils.getLook(player).getAspect(SkinUtils.ITEM)
				if(look && look.value == "bow") 
				{
					SkinUtils.setSkinPart(player,SkinUtils.ITEM,"empty");
				}
			}
			if(!shellApi.checkHasItem(_events.GAUNTLETS)){
				look = SkinUtils.getLook(player).getAspect(SkinUtils.ITEM)
				if(look && look.value == "poptropicon_goldface_front") 
				{
					SkinUtils.setSkinPart(player,SkinUtils.ITEM,"empty");
				}
				look = SkinUtils.getLook(player).getAspect(SkinUtils.ITEM2);
				if(look && look.value == "poptropicon_goldface_back") 
				{
					SkinUtils.setSkinPart(player,SkinUtils.ITEM,"empty");
				}
			}
			if(!shellApi.checkHasItem(_events.SHIELD)){
				look = SkinUtils.getLook(player).getAspect(SkinUtils.ITEM)
				if(look && look.value == "poptropicon_worldguy") 
				{
					SkinUtils.setSkinPart(player,SkinUtils.ITEM,"empty");
				}
			}
			if(!shellApi.checkHasItem(_events.OLD_SHIELD)){
				look = SkinUtils.getLook(player).getAspect(SkinUtils.ITEM)
				if(look && look.value == "poptropicon_saworldguy") 
				{
					SkinUtils.setSkinPart(player,SkinUtils.ITEM,"empty");
				}
			}
			
			if(shellApi.checkEvent(_events.HQ_DESTROYED)){
				omegon = getEntityById("omegon");
				hench0 = getEntityById("hench0");
				hench1 = getEntityById("hench1");
				removeEntity(omegon);
				removeEntity(hench0);
				removeEntity(hench1);
				removeEntity(leader);
				removeEntity(fan);
				removeEntity(goldFace);
				removeEntity(elfArcher);
				removeEntity(worldGuy);
				removeEntity(survivor1);
				removeEntity(survivor2);
				removeEntity(dealer);
				_hitContainer.removeChild(_hitContainer["portal"]);
				_hitContainer.removeChild(_hitContainer["pyramid"]);
			}
			else if(shellApi.checkEvent(_events.WORLD_GUY_RESCUED)){
				setupDestruction();
			}
			
			if(shellApi.checkEvent(_events.GOT_ALL_WEAPONS) && !shellApi.checkEvent(_events.HQ_DESTROYED)){
				startOmegonArrivalSequence();
			}
		}
		
		//		private function flashLights(interval:Number):void
		//		{
		//			Display(flash.get(Display)).alpha = 0;
		//			TweenUtils.entityTo(flash, Display, interval, {alpha:1, ease:Bounce.easeIn, onComplete:endFlash, onCompleteParams:[interval]});
		//		}
		//		
		//		private function endFlash(interval:Number):void
		//		{
		//			TweenUtils.entityTo(flash, Display, interval/2, {alpha:0, ease:Bounce.easeOut});
		//		}
		
		private function setupSoda():void
		{
			if(!shellApi.checkEvent(_events.GOT_SODA + "2")){
				this.addSystem(new ProximitySystem());
				var soda:Entity =  EntityUtils.createMovingEntity(this,_hitContainer["soda"]);
				var pInt:Interaction = InteractionCreator.addToEntity(soda,[InteractionCreator.CLICK]);
				soda.add(new Id("soda"));
				ToolTipCreator.addToEntity(soda);
				var sceneInt:SceneInteraction = new SceneInteraction();
				sceneInt.targetX = soda.get(Spatial).x;
				sceneInt.targetY = soda.get(Spatial).y;
				sceneInt.minTargetDelta.x = 20;
				sceneInt.minTargetDelta.y = 20;
				soda.add(sceneInt);
				var prox:Proximity = new Proximity(125,player.get(Spatial));
				prox.entered.addOnce(getSoda);
				soda.add(prox);
			}else{
				_hitContainer.removeChild(_hitContainer["soda"]);
			}
		}
		
		private function getSoda(...p):void
		{
			if(shellApi.checkHasItem(_events.SODA)){
				shellApi.showItem(_events.SODA, null);
			}else{
				shellApi.getItem(_events.SODA, null, true);
			}
			shellApi.completeEvent(_events.GOT_SODA + "2");
			shellApi.completeEvent(_events.HAS_SODA + "2");
			
			removeEntity(getEntityById("soda"));
		}
		
		private function showIntroPopup():void
		{
			var introPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			introPopup.updateText("save humankind from omegon!", "Start");
			introPopup.configData("intro-popup.swf", "scenes/con3/hq/");
			addChildGroup(introPopup);
			introPopup.removed.addOnce(introGo);
		}
		
		private function introGo(...p):void
		{
			SceneUtil.lockInput(this, true);
			runIntroConv();
		}
		
		override protected function eventTriggered( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var dialog:Dialog;
			if( event == "check_if_played" )
			{
				dialog = dealer.get( Dialog );
				if( !shellApi.checkEvent(_events.STARTER_DECK) )
				{
					dialog.sayById( "give_starter" );
				}
				else
				{
					dialog.sayById( "dealer_teach" );
				}
			}
			else if( event == "give_deck" )
			{
				dialog = dealer.get( Dialog );
				super.addCardToDeck(_events.CARD_DECK, Command.create( dialog.sayById, "dealer_teach" ) );
				shellApi.triggerEvent(_events.STARTER_DECK,true);
			}
			else if( event == "open_deck" )
			{
				var cardDeckPopup:CardDeck = new CardDeck( super.overlayContainer );
				cardDeckPopup.removed.addOnce( onForcedDeckClosed );
				super.addChildGroup( cardDeckPopup );
			}
			else if(event == "gotItem_" + _events.BOW){
				SkinUtils.setSkinPart(elfArcher, SkinUtils.ITEM, "empty");
			}
			else if(event == "gotItem_" + _events.GAUNTLETS){
				SkinUtils.setSkinPart(goldFace, SkinUtils.ITEM, "empty");
			}
			else if(event == "gotItem_" + _events.SHIELD){
				SkinUtils.setSkinPart(worldGuy, SkinUtils.ITEM, "empty");
			}
			else if(event == "hasItem_" + _events.SHIELD){
				startOmegonArrivalSequence();
			}
			else if(event == "show_" + _events.COMIC178){
				SceneUtil.addTimedEvent(this, new TimedEvent(0.2,1,showComic178));
			}
			else if(event == "show_" + _events.COMIC367){
				SceneUtil.addTimedEvent(this, new TimedEvent(0.2,1,showComic367));
			}
			
			super.eventTriggered(event, save, init, removeEvent);
		}
		
		private function onForcedDeckClosed( ...args ):void
		{
			super.returnControls();
			var dialog:Dialog = getEntityById( "dealer" ).get( Dialog );
			dialog.sayById( "deck_closed"  );
		}
		
		/**
		 * CARD SETUP
		 */
		private function setupDealerDialog():void
		{
			var dealer:Entity = super.getEntityById("dealer");
			var dialog:Dialog = dealer.get( Dialog );
			if( !shellApi.checkHasItem(_events.STARTER_DECK) )
			{        
				dialog.current = dialog.getDialog( "new_player" );
			}
			else
			{
				dialog.current = dialog.getDialog( "starter_deck" );
			}
		}
		
		private function showComic178():void
		{
			var popup:Comic178Popup = super.addChildGroup(new Comic178Popup(overlayContainer)) as Comic178Popup;
			popup.removed.addOnce(getComic178);
		}
		
		private function getComic178(...p):void
		{
			shellApi.getItem(_events.COMIC178,null,true);
		}
		
		private function showComic367():void
		{
			var popup:Comic367Popup = super.addChildGroup(new Comic367Popup(overlayContainer)) as Comic367Popup; 
			popup.removed.addOnce(getComic367);
			SceneUtil.lockInput(this,false);
		}
		
		private function getComic367(...p):void
		{
			shellApi.getItem(_events.COMIC367,null,true);
			SceneUtil.lockInput(this,true);
		}
		
		private function setupIntroConv():void
		{
			// position leader, sleep player
			EntityUtils.position(leader,940,EntityUtils.getPosition(leader).y);
			CharUtils.setDirection(leader, true);
			CharUtils.setAnim(player,Sleep);
			CharUtils.setDirection(player, false);
			SceneUtil.lockInput(this, true);
			EntityUtils.position(player, 1100, 528.388);
			
			cardManager.updateDeck("", shellApi.island);// reset deck
		}
		
		private function runIntroConv():void
		{
			CharUtils.setDirection(player,false);
			
			// talk to leader
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			actions.addAction(new AnimationAction(player, Stand, "", 30));
			actions.addAction(new TalkAction(leader, "intro"));
			actions.addAction(new TalkAction(player, "happen"));
			actions.addAction(new TalkAction(leader, "taken"));
			actions.addAction(new TalkAction(player, "night"));
			actions.addAction(new TalkAction(leader, "sadly"));
			actions.addAction(new TalkAction(leader, "bearings"));
			var p:Point = EntityUtils.getPosition(leader);
			p.x = 1350;
			actions.addAction(new MoveAction(leader,p,new Point(30,80),0,true));
			actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,leader, false)));
			actions.addAction(new WaitAction(0.8));
			actions.addAction( new CallFunctionAction(Command.create(shellApi.completeEvent,_events.INTRO_COMPLETE)));
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,actions.execute));
		}
		
		private function setupDestruction():void
		{
			omegon = getEntityById("omegon");
			hench0 = getEntityById("hench0");
			hench1 = getEntityById("hench1");
			
			addFsm(leader);
			addFsm(fan);
			addFsm(elfArcher);			
			
			ToolTipCreator.removeFromEntity(omegon);
			ToolTipCreator.removeFromEntity(hench0);
			ToolTipCreator.removeFromEntity(hench1);
			
			omegon.remove(SceneInteraction);
			omegon.remove(Interaction);
			hench0.remove(SceneInteraction);
			hench0.remove(Interaction);
			hench1.remove(SceneInteraction);
			hench1.remove(Interaction);
			
			Display(omegon.get(Display)).visible = false;
			Display(hench0.get(Display)).visible = false;
			Display(hench1.get(Display)).visible = false;			
		}		
		
		private function startOmegonArrivalSequence(...p):void
		{
			if(shellApi.checkEvent(_events.GOT_ALL_WEAPONS)){
				SceneUtil.lockInput(this, true);
				var actions:ActionChain = new ActionChain(this);
				//actions.lockInput = true;
				var targ:Point = EntityUtils.getPosition(leader);
				targ.x -= 90;
				actions.addAction(new MoveAction(player,targ,new Point(25,80),1,true));
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,true)));
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,true)));
				actions.addAction(new TalkAction(player,"weapons"));
				actions.addAction(new TalkAction(fan,"alphaon"));
				actions.addAction(new TalkAction(leader,"sure"));
				actions.addAction(new TalkAction(player,"yes"));
				actions.addAction(new TalkAction(leader,"betray"));
				actions.addAction(new PanAction( _portalGroup.portal ));
				actions.addAction(new CallFunctionAction(omegonEnters));
				
				actions.execute();
			}
		}	
		
		
		private function startDestructionSequence():void
		{	
			var leadLoc:Point = EntityUtils.getPosition(leader);
			var actions:ActionChain = new ActionChain(this);
			DisplayUtils.moveToBack(EntityUtils.getDisplayObject(multiplayerDoor));

			var minDist:Point = new Point(50,100)
			
			//actions.lockInput = true;
			
			actions.addAction(new TalkAction(omegon,"futile"));
			actions.addAction(new CallFunctionAction(fearNpcs)).noWait = true;
			actions.addAction(new PanAction(player));
			actions.addAction(new TalkAction(leader,"sorry"));
			actions.addAction(new TalkAction(player,"months"));
			actions.addAction(new TalkAction(leader,"time"));
			actions.addAction(new TalkAction(player,"offer"));
			actions.addAction(new TalkAction(leader,"power"));
			actions.addAction(new PanAction(omegon));
			actions.addAction(new TalkAction(omegon,"plant"));
			actions.addAction(new PanAction(hench0));
			actions.addAction(new MoveAction(hench0, new Point(leadLoc.x + 60, 615),minDist,0)).noWait = true;
			actions.addAction(new MoveAction(hench1, new Point(leadLoc.x - 60, 615),minDist,1));
			actions.addAction(new TalkAction(leader,"no"));
			actions.addAction(new PanAction(player));
			actions.addAction(new MoveAction(leader, new Point(200,614),minDist,0)).noWait = true;
			actions.addAction(new MoveAction(hench1, new Point(omegon.get(Spatial).x + 80,614),minDist,0)).noWait = true;
			actions.addAction(new MoveAction(hench0, new Point(omegon.get(Spatial).x - 80,614),minDist,1));
			actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,hench0,true)));
			actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,hench1,true)));
			actions.addAction(new CallFunctionAction(Command.create(removeEntity,leader)));
			actions.addAction(new PanAction(omegon));
			actions.addAction(new TalkAction(omegon,"reign"));
			actions.addAction(new CallFunctionAction(omegonExit));
			actions.addAction(new WaitAction(4.3));
			actions.addAction(new PanAction(player));
			actions.addAction(new TalkAction(goldFace,"again"));
			actions.addAction(new TalkAction(fan,"ripoff"));
			actions.addAction(new TalkAction(player,"doom"));
			actions.addAction(new TalkAction(fan,"crystal"));
			actions.addAction(new WaitAction(0.6));
			//actions.addAction(new ShowPopupAction(new Comic367Popup(overlayContainer)));
			actions.addAction(new TalkAction(player,"where"));
			actions.addAction(new TalkAction(fan,"throne"));
			actions.addAction(new TalkAction(player,"noble"));
			actions.addAction(new TalkAction(fan,"heroic"));
			actions.addAction(new MoveAction(fan, new Point(300,614)));
			actions.addAction(new AudioAction(fan,SoundManager.EFFECTS_PATH + "small_explosion_01.mp3", 700, 0.8,1.2));
			actions.addAction(new WaitAction(0.2));
			actions.addAction(new AudioAction(fan,SoundManager.EFFECTS_PATH + "small_explosion_04.mp3", 700, 0.8,1.2));
			actions.addAction(new WaitAction(0.2));
			actions.addAction(new AudioAction(fan,SoundManager.EFFECTS_PATH + "small_explosion_02.mp3", 700, 0.8,1.2));
			actions.addAction(new WaitAction(0.2));
			var targ:Point = new Point(1720,614);
			actions.addAction(new MoveAction(player, targ));
			targ = EntityUtils.getPosition(getEntityById("doorThrone"));
			targ.y -= 20;
			actions.addAction(new MoveAction(player, targ));
			actions.addAction(new CallFunctionAction(escapeHq));
			
			actions.execute();
		}
		
		private function escapeHq():void
		{
			SceneUtil.lockInput(this,true);
			shellApi.loadScene(ThroneRoom,2100,950);
		}
		
		private function omegonExit():void
		{
			var portal:Entity = _portalGroup.portal;
			omegon.remove(FSMControl);
			CharUtils.setAnim(omegon, Soar);
			TweenUtils.entityTo(omegon, Spatial,2,{y:portal.get(Spatial).y+10, onComplete:omegonOut});
		}
		
		private function omegonOut():void
		{
			_transportGroup.transportOut(omegon,false);
			//_transportGroup.transportOut(pyramid,false);
			
			shellApi.completeEvent(_events.HQ_DESTROYED);
			//		Timeline(portal.get(Timeline)).handleLabel("loopEnd",Command.create(Timeline(portal.get(Timeline)).gotoAndPlay,"end"));
		}
		
		private function omegonEnters():void
		{
			// show wormhole
			shellApi.triggerEvent("omegon_enters");
			shellApi.triggerEvent("portal_opening");
			var portal:Entity = _portalGroup.portal;
			
			oMotion = Motion(omegon.get(Motion));
			omegon.remove(Motion);
			hMotion0 = Motion(hench0.get(Motion));
			hMotion1 = Motion(hench1.get(Motion));
			hench0.remove(Motion);
			hench1.remove(Motion);
			
			SceneUtil.setCameraTarget(this, portal);
			omegon.get(Spatial).x = portal.get(Spatial).x;
			omegon.get(Spatial).y = portal.get(Spatial).y + 30;
			omegon.get(Display).alpha = 0;
			omegon.get(Display).displayObject.filters = new Array( colorGlow );
			hench0.get(Spatial).x = portal.get(Spatial).x+80;
			hench0.get(Spatial).y = portal.get(Spatial).y+15;
			hench0.get(Display).alpha = 0;
			hench1.get(Spatial).x = portal.get(Spatial).x-80;
			hench1.get(Spatial).y = portal.get(Spatial).y+15;
			hench1.get(Display).alpha = 0;
			
			SceneUtil.lockInput(this, true);
			_portalGroup.portalTransitionIn( transportOmegon, null, _events.HQ_DESTROYED );
			//			var portal:Entity = _portalGroup.portal;
			//			var tl:Timeline = Timeline(portal.get(Timeline));
			//			tl.gotoAndPlay("start");
		}
		
		//		private function portalOpen():void
		//		{
		//			var portal:Entity = _portalGroup.portal;
		//			//var pClip:MovieClip = _hitContainer["pyramid"];
		//			//pyramid = EntityUtils.createSpatialEntity(this, pClip);
		//			//var follow:FollowTarget = new FollowTarget(Spatial(omegon.get(Spatial)), .02);
		//			//follow.properties = new <String>["x","y"];
		//			//pyramid.add(follow);
		//			//pyramid.add(new SpatialOffset());
		//			//pyramid.get(SpatialOffset).x = 40;
		//			//pyramid.get(SpatialOffset).y = -50;
		//			//pyramid.add(new Tween());
		//			//pyramid.get(Display).alpha = 0;
		//			
		//			//MotionUtils.addWaveMotion(pyramid,new WaveMotionData("y",3,0.1),this);
		//			
		////			oMotion = Motion(omegon.get(Motion));
		////			omegon.remove(Motion);
		////			hMotion0 = Motion(hench0.get(Motion));
		////			hMotion1 = Motion(hench1.get(Motion));
		////			hench0.remove(Motion);
		////			hench1.remove(Motion);
		////			
		////			SceneUtil.setCameraTarget(this, portal);
		////			omegon.get(Spatial).x = portal.get(Spatial).x;
		////			omegon.get(Spatial).y = portal.get(Spatial).y + 30;
		////			omegon.get(Display).alpha = 0;
		////			hench0.get(Spatial).x = portal.get(Spatial).x+80;
		////			hench0.get(Spatial).y = portal.get(Spatial).y+15;
		////			hench0.get(Display).alpha = 0;
		////			hench1.get(Spatial).x = portal.get(Spatial).x-80;
		////			hench1.get(Spatial).y = portal.get(Spatial).y+15;
		////			hench1.get(Display).alpha = 0;
		//			//portal.get(Timeline).gotoAndPlay(1);
		//			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, transportOmegon, true));
		//			shellApi.triggerEvent("portal_opening");
		//	//		AudioUtils.play( this, SoundManager.EFFECTS_PATH + "energy_hum_02_loop.mp3" );
		//		}	
		
		private function transportOmegon():void 
		{
			var portal:Entity = _portalGroup.portal;
			
			_transportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
			_transportGroup.transportIn( omegon, false, .1 );
			//_transportGroup.transportIn( pyramid, false, .1 );
			_transportGroup.transportIn( hench0, false, 1 );
			_transportGroup.transportIn( hench1, false, 1 );
			//var follow:FollowTarget = new FollowTarget(Spatial(omegon.get(Spatial)), .05);
			//follow.properties = new <String>["x","y"];
			//follow.rate = 100;
			//pyramid.add(follow);
			Display(omegon.get(Display)).visible = true;
			//Display(pyramid.get(Display)).visible = true;
			Display(hench0.get(Display)).visible = true;
			Display(hench0.get(Display)).moveToBack();
			Display(hench1.get(Display)).visible = true;
			Display(hench0.get(Display)).moveToBack();
			Display(portal.get(Display)).moveToBack();
			Display(elfArcher.get(Display)).moveToBack();
			
			SceneUtil.addTimedEvent(this, new TimedEvent(3.6, 1, dropOmegon, true));
			// close chars run away
			var action:ActionChain = new ActionChain(this);
			var multi:MultiAction = new MultiAction();
			multi.addAction(new AnimationAction(elfArcher,Grief));
			multi.addAction(new AnimationAction(survivor2,Grief));
			multi.addAction(new AnimationAction(dealer,Grief));
			action.addAction(multi);
			multi.noWait = true;
			action.addAction(new WaitAction(1));
			multi = new MultiAction();
			multi.addAction(new MoveAction(elfArcher,new Point(1800,614)));
			multi.addAction(new MoveAction(survivor2,new Point(1900,614)));
			multi.addAction(new MoveAction(dealer,new Point(1900,614)));
			action.addAction(multi);
			action.addAction(new CallFunctionAction(fearNpcs));
			action.execute();
		}
		
		private function fearNpcs(...p):void
		{
			CharUtils.setAnim(elfArcher, Tremble);
			CharUtils.setAnim(goldFace, Tremble);
			CharUtils.setAnim(worldGuy, Tremble);
			CharUtils.setAnim(survivor1, Tremble);
			CharUtils.setAnim(survivor2, Tremble);
			CharUtils.setAnim(dealer, Tremble);
		}
		
		private function dropOmegon():void {
			SceneUtil.lockInput(this, true);
			SceneUtil.setCameraTarget(this,omegon);
			addFsm(omegon);
			addFsm(hench0);
			addFsm(hench1);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5,1,startDestructionSequence));
			//AudioUtils.stop( this, SoundManager.EFFECTS_PATH + "energy_hum_02_loop.mp3" );
		}
		
		private function makeTimeline(clip:MovieClip, play:Boolean = true, seq:BitmapSequence = null):Entity
		{
			var target:Entity;
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				target = BitmapTimelineCreator.convertToBitmapTimeline(target, clip, true, seq, PerformanceUtils.defaultBitmapQuality);
				this.addEntity(target);
				target.add(new Motion());
			}else{
				target = EntityUtils.createMovingTimelineEntity(this, clip, null, play);
			}
			return target; 
		}
		
		private function addFsm(character:Entity):void
		{
			var fsmControl:FSMControl = character.get( FSMControl );
			if( !fsmControl )
			{
				var parentGroup:Group = OwningGroup( character.get( OwningGroup ) ).group;
				fsmControl = CharacterGroup( parentGroup.getGroupById("characterGroup") ).addFSM( character );
				fsmControl = character.get( FSMControl );
			}
			fsmControl.active = true;
		}
		
		
		
		
		
		
		
		
	}
}