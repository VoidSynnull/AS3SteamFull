package game.scenes.viking.fortress
{
	import com.greensock.easing.Sine;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Character;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Skin;
	import game.components.entity.character.Talk;
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Sword;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.ItemGroup;
	import game.scenes.viking.VikingScene;
	import game.scenes.viking.diningHall.DiningHall;
	import game.scenes.viking.fortress.components.FortressTrash;
	import game.scenes.viking.fortress.systems.FortressTrashSystem;
	import game.scenes.viking.jungle.WoodChips;
	import game.scenes.viking.river.River;
	import game.scenes.viking.shared.popups.MapPopup;
	import game.systems.motion.ProximitySystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.util.Utils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class Fortress extends VikingScene
	{
		private var gobletFall:Entity;
		private var viking:Entity;
		private var dialogTarget:Entity;
		
		private var proximityEntity:Entity;
		private var proximity:Proximity;
		private var dumpLock:Boolean = false;
		
		private var chuteClick:Entity;
		private var chuteClickInteraction:Interaction;
		
		private var sparkle:Entity;
		
		private var woodChipsEmitter:WoodChips;
		private var woodChipsEmitterEntity:Entity;
		private var woodChipsTarget:Entity;
		
		private var logFall:Entity;
		private var plat:Entity;
		private var log:Entity;
		
		private var talkTarg:Entity;
		private var e2:Emitter2D;
		
		private var logClick:Entity;
		private var logInteraction:Interaction;
		
		public function Fortress()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/fortress/";
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
			this.viking = this.getEntityById("viking");
			viking.get(Npc).ignoreDepth = true;
			
			setupMapDoor();
			
			if(!shellApi.checkEvent(_events.GOBLET_DROPPED)) {
				if(this.getEntityById("goblet")){
					this.getEntityById("goblet").get(Spatial).y += 500;
				}
				setupProximityEntity();
				setupTrash();
				setupSparkle();
			}else{
				if(!shellApi.checkEvent(_events.PEAK_EXPLODED)){
					var clip:MovieClip = _hitContainer["proximityEntity"];
					clip.visible = false;
					setupTrash();
					startTrashDump();
					setupSparkle();
					startRandomSparkle();
					//var sparkleClip:DisplayObject = this._hitContainer["sparkle"];
					//this._hitContainer.removeChild(sparkleClip);
				} else {
					setupLog();
					setupFortressDoor();
				}
			}
			
			if(shellApi.checkEvent(_events.BALANCE_GAME_COMPLETE) && !shellApi.checkEvent(_events.RIVER_COMPLETED)) {
				SceneUtil.lockInput(this, true);
				
				var npc1:Entity = this.getEntityById("npc1");
				SkinUtils.applyLook(npc1, SkinUtils.getLook(this.shellApi.player));
				
				this.removeEntity(this.shellApi.player);
				
				var logClip:MovieClip = this._hitContainer["log"];
				
				for(var index:int = 1; index <= 4; ++index)
				{
					var npc:Entity = this.getEntityById("npc" + index);
					
					logClip.addChildAt(Display(npc.get(Display)).displayObject, 1);
					
					Npc(npc.get(Npc)).ignoreDepth = true;
					
					var leg:Entity = CharUtils.getPart(npc, CharUtils.LEG_BACK);
					Display(leg.get(Display)).visible = false;
					
					var foot:Entity = CharUtils.getPart(npc, CharUtils.FOOT_BACK);
					Display(foot.get(Display)).visible = false;
					
					ToolTipCreator.removeFromEntity(npc);
				}
				
				this.shellApi.player = this.log;
				
				SceneUtil.setCameraTarget(this, plat);
				
				talkTarg.add( new FollowTarget( log.get( Spatial )));
				talkTarg.get(FollowTarget).offset = new Point(100, -100);
				
				Dialog(talkTarg.get(Dialog)).sayById("outOfHere");
				TweenUtils.globalTo(this,log.get(Spatial),10,{x:2000, delay:0.5, ease:Sine.easeInOut},"log_ride");
				SceneUtil.addTimedEvent(this, new TimedEvent(6, 1, loadRiverScene, true));
			}
			
			_hitContainer['grate'].mouseEnabled = false;
			_hitContainer['grate'].mouseChildren = false;
			
			_hitContainer.swapChildren(viking.get(Display).displayObject, _hitContainer['grate']);
			viking.get(Dialog).faceSpeaker = false;
		}
		
		private function loadRiverScene():void {
			shellApi.loadScene(River);
		}
		
		private function setupCustomDialog():void
		{
			talkTarg = new Entity();
			var dialog:Dialog = new Dialog()
			dialog.faceSpeaker = false;     // the display will turn towards the player if true.
			dialog.dialogPositionPercents = new Point(0, 1);  // set the percent of the bounds that the dialog is offset.  The current arts will cause it to be offset 0% on x axis and 100% on y (66px).
			
			talkTarg.add(dialog);
			talkTarg.add(new Id("talkTarg"));
			talkTarg.add(new Spatial());
			talkTarg.add(new Display(_hitContainer["talkTarg"]));
			talkTarg.add(new Edge(33, 66, 33, 0));   //set the distance from the characters registration point.
			talkTarg.add(new Character());           //allows this entity to get picked up by the characterInteractionSystem for dialog on click
			talkTarg.get(Display).alpha = 0;
			
			dialog.start.add(this.talkStart);
			dialog.complete.add(this.talkStop);
			
			super.addEntity(talkTarg);
			
		}
		
		override protected function addCharacterDialog(container:Sprite):void
		{
			// custom dialog entity MUST be added here so that dialog from the xml gets assigned to it.
			if(shellApi.checkEvent(_events.BALANCE_GAME_COMPLETE)) {
				setupCustomDialog();
			}else{
				if(_hitContainer["talkTarg"]) {
					_hitContainer["talkTarg"].visible = false;
				}
			}
			super.addCharacterDialog(container);
		}
		
		private function talkStart(data:DialogData):void
		{
			Talk(this.getEntityById("npc1").get(Talk)).isStart = true;
		}
		
		private function talkStop(data:DialogData):void
		{
			Talk(this.getEntityById("npc1").get(Talk)).isEnd = true;
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( event == "axe_used" ) {
				if(!shellApi.checkEvent("log_cut_down") && shellApi.checkEvent(_events.PEAK_EXPLODED)) {
					if(player.get(Spatial).x < 265 && player.get(Spatial).y < 970) {
						SceneUtil.lockInput(this, true);
						CharUtils.moveToTarget(player, 130, 925, false, chopTree);
					}else{
						Dialog(player.get(Dialog)).sayById("nothingToChop");
					}
				} else {
					Dialog(player.get(Dialog)).sayById("nothingToChop");
				}
			}
		}
		
		private function chopTree(entity:Entity):void {
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, startChop, true));
			CharUtils.setDirection(player, true);
			var lookData:LookData = new LookData();
			lookData.applyAspect( new LookAspectData( SkinUtils.ITEM, "comic_axe" ) );
			SkinUtils.applyLook( player, lookData, false );
		}
		
		private function startChop():void {
			var threeChops:Vector.<Class> = new Vector.<Class>();
			threeChops.push(Sword, Sword, Sword);
			CharUtils.setAnimSequence(player, threeChops);
			player.get(Timeline).handleLabel("sword", swingAxe, false);
			player.get(Timeline).handleLabel("fire", woodChips, false);
			SceneUtil.addTimedEvent(this, new TimedEvent(4, 1, preTreeFall, true));
		}
		
		private function preTreeFall():void {
			var lookData:LookData = new LookData();
			lookData.applyAspect( new LookAspectData( SkinUtils.ITEM, "empty" ) );
			SkinUtils.applyLook( player, lookData, false );
			logFall.get(Tween).to(logFall.get(Spatial), 2, { rotation:5, ease:Sine.easeIn, onComplete:treeFall });
		}
		
		private function treeFall(entity:Entity=null):void {
			var tx:Number = 355;//logFall.get(Spatial).x + 40;
			var ty:Number = 1001;//logFall.get(Spatial).y + 50;
			logFall.get(Tween).to(logFall.get(Spatial), 1, { rotation:85, ease:Sine.easeIn });
			logFall.get(Tween).to(logFall.get(Spatial), 1, { x:tx, y:ty, ease:Sine.easeIn, onComplete:treeFell });
			CharUtils.setDirection(player, true);
		}
		
		private function treeFell():void {
			SceneUtil.lockInput(this, false);
			MotionUtils.addWaveMotion( logFall, new WaveMotionData( "y", 6, 0.04 , "cos" ), this );
			plat.get(Spatial).y += 1000;
			plat.add(logFall.get(SpatialAddition));
			shellApi.completeEvent(_events.LOG_CUT_DOWN);
			e2.start();
			this.shellApi.triggerEvent("splash");
		}
		
		private function woodChips():void {
			woodChipsEmitter.start();
			this.shellApi.triggerEvent("chop");
		}
		
		private function swingAxe(entity:Entity=null):void {
			var hand:Entity = Skin( shellApi.player.get( Skin )).getSkinPartEntity( "item" );
			var handSpatial:Spatial = hand.get( Spatial );
			TweenUtils.globalFrom(this,handSpatial,0.4,{rotation:160},"axe_rot");
		}
		
		private function setPlayerRight(entity:Entity):void {
			CharUtils.setDirection(player, true);
		}
		
		private function setupSparkle():void
		{
			var sparkleClip:DisplayObject = this._hitContainer["sparkle"];
			sparkle = EntityUtils.createSpatialEntity(this, sparkleClip);
			TimelineUtils.convertClip(this._hitContainer["sparkle"], this, sparkle);
			
			DisplayUtils.moveToTop(sparkle.get(Display).displayObject);
			sparkle.get(Timeline).gotoAndStop(0);
		}
		
		private function setupLog():void {
			var logFallClip:MovieClip = _hitContainer["logFall"];
			var splashClip:MovieClip = _hitContainer["splash"];
			
			logFall = EntityUtils.createSpatialEntity(this, logFallClip);
			logFall.add(new Tween());
			var logWrapper:BitmapWrapper = DisplayUtils.convertToBitmap(_hitContainer["logFall"]["log"]);
			logWrapper.bitmap.smoothing = true;
			
			plat = getEntityById("logPlat");
			plat.get(Display).visible = false;
			
			if(!shellApi.checkEvent( _events.LOG_CUT_DOWN)) {
				var shardAsset:MovieClip = super.getAsset( "chips.swf") as MovieClip; 
				var bitmapData:BitmapData = BitmapUtils.createBitmapData(shardAsset);
				woodChipsEmitter = new WoodChips();
				woodChipsEmitter.init( bitmapData );
				
				woodChipsTarget = new Entity();
				woodChipsTarget.add(new Spatial());
				woodChipsTarget.get(Spatial).x = 220;
				woodChipsTarget.get(Spatial).y = 898;
				
				woodChipsEmitterEntity = EmitterCreator.create( this, super._hitContainer, woodChipsEmitter, 0, 0, player, "mEmitterEntity", woodChipsTarget.get(Spatial), false );
				_hitContainer['log'].visible = false;
				plat.get(Spatial).y -= 1000;
				
				e2 = new Emitter2D();
				e2.counter = new Blast(100);
				e2.addInitializer(new ImageClass(Dot, [2], true, 50));
				e2.addInitializer(new Position(new RectangleZone(-140, -5, 165, 5)));
				e2.addInitializer(new Velocity(new RectangleZone(100, -100, 100, -100)));
				e2.addInitializer(new Lifetime(0.7));
				e2.addInitializer(new ScaleImageInit(0.5, 1));
				e2.addInitializer(new RotateVelocity(-20, 20));
				e2.addAction(new ColorChange(0xFF22A0D2, 0xFFFFFFFF));
				e2.addAction(new Rotate());
				e2.addAction(new RandomDrift(100, 20));
				e2.addAction(new Move());
				e2.addAction(new Age());
				e2.addAction(new Accelerate(0, 260));
				
				EmitterCreator.create(this, splashClip, e2);
				
				//click for logClick
				logClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["logClick"]), this);
				logClick.remove(Timeline);
				logClick.get(Display).alpha = 0;
				logInteraction = logClick.get(Interaction);
				logInteraction.downNative.add( Command.create( clickLog ));
			} else {
				_hitContainer["logClick"].visible = false;
				logFall.get(Display).visible = false;
				var clip:MovieClip = _hitContainer['log'];
				
				BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
				log = EntityUtils.createMovingEntity(this, clip, _hitContainer);
				MotionUtils.addWaveMotion( log, new WaveMotionData( "y", 6, 0.04 , "cos" ), this );
				plat.add(log.get(SpatialAddition));
			}
		}
		
		private function clickLog(event:Event):void {
			//SceneUtil.lockInput(this, true);
			var destination:Destination = CharUtils.moveToTarget(player, 175, 925, false, sayWontBudge);
			destination.ignorePlatformTarget = true;
		}
		
		private function sayWontBudge(entity:Entity):void {
			//SceneUtil.lockInput(this, false);
			CharUtils.setDirection(player, true);
			Dialog(player.get(Dialog)).sayById("wontBudge");
		}
		
		private function setupTrash():void {
			var i:uint;
			
			for (i=0;i<=12;i++){
				var t:MovieClip = super._hitContainer["trashContainer"]["t"+(i+1)];
				var e:Entity = EntityUtils.createSpatialEntity(this, t, super._hitContainer["trashContainer"]);
				e.get(Display).displayObject.gotoAndStop(Math.ceil(Math.random()*12));
				
				e.add(new FortressTrash());
			}
			
			super._hitContainer["trashContainer"].mask = super._hitContainer['masker'];
			
			super.addSystem(new FortressTrashSystem());
			
			var clip:MovieClip = super._hitContainer["goblet"];
			gobletFall = EntityUtils.createSpatialEntity(this, clip, super._hitContainer);
			gobletFall.add(new Tween());
			gobletFall.get(Display).visible = false;
			
			chuteClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["chuteClick"]), this);
			chuteClick.remove(Timeline);
			chuteClickInteraction = chuteClick.get(Interaction);
			chuteClickInteraction.downNative.add( Command.create( clickChute ));
			chuteClick.get(Display).alpha = 0;
		}
		
		private function clickChute(event:Event):void {
			Dialog(player.get(Dialog)).sayById("wayIn");
		}
		
		private function enterGoblet():void {
			gobletFall.get(Display).visible = true;
			var tx:Number = 526;
			var ty:Number = 1221
			gobletFall.get(Tween).to(gobletFall.get(Spatial), .7, { x:tx, y:ty, rotation:0, ease:Sine.easeIn, onComplete:setupGoblet });
		}
		
		private function setupGoblet():void {
			if(this.getEntityById("goblet")){
				this.getEntityById("goblet").get(Spatial).y = 1221;
			}
			SceneUtil.addTimedEvent(this, new TimedEvent(.2, 1, removeGobletFall, true));
			SceneUtil.lockInput(this, false);
			dumpLock = false;
		}
		
		private function removeGobletFall():void {
			gobletFall.get(Display).visible = false;
			sparkle.get(Timeline).gotoAndPlay(1);
			startRandomSparkle();
		}
		
		private function startRandomSparkle():void {
			var delay:Number = Utils.randNumInRange(4, 8);
			SceneUtil.addTimedEvent(this, new TimedEvent(delay, 1, startSparkle, true));
		}
		
		private function startSparkle():void {
			if(!shellApi.checkItemEvent(_events.GOBLET)){
				sparkle.get(Timeline).gotoAndPlay(1);
				startRandomSparkle();
			}
		}
		
		private function setupProximityEntity():void
		{
			var clip:MovieClip = _hitContainer["proximityEntity"];
			proximityEntity = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			proximityEntity.add(spatial);
			proximityEntity.add(new Display(clip));
			proximityEntity.get(Display).alpha = 0;
			
			super.addEntity(proximityEntity);
			
			this.addSystem(new ProximitySystem());
			
			proximity = new Proximity(500, this.player.get(Spatial));
			this.proximityEntity.add(proximity);
			dumpLock = true;
			proximity.entered.addOnce(startTrashDump);
		}
		
		private function startTrashDump(entity:Entity=null):void {
			if(dumpLock){
				SceneUtil.lockInput(this, true);
			}
			dumpTrash();
		}
		
		private function startRandomDump():void {
			var randomInterval:Number = Utils.randNumInRange(5, 10);
			SceneUtil.addTimedEvent(this, new TimedEvent(randomInterval, 1, dumpTrash, true));
		}
		
		private function dumpTrash():void {
			if(!shellApi.checkEvent(_events.GOBLET_DROPPED)) {
				SceneUtil.addTimedEvent(this, new TimedEvent(0.2, 1, enterGoblet, true));
				shellApi.completeEvent(_events.GOBLET_DROPPED);
			}
			FortressTrashSystem(super.getSystem(FortressTrashSystem)).startDump();
			startRandomDump();
			//garbage sounds
			this.shellApi.triggerEvent("garbageOut");
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, garbageImpact, true));
		}
		
		private function garbageImpact():void {
			this.shellApi.triggerEvent("garbageHit");
		}
		
		private function setupFortressDoor():void
		{
			var door:Entity = super.getEntityById("doorFortress");
			var scenenteraction:SceneInteraction = door.get(SceneInteraction);
			var interaction:Interaction = door.get(Interaction);
			scenenteraction.offsetX = 0;
			interaction.click = new Signal();
			interaction.click.add(moveToFortressDoor);	
		}
		
		private function moveToFortressDoor(door:Entity):void {
			if(shellApi.checkEvent(_events.LOG_CUT_DOWN) && !shellApi.checkEvent(_events.BALANCE_GAME_COMPLETE)) {
				var targX:Number = door.get(Spatial).x - 20;
				var targY:Number = door.get(Spatial).y;
				CharUtils.moveToTarget(player, targX, targY, false, enterFortress);
			} else if(shellApi.checkEvent(_events.BALANCE_GAME_COMPLETE)) {
				Dialog(player.get(Dialog)).sayById("hope");
			} else {
				Dialog(player.get(Dialog)).sayById("getUpThere");
			}
		}
		
		private function enterFortress(entity:Entity):void {
			this.shellApi.triggerEvent("enterFortress");
			shellApi.loadScene(DiningHall);
		}
		
		private function setupMapDoor():void	{
			var door:Entity = super.getEntityById("doorMap");
			var scenenteraction:SceneInteraction = door.get(SceneInteraction);
			var interaction:Interaction = door.get(Interaction);
			scenenteraction.offsetX = 0;
			interaction.click = new Signal();
			interaction.click.add(moveToDoor);			
		}
		
		private function moveToDoor(door:Entity):void {
			var targX:Number = door.get(Spatial).x - 20;
			var targY:Number = door.get(Spatial).y;
			CharUtils.moveToTarget(player, targX, targY, false, openMap);
		}
		
		private function openMap(entity:Entity):void {
			var mapPopup:MapPopup = new MapPopup(overlayContainer);
			addChildGroup(mapPopup);
		}
	}
}




