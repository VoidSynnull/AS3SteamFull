package game.scenes.mocktropica.mainStreet
{
	import com.greensock.easing.Quad;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterWander;
	import game.components.entity.character.Talk;
	import game.components.hit.Door;
	import game.components.hit.Platform;
	import game.components.hit.Wall;
	import game.components.motion.MotionTarget;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Stand;
	import game.data.scene.characterDialog.DialogData;
	import game.data.ui.ToolTipType;
	import game.particles.emitter.Rain;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.CollisionGroup;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scenes.mocktropica.mainStreet.bossIntro.BossIntroGroup;
	import game.scenes.mocktropica.robotBossBattle.RobotBossBattle;
	import game.scenes.mocktropica.shared.AchievementGroup;
	import game.scenes.mocktropica.shared.AdvertisementGroup;
	import game.scenes.mocktropica.shared.MocktropicanHUD;
	import game.scenes.mocktropica.shared.NarfCreator;
	import game.scenes.mocktropica.shared.components.Narf;
	import game.systems.SystemPriorities;
	import game.systems.motion.ProximitySystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.counters.Steady;
	import org.osflash.signals.Signal;
	
	public class MainStreet extends PlatformerGameScene
	{
		private var hitBMD:BitmapData;
		private var buildingOrder:Array;
		private var _events:MocktropicaEvents;
		private var _narfCreator:NarfCreator;
		private var _numPets:Number;
		private var _pets:Vector.<Entity>;
		private var _currentCurd:Entity;
		private var _boy:Entity;
		
		private var layoutEvent:String = "none";
		public var correctOrder:Vector.<String> = Vector.<String>["car","hardwareStore","popStatue","blueLocust"];
		public const MOCK_LAYOUT:String = "mock_layout";
		private var doorChasm:Entity;
		private var doorUniversity:Entity;
		private var popEntity:Entity;
		private var achievements:AchievementGroup;
		private var wall:Entity;
		private var crateTop:Entity;
		private var advertisments:AdvertisementGroup;
		private var gCampaignName:String = "Mocktropica";
		private var safetyWall:Entity;
		private var focusTester:Entity;
		private var crate:Entity;

		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/mocktropica/mainStreet/";
			
			super.init(container);
			
			//super.showHits = true;
		}
		
		protected override function addUI(container:Sprite):void
		{
			var sceneUIGroup:SceneUIGroup = new SceneUIGroup(super.overlayContainer, container);
			sceneUIGroup.hudClass = MocktropicanHUD;
			super.addChildGroup(sceneUIGroup);
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
			
			
			_events = MocktropicaEvents(events);
			super.shellApi.eventTriggered.add(handleEvents);
			positionFocusTester();
			
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb1"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);
			
			if(shellApi.checkEvent(_events.SERVER_REPAIRED) && !shellApi.checkEvent(_events.DEFEATED_BOSS) && !shellApi.checkHasItem(_events.MEDAL_MOCKTROPICA)){
				shellApi.completeEvent(_events.SET_CLEAR);
				shellApi.removeEvent(_events.SET_RAIN);
				shellApi.completeEvent(_events.SET_DAY);
				shellApi.removeEvent(_events.SET_NIGHT);
			}
			
			if(shellApi.checkEvent(_events.SET_RAIN))
			{
				var rain:Rain = new Rain();
				rain.init(new Steady(150), new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight), 2);
				EmitterCreator.createSceneWide(this, rain);
			}
			correctOrder = new Vector.<String>();
			correctOrder.push("car","hardwareStore","popStatue","blueLocust");
			setBuildingPositions();			
			setupDoors()
			_boy = super.getEntityById("boy");
			// Achievements
			achievements = new AchievementGroup( this );
			this.addChildGroup( achievements );		
			advertisments = super.addChildGroup( new AdvertisementGroup( this, _hitContainer )) as AdvertisementGroup;
			// If it should be raining turn the rain effect on

			
			// Remove items the player no longer has, this is for island resets
			if(!super.shellApi.checkHasItem(_events.CURDS))
			{
				if ( SkinUtils.getSkinPart( super.player, SkinUtils.ITEM).value == "mk_curds" )
				{
					SkinUtils.setSkinPart(super.player, SkinUtils.ITEM, "empty");
				}
			}
			if(!super.shellApi.checkHasItem(_events.HELMET))
			{
				if ( SkinUtils.getSkinPart( super.player, SkinUtils.FACIAL).value == "mk_helmet" )
				{
					SkinUtils.setSkinPart(super.player, SkinUtils.FACIAL, "empty");
				}
			}

			if(shellApi.checkEvent("bonusGoInside") || shellApi.checkEvent(_events.DEFEATED_MFB))
			{
				removeEntity(getEntityById("projectManager"));
				removeEntity(getEntityById("leadDeveloper"));
			}
			
			
			_narfCreator = new NarfCreator(this, super.getGroupById("characterGroup") as CharacterGroup, super._hitContainer);
			_numPets = 0;
			// If the boy has left the cheese factory and the player has the curds then their are a bunch of pets
			if(super.shellApi.checkEvent(_events.BOY_LEFT_CHEESE_EXTERIOR) 
				&& super.shellApi.checkHasItem(_events.CURDS) 
				&& !super.shellApi.checkEvent(_events.BOY_LEFT_MAIN_STREET_CHASM)){
				_numPets = 9;
			// else check to see if the boy should even be here
			}else if(super.shellApi.checkEvent(_events.BOY_LEFT_MAIN_STREET_CHEESE) 
				|| super.shellApi.checkEvent(_events.BOY_LEFT_MAIN_STREET_CHASM)){
				super.removeEntity(_boy);
				_boy = null;
			// else add a pet if we have spoken to the focus tester
			}else if(super.shellApi.checkEvent(_events.SPOKE_WITH_FOCUS_TESTER)){
				_numPets = 1;
			}
			loadPets();
			// collectibles
			if(shellApi.checkEvent(_events.START_COLLECTIBLES)){
				goTalkToNpc(getEntityById("focusTester"),controlToPlayer);
			}
			// coins
			else if(shellApi.checkEvent(_events.START_POP_COINS)){
				goTalkToNpc(getEntityById("focusTester"),controlToPlayer);
			}
			// hide pop bottle
			if(!shellApi.checkEvent(_events.FOCUS_COLLECTIBLES)){
				popEntity = getEntityById("pop");
				if(popEntity){
					popEntity.add(new Sleep(true,true));
				}
			}
			if(shellApi.sceneManager.previousScene == "game.scenes.mocktropica.poptropicaHQ::PoptropicaHQ"){
				if( shellApi.checkEvent(_events.ACHIEVEMENT_ACHIEVER) && !shellApi.checkEvent(_events.ACHIEVEMENT_DOORK)){
					achievements.completeAchievement( _events.ACHIEVEMENT_DOORK );
				}
			}
			
			safetyWall = getEntityById("safety");
			safetyWall.remove(Wall);
			wall = getEntityById("wall");
			wall.remove(Wall);
			crateTop = getEntityById("crateTop");
			crateTop.remove(Platform);
			setupCrate();
			// begin pre-final fight dialog
			if(shellApi.checkEvent(_events.SERVER_REPAIRED) && !shellApi.checkEvent(_events.BOSS_ESCAPED) ) {
				if ( !shellApi.checkEvent( this._events.DEFEATED_BOSS ) ) {
					this.goTalkToNpc(getEntityById("projectManager"));
				}
			}			
			if(shellApi.checkEvent(_events.DEFEATED_BOSS) && !shellApi.checkHasItem(_events.MEDAL_MOCKTROPICA))
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(.3,1,notifyBossBattlePhoto));
			}
			else if(shellApi.checkHasItem(_events.MEDAL_MOCKTROPICA))
			{
				removeEntity(getEntityById("focusTester"));
				removeEntity(getEntityById("safetyInspector"));
				removeEntity(getEntityById("salesManager"));
				removeEntity(getEntityById("costCutter"));
			}
			setupAnimations();
			//track if non member is playing demo
			//REMOVE THIS WHEN EARLY ACCESS PERIOD ENDS
			/*if(!shellApi.profileManager.active.isMember && !shellApi.checkEvent(_events.STARTED_EA_DEMO)){
				shellApi.completeEvent(_events.STARTED_EA_DEMO);
				shellApi.track("Demo", "StartDemo", null, gCampaignName);
			}*/
		}
		
		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb1"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}
		
		// handle the heap of locations the tester ends up in
		private function positionFocusTester():void
		{
			focusTester = getEntityById("focusTester");
			focusTester.add(new Sleep(false,false));
			Display(focusTester.get(Display)).visible = true;
			if(shellApi.checkHasItem(_events.MEDAL_MOCKTROPICA)){
				removeEntity(focusTester);
			}
			else if(shellApi.checkEvent(_events.DEFEATED_BOSS)){
				EntityUtils.position(focusTester,3800, 1700);
				CharUtils.setAnim(focusTester, Dizzy);
			}
			else if(shellApi.checkEvent(_events.SERVER_REPAIRED)){
				EntityUtils.position(focusTester,2500, 1700);
			}
			else if(shellApi.checkEvent("crate_dazed")){
				EntityUtils.position(focusTester,5600, 1700);
				CharUtils.setAnim(focusTester, Dizzy);
			}
			else if(shellApi.checkEvent(_events.START_CRATE)){
				EntityUtils.position(focusTester,5600, 1700);
				var anims:Vector.<Class> = new Vector.<Class>();
				var comm:Function = Command.create(CharUtils.setAnim,focusTester, Grief);
				SceneUtil.addTimedEvent(this, new TimedEvent(6,0,comm));
				CharUtils.setDirection(focusTester, true);
			}
			else if(shellApi.checkEvent(_events.START_COLLECTIBLES)){
				EntityUtils.position(focusTester, 4200, 1700);
			}
			else if(shellApi.checkEvent(_events.START_POP_COINS)){
				EntityUtils.position(focusTester,1000, 1700);
			}
			else if(shellApi.checkEvent("show_focus_coins")){
				EntityUtils.position(focusTester,1000, 1700);
			}
			else {
				focusTester.add(new Sleep(true));
				Display(focusTester.get(Display)).visible = false;
			}
		}
		
		private function handleEvents(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			switch(event)
			{
				case "show_evil_managers":
					SceneUtil.addTimedEvent(this,new TimedEvent(0.3,1,managersArrive));
					break;
				case "feedingTime":
					if(_boy){
						_boy.remove(CharacterWander);
						SceneUtil.lockInput(this, true);
						CharUtils.lockControls(this.player);
						SceneInteraction(_boy.get(SceneInteraction)).reached.removeAll();
					}
					break;
				case _events.BOY_LEFT_MAIN_STREET_CHEESE:
					if(_boy){
						charGroup.addFSM(_boy);
						CharacterMotionControl(_boy.get(CharacterMotionControl)).maxVelocityX = 350;
						CharUtils.followPath(_boy, new <Point>[new Point(2550, 1740), new Point(3500, 1740)], boyOffScreen);
					}
					break;
				case "boss_transform":
					this.startBossTransform();
					break;
				case "enter_developer":
					var dev:Entity = getEntityById("leadDeveloper");
					var dialog:Dialog = dev.get(Dialog);
					var path:Vector.<Point> = new Vector.<Point>();
					var pLoc:Point = EntityUtils.getPosition(player);
					pLoc.x -= 150;
					path.push(EntityUtils.getPosition(dev),pLoc);
					CharUtils.followPath(dev,path,devRunsIn);
					break;
				case _events.BOSS_FIGHT_START:
					this.shellApi.loadScene( RobotBossBattle );
					break;
				case "showPda":
					showPda();
					break;
				case "bonusGoInside":
					charsLeave();
					break;
				case "giveMedal":
					if(!shellApi.checkHasItem(_events.MEDAL_MOCKTROPICA)){
						shellApi.getItem(_events.MEDAL_MOCKTROPICA,null,true, medallionReceived);
						// complete island
			//			shellApi.completedIsland();				
						//trigger bonus quest
			//			startday2();
						//SceneUtil.addTimedEvent(this, new TimedEvent(0.5,1,Command.create(shellApi.triggerEvent,"startDay2")));
					}
					break;
				case "gotItem_"+_events.POP:
					// adds a wall around the top of pop hq for helmet sequence
					if(shellApi.checkHasItem(_events.POP)){
						safetyWall.add(new Wall());
						var popup:BottleCollectedPopup = super.addChildGroup( new BottleCollectedPopup( super.overlayContainer )) as BottleCollectedPopup;
						popup.id = "bottleGet";
					}
					break;
				case "bottleAchievement":
					achievements.completeAchievement(_events.ACHIEVEMENT_COLLECTOR);
					achievements.onAchievementComplete.addOnce(getHelmet);
					
					break;
				case "gotItem_"+_events.HELMET:
					var itemGroup:ItemGroup = ItemGroup(shellApi.sceneManager.currentScene.getGroupById("itemGroup"));
					SkinUtils.setSkinPart( player, SkinUtils.FACIAL,"mk_helmet",false);
					break;
				case "usedCoin":
					if(!shellApi.checkEvent(_events.PAYED_COIN)){
						goTalkToNpc(getEntityById("focusTester"),focusRunsOff,payCoin);
					}
					break;
				case _events.FOCUS_POP_COINS+2:
					achievements.completeAchievement(_events.ACHIEVEMENT_JUST_FOCUS);
					break;
				case _events.FOCUS_COLLECTIBLES:
					CharUtils.lockControls(player);
					if(popEntity){
						popEntity.remove(Sleep);
					}
					break;
				case "focus_collectibles2":
					CharUtils.lockControls(player, false, false);
					break;
				default:
					break;
			}
		}

		private function medallionReceived():void
		{
			shellApi.completedIsland('', showIslandEndingPopup);
		}

		private function showIslandEndingPopup(...args):void
		{
			SceneUtil.lockInput(this, false);
			
			var islandEndingPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer);
			islandEndingPopup.hasBonusQuestButton = true;
			islandEndingPopup.removed.addOnce(this.lock);
			islandEndingPopup.popupRemoved.addOnce(startday2);
			this.addChildGroup(islandEndingPopup);
		}
		
		private function startday2():void
		{
			var dev:Entity = getEntityById("leadDeveloper");
			if(dev){
				var dialog:Dialog = dev.get(Dialog);
				if(dialog){
					//dialog.sayById("figures");
					//dialog.sayCurrent();
				}
			}
			CharUtils.setDirection(player, false);
		}
		
		private function focusRunsOff(...p):void
		{
			var focusTester:Entity = getEntityById("focusTester");
			var loc:Point = EntityUtils.getPosition(focusTester);
			var dloc:Point = EntityUtils.getPosition(getEntityById("doorPoptropicaHQ"));
			if(loc.x < dloc.x){
				loc.x += 1000;
			}
			else{
				loc.x -= 1000;
			}
			moveNpc(focusTester,loc,runOver);
		}
		
		private function runOver(...p):void
		{
			removeEntity(getEntityById("focusTester"));
			shellApi.triggerEvent("payed_coin",true);
			shellApi.completeEvent("payed_coin");
			controlToPlayer();
		}
		
		private function payCoin(...p):void
		{
			CharUtils.setAnim(player, Salute);
			CharUtils.setAnim(getEntityById("focusTester"),Salute);
		}
		
		// safety guy gives helmet
		private function getHelmet(...nope):void
		{
			var safetyInspector:Entity = getEntityById("safetyInspector");
			goTalkToNpc(safetyInspector, controlToPlayer,hideWall);
		}
		
		private function hideWall(...p):void
		{
			safetyWall.remove(Wall);
			setupCrate();
		}
		
		private function goTalkToNpc(npc:Entity, handleFinish:Function = null, handleReached:Function = null):void
		{
			if(npc!=null)
			{
				var dialog:Dialog = npc.get(Dialog);
				var interaction:Interaction = npc.get(Interaction);
				interaction.click.dispatch(npc);
				if(handleReached){
					SceneInteraction(npc.get(SceneInteraction)).reached.addOnce(handleReached);
				}
				if(handleFinish){
					dialog.complete.addOnce(handleFinish);
				}
				SceneUtil.lockInput(this,true);
			}
		}
		
		private function setupDoors():void
		{
			doorChasm = super.getEntityById("doorChasm");
			doorUniversity = super.getEntityById("doorUniversity");
			// replace door interaction
			SceneInteraction(doorChasm.get(SceneInteraction)).reached.removeAll();
			SceneInteraction(doorChasm.get(SceneInteraction)).reached.add(doorReached);
			SceneInteraction(doorUniversity.get(SceneInteraction)).reached.removeAll();
			SceneInteraction(doorUniversity.get(SceneInteraction)).reached.add(doorReached);
			//Children(doorUniversity.get(Children)).children[0].remove(ToolTip);
			getEntityById(doorChasm.get(Id).id+"NavInteraction").remove(ToolTip);
			getEntityById(doorUniversity.get(Id).id+"NavInteraction").remove(ToolTip);
		}
		
		private function doorReached(char:Entity, door:Entity):void
		{
			/*if(door.get(Id).id == "doorUniversity" && shellApi.checkEvent(_events.MAINSTREET_FINISHED)){
				var isMem:Boolean = shellApi.profileManager.active.isMember;
				//isMem=true;
				if(!isMem){
					var popup:NonMemberBlockPopup = super.addChildGroup( new NonMemberBlockPopup( super.overlayContainer )) as NonMemberBlockPopup;
					popup.id = "nonMemberBlock";
					return;
				}
				else {
					//track if member is starting early access
					//REMOVE THIS WHEN EARLY ACCESS PERIOD ENDS
					if(!shellApi.checkEvent(_events.STARTED_EA)){
						shellApi.completeEvent(_events.STARTED_EA);
						if (shellApi.checkEvent(_events.BLOCKED_FROM_EA)) {
							shellApi.track("Demo", "DemoBlock", "Converted", gCampaignName);
						}
					}
				}
			}*/
			
			if(shellApi.checkEvent(_events.PAYED_COIN)){
				Door( door.get( Door )).open = true;
			}
			else if(shellApi.checkEvent(_events.FOCUS_POP_COINS)){
				stopAndPayUp(door);
			}
			else if(door.get(Id).id == "doorUniversity" && !shellApi.checkEvent(_events.USED_DES_COMPUTER)){
				examineDoor(char,door);
			}
			else{
				Door( door.get( Door )).open = true;
			}
		}
		
		private function examineDoor(char:Entity, door:Entity):void
		{
			var nav:Entity = getEntityById(door.get(Id).id+"NavInteraction");
			var navInt:Interaction = nav.get(Interaction);
			navInt.click = new Signal();
			navInt.click.addOnce(Command.create(saySomething,player,"doorBroken",true));
			navInt.click.dispatch(nav);
			var targ:Point = EntityUtils.getPosition(nav);
			SceneUtil.lockInput(this,true);
			Dialog(player.get(Dialog)).complete.addOnce(controlToPlayer);
		}
		
		private function stopAndPayUp(door:Entity):void
		{
			// focus tester stops you
			var focusTester:Entity = getEntityById("focusTester");
			var targ:Point = EntityUtils.getPosition(getEntityById(door.get(Id).id+"NavInteraction"));
			var dx:Number = Math.abs(targ.x - EntityUtils.getPosition(focusTester).x);
			if(dx >= 200){
				if(door.get(Id).id=="doorUniversity"){
					targ.x -= 150;
					EntityUtils.position(focusTester,targ.x - 1000,focusTester.get(Spatial).y);
				}else{
					targ.x += 150;
					EntityUtils.position(focusTester,targ.x + 1000,focusTester.get(Spatial).y);
				}
			}
			SceneUtil.lockInput(this,true);
			SceneUtil.setCameraTarget(this, focusTester);
			Dialog(focusTester.get(Dialog)).setCurrentById("coinsPlease");
			moveNpc(focusTester,targ,Command.create(goTalkToNpc,controlToPlayer));
		}
		
		private function controlToPlayer(...p):void
		{
			SceneUtil.setCameraTarget(this,player);
			SceneUtil.lockInput(this,false);
		}
		
		//make them walk onto screen, then talk
		private function managersArrive():void
		{
			var safetyInspector:Entity = getEntityById("safetyInspector");
			var salesManager:Entity = getEntityById("salesManager");
			var costCutter:Entity = getEntityById("costCutter");
			Sleep(focusTester.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(salesManager.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(safetyInspector.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(costCutter.get(Sleep)).ignoreOffscreenSleep = true;
			Display(focusTester.get(Display)).moveToFront();
			Display(safetyInspector.get(Display)).moveToFront();
			Display(salesManager.get(Display)).moveToFront();
			Display(costCutter.get(Display)).moveToFront();
			CharUtils.moveToTarget(focusTester, 3800,1740, false, Command.create(saySomething, focusTester, "begin"));
			CharUtils.moveToTarget(safetyInspector, 3700,1740);
			CharUtils.moveToTarget(salesManager, 3600,1740);
			CharUtils.moveToTarget(costCutter, 3500,1740);
			SceneUtil.lockInput(this, true);
			CharUtils.setDirection(player,false);
		}
		
		private function moveNpc(char:Entity, target:Point, finished:Function = null):void
		{
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(EntityUtils.getPosition(char),target);
			CharUtils.followPath(char,path,finished);
		}
		
		private function saySomething(thing:*, char:Entity, id:String, faceRight:Boolean = true):void
		{
			CharUtils.setDirection(char,faceRight);
			var dialog:Dialog = char.get(Dialog);
			dialog.sayById(id);
		}
		
		private function loadPets():void
		{
			if(_numPets > 0)
			{
				var narf:Narf = new Narf();
				this.player.add(narf);
				narf.targetChanged.add(curdLanded);
				_pets = new Vector.<Entity>();
				
				for(var i:uint = 0; i < _numPets; i++)
				{
					_narfCreator.create(_boy, narfLoaded);
				}
			}
			if(_numPets == 1){
				Dialog(_boy.get(Dialog)).start.add(lock);
				Dialog(_boy.get(Dialog)).complete.add(unlock);
			}
		}
		
		private function lock(...p):void
		{
			SceneUtil.lockInput(this,true);
		}
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this,true);
		}
		
		private function narfLoaded(entity:Entity):void
		{
			_pets.push(entity);
			this._hitContainer.setChildIndex(Display(this.player.get(Display)).displayObject, this._hitContainer.numChildren - 1);
			FSMControl(entity.get(FSMControl)).stateChange = new Signal();
			FSMControl(entity.get(FSMControl)).stateChange.add(petStateChange);
			
			if(_numPets == 1)
			{
				entity.add(new Id("pet"));
				entity.add(new Talk());
				CharUtils.assignDialog(entity, this, "pet", false, 0, 1, true);
			}			
		}
		
		private function petStateChange(type:String, entity:Entity):void
		{
			if(type == "eat")
			{
				Narf(entity.get(Narf)).petChew.addOnce(petChew);
				for each(var pet:Entity in _pets)
				{
					if(pet != entity)
					{
						Narf(pet.get(Narf)).targetCurd = false;
					}
				}
			}
		}
		
		private function petChew():void
		{
			super.removeEntity(_currentCurd);
			for each(var pet:Entity in _pets)
			{
				Narf(pet.get(Narf)).targetCurd = false;
				MotionTarget(pet.get(MotionTarget)).targetSpatial = _boy.get(Spatial);
			}
		}
		
		private function curdLanded(spatial:Spatial, curd:Entity):void
		{
			_currentCurd = curd;
			for each(var entity:Entity in _pets)
			{
				if(spatial != null)
				{
					var distance:Number = GeomUtils.dist(spatial.x, spatial.y, _boy.get(Spatial).x, _boy.get(Spatial).y);
					
					if(distance < 900)
					{
						entity.get(Narf).targetCurd = true;
						MotionTarget(entity.get(MotionTarget)).targetSpatial = spatial;
						if(_numPets > 1 && _boy != null)
						{
							Narf(this.player.get(Narf)).targetChanged.removeAll();
							SceneUtil.lockInput(this, true, true);
							CharUtils.lockControls(this.player);
							_boy.remove(CharacterWander);
							SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, proximityWaitDone));
						}
					}
				}
				else
				{
					entity.get(Narf).targetCurd = false;
					MotionTarget(entity.get(MotionTarget)).targetSpatial = _boy.get(Spatial);
				}
			}
		}
		
		private function proximityWaitDone():void
		{
			super.addSystem(new ProximitySystem, SystemPriorities.update);
			var proximity:Proximity = new Proximity(200, _boy.get(Spatial));
			proximity.squareTest = true;
			proximity.entered.addOnce(petsBackToBoy);
			_pets[0].add(proximity);
		}
		
		private function petsBackToBoy(entity:Entity):void
		{
			SceneUtil.setCameraTarget(this, _boy, true);
			var boyDialog:Dialog = _boy.get(Dialog);
			boyDialog.sayById("first_curd");
			boyDialog.complete.addOnce(boyDoneTalking);
		}
		
		private function boyDoneTalking(dialogData:DialogData):void
		{
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM(_boy);
			CharacterMotionControl(_boy.get(CharacterMotionControl)).maxVelocityX = 450;
			SceneInteraction(_boy.get(SceneInteraction)).reached.removeAll();
			MotionBounds(_boy.get(MotionBounds)).box.left = -600;
			CharUtils.followPath(_boy, new <Point>[new Point(2550, 1740), new Point(-600, 1740)], boyOffScreen);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, backToPlayer));
			super.shellApi.completeEvent(_events.BOY_LEFT_MAIN_STREET_CHASM);
		}
		
		private function backToPlayer():void
		{
			SceneUtil.setCameraTarget(this, this.player, false);
			SceneUtil.lockInput(this, false);
			CharUtils.lockControls(this.player, false, false);
		}
		
		private function boyOffScreen(entity:Entity):void
		{
			super.removeEntity(entity);
			
			for each(var pet:Entity in _pets)
				super.removeEntity(pet);
							
			SceneUtil.setCameraTarget(this, this.player, false);
			SceneUtil.lockInput(this, false);
			CharUtils.lockControls(this.player, false, false);
		}
		
		private function devRunsIn(...p):void
		{
			CharUtils.setDirection( this.player, false );
			var dialog:Dialog = getEntityById("leadDeveloper").get(Dialog);
			dialog.sayById("use_fps_engine");
		}

		private function startBossTransform():void 
		{
			var grp:BossIntroGroup = new BossIntroGroup( this, this._hitContainer );
		}

		private function notifyBossBattlePhoto():void 
		{
			shellApi.takePhotoByEvent( _events.DEFEATED_BOSS, startEndDialog );
		}

		private function startEndDialog():void
		{
			SceneUtil.lockInput( this, true );
			var focusTester:Entity = getEntityById("focusTester");
			var safetyInspector:Entity = getEntityById("safetyInspector");
			var startDialog:Dialog = focusTester.get(Dialog);
			startDialog.sayById("escape");
			var endDialog:Dialog = safetyInspector.get(Dialog);
			// do ipad thing at end
			endDialog.complete.addOnce(loadTablet);
		}
		
		private function loadTablet(...p):void
		{
			super.loadFile( "plane.swf", makeTablet);
		}
		
		private function makeTablet(clip:MovieClip):void
		{
			var tablet:Entity = EntityUtils.createMovingEntity(this, clip, hitContainer);
			tablet = TimelineUtils.convertClip(clip,this,tablet);
			tablet.add(new Id("plane"));
			tablet.get(Timeline).gotoAndPlay("fly");
			EntityUtils.position(tablet,3000, 500);
			tablet.get(Sleep).ignoreOffscreenSleep = true;
			tablet.get(Display).moveToFront();
			tabletDescendSequence();
		}
		
		private function tabletDescendSequence(...p):void
		{
			shellApi.triggerEvent("planeDescend");
			var tablet:Entity = getEntityById("plane");
			SceneUtil.setCameraPoint(this,tablet.get(Spatial).x+300,1500);
			var tween:Tween =  new Tween();
			tween.to(tablet.get(Spatial),2,{x:3000, y:1400, ease:Quadratic.easeInOut, onComplete:transformPlane});
			tablet.add(tween);
		}
		
		private function transformPlane():void
		{
			shellApi.triggerEvent("planetransform");
			AudioUtils.getAudio(this,"sceneSound").stop(SoundManager.EFFECTS_PATH+"rocket_engines_01_loop.mp3","effects");
			var tablet:Entity = getEntityById("plane");
			var timeLine:Timeline = tablet.get(Timeline);
			timeLine.gotoAndPlay("landing");
			timeLine.handleLabel("transformOver",enterPlane);
		}		

		private function enterPlane(...p):void
		{
			// run to and get in plane
			var plane:Entity = getEntityById("plane");
			var focusTester:Entity = getEntityById("focusTester");
			var safetyInspector:Entity = getEntityById("safetyInspector");
			var salesManager:Entity = getEntityById("salesManager");
			var costCutter:Entity = getEntityById("costCutter");
			var chars:Vector.<Entity> = new Vector.<Entity>();
			chars.push(costCutter,salesManager,safetyInspector,focusTester);
			for (var i:int = 0;i<chars.length;i++) 
			{
				var path:Vector.<Point> = new Vector.<Point>();
				path.push(new Point(plane.get(Spatial).x+180+i*15,plane.get(Spatial).y+320),
						new Point(plane.get(Spatial).x+180+i*15,plane.get(Spatial).y+120));
				if(i==chars.length-1){
					CharUtils.followPath(chars[i],path,Command.create(joinPlane,i,true));
				}else{
					CharUtils.followPath(chars[i],path,Command.create(joinPlane,i));
				}
			}
		}
		
		private function joinPlane(ent:Entity, i:int, end:Boolean = false):void
		{
			CharUtils.setAnim(ent,Stand);
			CharacterGroup(getGroupById("characterGroup",this)).removeFSM(ent);
			MotionUtils.zeroMotion(ent);
			CharUtils.setDirection(ent,false);
			//merge npc graphics with plane
			var plane:Entity = getEntityById("plane");
			var planeDisplay:Display = EntityUtils.getDisplay(plane);
			var charDisplay:Display = EntityUtils.getDisplay(ent);
			var charHolder:MovieClip = planeDisplay.displayObject.getChildByName("charHolder"+i) as MovieClip;
			// position and push char into background of plane
			Display(ent.get(Display)).setContainer(charHolder);
			EntityUtils.position(ent, 0, 0);
			if(end){
				closePlane();
			}
		}		
		
		private function closePlane():void
		{
			shellApi.triggerEvent("planeClose");
			var plane:Entity = getEntityById("plane");
			Timeline(plane.get(Timeline)).gotoAndPlay("closeDome");
			Timeline(plane.get(Timeline)).handleLabel("end",flyAway);
		}
			
		private function flyAway(...p):void
		{
			shellApi.triggerEvent("planeFly");
			var plane:Entity = getEntityById("plane");
//			var focusTester:Entity = getEntityById("focusTester");
//			var safetyInspector:Entity = getEntityById("safetyInspector");
//			var salesManager:Entity = getEntityById("salesManager");
//			var costCutter:Entity = getEntityById("costCutter");
			Tween(plane.get(Tween)).to(plane.get(Motion),2,{x:1000,y:100,ease:Quad.easeInOut, onComplete:Command.create(planeFinished,plane)});
		}
		
		// clean up plane
		private function planeFinished(plane:Entity):void
		{
			shellApi.triggerEvent(_events.BOSS_ESCAPED,true);
			Display(plane.get(Display)).visible = false;
			removeEntity(plane);
			removeEntity(getEntityById("focusTester"));
			removeEntity(getEntityById("safetyInspector"));
			removeEntity(getEntityById("salesManager"));
			removeEntity(getEntityById("costCutter"));
			// get medal conversation
			var manager:Entity = getEntityById("projectManager");
			goTalkToNpc(manager);
			SceneUtil.setCameraTarget(this,player);
		}
		
		private function showPda():void
		{
			var popup:Day2JordansPDAPopup = this.addChildGroup( new Day2JordansPDAPopup( super.overlayContainer )) as Day2JordansPDAPopup;
			popup.id = "pda";
			//popup.removed.addOnce( this.relockScene );
			popup.closeClicked.add( relockScene );
			// get rid of loading icon during pda.
			SceneUtil.lockInput( this, false );
		}

		private function relockScene( ...p ):void {
			var dialog:Dialog = getEntityById("leadDeveloper").get(Dialog);
			dialog.sayById("pda");
			SceneUtil.lockInput( this, true );
		}

		private function charsLeave():void
		{
			// done with talking, unlock
			SceneUtil.lockInput( this, false );
			// lead programmer and project manager leave for day 2 adventure
			var door:Entity = getEntityById("doorPoptropicaHQ");
			var doorLoc:Point = EntityUtils.getPosition(door);
			var prog:Entity = getEntityById("leadDeveloper");
			var manager:Entity = getEntityById("projectManager");
			moveNpc(prog,doorLoc,Command.create(hideNpc, prog));
			moveNpc(manager,doorLoc,Command.create(hideNpc, manager));			
		}
		
		private function hideNpc(junk:*, char:Entity):void
		{
			removeEntity(char);
		}
		
//		private function loadCrate(...p):void
//		{
//			super.loadFile( "crate.swf", setupCrate);
//		}
		
		private function setupCrate():void
		{
			if(crate == null){
				crate = EntityUtils.createSpatialEntity(this, _hitContainer["crate"]);
				crate = TimelineUtils.convertClip(_hitContainer["crate"],this,crate,null,false);
				crate.add(new Id("crate"));
				Sleep(crate.get(Sleep)).ignoreOffscreenSleep = true;
			}
			if(shellApi.checkEvent(_events.SMASHED_CRATE)){
				crate.get(Timeline).gotoAndStop("broken");
				crate.get(Display).moveToBack();
				crate.get(Display).visible = true;
			}
			else if(shellApi.checkEvent(_events.FOCUS_HAS_CRATE)||shellApi.checkEvent(_events.START_CRATE)){
				crate.get(Timeline).gotoAndStop("whole");
				crate.get(Display).moveToFront();
				crate.get(Display).visible = true;
				removeEntity(getEntityById("doorUniversity"),true);
				wall.add(new Wall());
				crateTop.add(new Platform());
				EntityUtils.position(focusTester,5600, 1700);
				var anims:Vector.<Class> = new Vector.<Class>();
				var comm:Function = Command.create(CharUtils.setAnim,focusTester, Grief);
				SceneUtil.addTimedEvent(this, new TimedEvent(6,0,comm));
				CharUtils.setDirection(focusTester, true);
			}
			else{
				crate.get(Display).visible = false;
			}
		}
		
		private function setBuildingPositions():void
		{
			var collisionGroup:CollisionGroup = super.getGroupById("collisionGroup") as CollisionGroup;
			hitBMD = collisionGroup.hitBitmapData;
			var bitmapHits:MovieClip = MovieClip(super._hitContainer).bitmapHits;			
			var buildings:Vector.<String> = getBuildingOrder();
			var correctCount:int = 0;
			var buildingX:Number = 564;			
			for (var i:uint = 0; i < buildings.length; i++) {
				var curBuilding:MovieClip = super._hitContainer[buildings[i]];
				var curBuildingHit:MovieClip = bitmapHits[buildings[i] + "Hits"];
				if (buildings[i] == "popStatue") {
					buildingX -= 52;
				}
				if (buildings[i] == "car") {
					buildingX -= 32;
				}
				curBuilding.x = buildingX;
				curBuildingHit.x = buildingX;
				buildingX += curBuilding.width;
				if(buildings[i]=="blueLocust"){
					// move door
					var doorTarg:Point = new Point(curBuilding.x+300,1714);
					var doorEnt:Entity = getEntityById("doorCommon");
					if(doorEnt){
						var door:DisplayObject = doorEnt.get(Display).displayObject;
						EntityUtils.position(doorEnt,doorTarg.x,doorTarg.y);
						door.x = doorTarg.x;
						door.y = doorTarg.y;
						ToolTipCreator.addUIRollover(doorEnt,ToolTipType.EXIT_3D,"ENTER");
					}
				}
			}

			var matrix:Matrix = new Matrix();
			matrix.scale(collisionGroup.hitBitmapDataScale, collisionGroup.hitBitmapDataScale);		
			matrix.tx = collisionGroup.hitBitmapOffsetX;
			matrix.ty = collisionGroup.hitBitmapOffsetY;
			hitBMD.fillRect(hitBMD.rect, 0x00000000);
			hitBMD.draw(bitmapHits, matrix);
		}
		
		private function getBuildingOrder():Vector.<String>
		{
			var vect:Array;
			// TODO :: Should we be getting this from the server? - bard
			var order:String = shellApi.getUserField(MOCK_LAYOUT,shellApi.island);
			if(order){
				shellApi.triggerEvent(_events.MAINSTREET_REARRANGED,true);
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
		
		private function setupAnimations():void
		{
			this.addSystem(new BitmapSequenceSystem());
			var clips:Array = ["signLeft", "signRight", "tree1", "tree2", "hydrant","hardwareStore", "blueLocust", "popHq", "popStatue", "car"];			
			var display:Display;			
			for(var i:uint = 0; i < clips.length; i++)
			{
				var entity:Entity = BitmapTimelineCreator.createBitmapTimeline(this._hitContainer[clips[i]]);
				this.addEntity(entity);				
				display = entity.get(Display);
				display.displayObject.mouseChildren = false;
				display.displayObject.mouseEnabled = false;
				entity.add(new Id(clips[i]));
				var timeline:Timeline = entity.get(Timeline);
				if (i < 4) {
					timeline.gotoAndPlay(i*3 - 20);
					timeline.playing = true;
				}
				if(!shellApi.checkEvent(_events.USED_DES_COMPUTER)){
					if(clips[i] == "signRight"){
						display.visible = false;
					}
				}
				if(shellApi.checkEvent(_events.MAINSTREET_UNFINISHED)){
					// set unfinished building look
					timeline.gotoAndPlay("unfinished");
				}
				else {
					timeline.gotoAndStop("finished");
				}
				if(2 <= i && i <= 4){
					if(!shellApi.checkEvent(_events.DEVELOPER_RETURNED)){
						// set glitched look
						timeline.gotoAndPlay("glitched");
						// sounds
						setupGlitchSounds(entity,timeline,clips[i]);
					}
					else {
						timeline.gotoAndStop("finished");
					}
				}
				// fix layering	
				display.moveToBack();
			}
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi,null,null,false);

		}
		
		private function setupGlitchSounds(entity:Entity, timeline:Timeline, entId:String):void
		{
			var audioGroup:AudioGroup = getGroupById("audioGroup") as AudioGroup;
			audioGroup.addAudioToEntity(entity);
			var audio:Audio = entity.get(Audio);
			entity.add(new AudioRange(700, 0.01, 0.7, Quad.easeInOut));
			if(entId=="tree1"||entId=="tree2"){							
				timeline.handleLabel("static",Command.create(audio.playCurrentAction,"buzz"),false);
			}
			if(entId=="hydrant"){
				timeline.handleLabel("eyesOpen",Command.create(audio.playCurrentAction,"appear"),false);
				timeline.handleLabel("land",Command.create(audio.playCurrentAction,"hop"),false);
				timeline.handleLabel("land2",Command.create(audio.playCurrentAction,"hop"),false);
				timeline.handleLabel("roar",Command.create(audio.playCurrentAction,"roar"),false);
			}
		}		
		
	};
};