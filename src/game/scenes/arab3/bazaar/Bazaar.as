package game.scenes.arab3.bazaar
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Cough;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Soar;
	import game.data.character.LookData;
	import game.data.comm.PopResponse;
	import game.data.ui.ToolTipType;
	import game.particles.FlameCreator;
	import game.scenes.arab3.Arab3Scene;
	import game.scenes.arab3.bazaar.tradePopup.TradePopup;
	import game.scenes.arab3.desertScope.DesertScope;
	import game.scenes.arab3.shared.DivinationTarget;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.RemoveEntityAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.TriggerEventAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	public class Bazaar extends Arab3Scene
	{
		private var jailer:Entity;
		private var trader1:Entity;
		private var trader2:Entity;
		private var trader3:Entity;	
		private var genie:Entity;
		
		private var genieHide:Entity;
		private var telescope:Entity;
		private var moonStoneInt:Entity;
		private var wishBoneInt:Entity;
		private var commonRoomTl:Entity;
		
		private var genietimer:TimedEvent;
		
		private var TRADER:String = "trader";
		private var sesameOilInt:Entity;
		private var camel:Entity;
		private var tradePopupOpen:Boolean;
		
		private const BARREL_SOUND:String = SoundManager.EFFECTS_PATH +"wood_impact_logs_01.mp3";
		private const POOF_SOUND:String = SoundManager.EFFECTS_PATH + "poof_02.mp3";
		private const FOUND:String = SoundManager.MUSIC_PATH + "genie_found.mp3";
		private var _flameCreator:FlameCreator;
		
		public function Bazaar()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{ 
			super.groupPrefix = "scenes/arab3/bazaar/";
			super.init( container );
		}
		
		override public function smokeReady():void
		{
			super.smokeReady();		
			shellApi.eventTriggered.add(handleEventTriggered);
			
			setupFire();
			
			commonRoomTl = EntityUtils.createMovingTimelineEntity(this, _hitContainer["commonRoomBlock"]);
			if(!PlatformUtils.isMobileOS){
				Timeline(commonRoomTl.get(Timeline)).gotoAndStop("night");
			}else{
				Timeline(commonRoomTl.get(Timeline)).gotoAndStop("nightClosed");
				removeEntity(getEntityById("doorCommon"));
			}			
			_numSpellTargets = 3;
			
			setupTraders();
			setupGenieHiding();
			setupEnding();			
		}
		
		private function handleEventTriggered(event:String, ...junk):void
		{
			if(event == _events.USE_COMPASS){
				jailerLeaves();
			}
			else if(event == "turn"){
				if(jailer && jailer.has(Display)){
					CharUtils.setDirection(jailer, true);
				}
			}
			else if(event.indexOf(TRADER) == 0)
			{
				var traderNumber:uint = uint(event.substring(TRADER.length));
				openTradePopup(traderNumber);
			}else if(event == "gotItem_"+_events.MOONSTONE){
				removeEntity(moonStoneInt);
				moonStoneInt = null;
			}
			else if(event == "gotItem_"+_events.SESAME_OIL){
				removeEntity(sesameOilInt);
				sesameOilInt = null;
			}
			else if(event == "gotItem_"+_events.WISHBONE){
				removeEntity(wishBoneInt);
				wishBoneInt = null;
			}
			else if(event == _events.GENIE_IN_PALACE){
				SceneUtil.addTimedEvent(this, new TimedEvent(3.0,1,camelLeaves));
			}
		}
		
		private function camelLeaves():void
		{
			if(camel){
				camel.add(new Sleep(false, true));
				SceneUtil.lockInput(this, true);
				SceneUtil.setCameraTarget(this, trader3);
				Dialog(trader3.get(Dialog)).sayById("camel_run");
				addSystem(new ThresholdSystem())
				var motion:Motion = camel.get(Motion);
				if( !motion )
				{
					motion = new Motion();
					camel.add( motion );
				}
				motion.velocity = new Point(-500,0);
				var spat:Spatial = camel.get(Spatial);
				spat.scaleX =- 1;
				var thresh:Threshold = new Threshold("x","<");
				thresh.threshold = -(spat.width + 1);
				thresh.entered.addOnce(removeCamel);
				camel.add(new Sleep(false,true));
				camel.add(thresh);
				Timeline(camel.get(Timeline)).gotoAndPlay("startrun");
				Display(camel.get(Display)).moveToFront();
			}
		}
		
		private function removeCamel():void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player);
			player.get(Dialog).sayById("where");
			removeEntity(camel);
		}
		
		private function jailerLeaves():void
		{
			if(!shellApi.checkEvent(_events.JAILER_LEFT)){
				var distx:Number = Math.abs(player.get(Spatial).x - jailer.get(Spatial).x);
				var disty:Number = Math.abs(player.get(Spatial).y - jailer.get(Spatial).y);
				if(distx < 250 && disty < 600){			
					CharUtils.moveToTarget(player, jailer.get(Spatial).x+70,jailer.get(Spatial).y,false,preJailerPosition);
				}else{
					Dialog(player.get(Dialog)).sayById("compassBazaar");
				}
			}
		}
		
		private function preJailerPosition(...p):void
		{
			trace("pos:"+EntityUtils.getPosition(player));
			SceneUtil.lockInput(this,true);
			EntityUtils.position(player,3270,405);
			CharUtils.stateDrivenOff(player);
			MotionUtils.zeroMotion(player);
			jailer.add(new Sleep(false, true));
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5,1,runJailerSeq));
		}
		
		private function runJailerSeq(...p):void
		{
			var dist:Number = GeomUtils.spatialDistance(player.get(Spatial),jailer.get(Spatial));
			if(dist < 400){
				EntityUtils.position(player,3270,405);
				var actions:ActionChain = new ActionChain(this);
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,false)));
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,false)));
				actions.addAction(new TalkAction(player,"compass"));
				actions.addAction(new RemoveItemAction(_events.COMPASS,"jailer",true,false));
				actions.addAction(new TalkAction(jailer,"twist"));
				actions.addAction(new TalkAction(jailer,"give_key"));
				actions.addAction(new GetItemAction(_events.SKELETON_KEY,true));
				actions.addAction(new SetSkinAction(jailer, SkinUtils.ITEM, "empty"));
				actions.addAction(new MoveAction(jailer, new Point(3650, 1550)));
				actions.addAction(new CallFunctionAction(finalizeSequence));
				actions.execute(unlock);
			}else{
				unlock()
			}
		}
		
		private function finalizeSequence():void
		{
			shellApi.removeItem(_events.COMPASS);
			shellApi.completeEvent(_events.JAILER_LEFT);
		}
		
		private function unlock(...p):void
		{
			CharUtils.stateDrivenOn(player);
			SceneUtil.lockInput(this,false);
		}
		
		private function setupGenieHiding():void
		{
			genie = getEntityById("genie");
			Display(genie.get(Display)).visible = false;
			ToolTipCreator.removeFromEntity(genie);
			genieHide = EntityUtils.createMovingTimelineEntity(this, _hitContainer["genieBarrel"]);
			// genie in crate
			if(shellApi.checkHasItem(_events.DRAWING) && !shellApi.checkEvent(_events.GENIE_IN_BAZAAR)){
				shellApi.completeEvent(_events.GENIE_IN_BAZAAR);
			}
			
			if(shellApi.checkEvent(_events.GENIE_IN_PALACE) || shellApi.checkEvent(_events.GENIE_IN_DESERT)){
				// not there	
				Timeline(genieHide.get(Timeline)).gotoAndStop("start");
				removeEntity(genie);
			}
			else if(shellApi.checkEvent(_events.GENIE_IN_BAZAAR)){
				var inter:Interaction = InteractionCreator.addToEntity(genieHide, [InteractionCreator.CLICK]);
				inter.click.add(clickedBarrel);
				ToolTipCreator.addToEntity(genieHide);
				geniePeek();
				Timeline(genieHide.get(Timeline)).handleLabel("peeking", hidePuff, false);
				var divination:DivinationTarget = new DivinationTarget();
				divination.response.addOnce(hitGenie);
				genie.add(divination);	
			}
			else{
				// not there	
				Timeline(genieHide.get(Timeline)).gotoAndStop("start");
				removeEntity(genie);
			}
			
			if(shellApi.checkEvent(_events.SULTAN_MADE_WISH)){
				removeEntity(genieHide);
			}
		}	
		
		private function clickedBarrel(...p):void
		{
			Dialog(player.get(Dialog)).sayById("click_barrel");
		}
		
		private function hidePuff():void
		{
			//_smokePuffGroup.poofAt(genieHide, 0.2);
		}
		
		private function geniePeek(...p):void
		{
			AudioUtils.playSoundFromEntity(genieHide, BARREL_SOUND, 700, 0.3 , 1.5, Linear.easeInOut);
			Timeline(genieHide.get(Timeline)).gotoAndPlay("start");
			Timeline(genieHide.get(Timeline)).handleLabel("end", geniePeekDelay);
		}
		
		private function geniePeekDelay():void
		{
			if(genietimer){
				genietimer.stop()
			}
			genietimer = SceneUtil.addTimedEvent(this, new TimedEvent(4.0,1,geniePeek));
		}		
		
		private function hitGenie(bomb:Entity):void
		{
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput=true;
			actions.addAction(new WaitAction(0.9));
			actions.addAction(new CallFunctionAction(showGenie));
			actions.addAction(new WaitAction(0.3));
			actions.addAction(new AnimationAction(genie, Cough, "", 50, true));
			actions.addAction(new TalkAction(genie, "run"));
			actions.addAction(new CallFunctionAction(genieLeavesForPalace));
			actions.addAction(new WaitAction(1.0));
			actions.addAction(new PanAction(player));
			actions.addAction(new TriggerEventAction(_events.GENIE_IN_PALACE,true));
			actions.execute();
		}
		
		private function showGenie():void
		{
			AudioUtils.play(this, FOUND,1.2,false,null,null,1.2);
			AudioUtils.playSoundFromEntity(genie, POOF_SOUND, 600, 0.2);
			EntityUtils.positionByEntity(genie,genieHide);
			genie.get(Spatial).y -= 100;
			_smokePuffGroup.poofAt(genie,0.6);
			genie.get(Display).visible = true;
			Timeline(genieHide.get(Timeline)).gotoAndStop("start");
			if(genietimer){
				genietimer.stop();
			}
			
			Interaction( genieHide.get( Interaction )).click.removeAll();
			ToolTipCreator.removeFromEntity( genieHide );
			var clip:MovieClip = Display( genieHide.get( Display )).displayObject as MovieClip;
			clip.mouseEnabled = false;
			clip.mouseChildren = false;
			
			super.addGenieWaveMotion(genie);
		}
		private function genieLeavesForPalace(...p):void
		{
			var speed:Number = 800;
			var target:Point = new Point(-100, 500);
			var spatial:Spatial = genie.get(Spatial);
			var time:Number = GeomUtils.dist(target.x,target.y, spatial.x, spatial.y) / speed;
			CharUtils.setAnim(genie, Soar);
			CharUtils.setDirection(genie, false);
			TweenUtils.entityTo( genie, Spatial, time, {x:target.x, y:target.y, ease:Back.easeIn, onComplete:Command.create(removeEntity,genie)});
			genie.add(new Sleep(false, true));
			
			shellApi.completeEvent(_events.GENIE_IN_PALACE);
		}
		
		// daytime state
		private function setupEnding():void
		{
			if(shellApi.checkEvent(_events.SULTAN_MADE_WISH)){
				// common room door
				if(!PlatformUtils.isMobileOS){
					Timeline(commonRoomTl.get(Timeline)).gotoAndStop("day");
				}else{
					Timeline(commonRoomTl.get(Timeline)).gotoAndStop("dayClosed");
					removeEntity(getEntityById("doorCommon"));
				}
				removeEntity(getEntityById("backdropNight"));
				removeEntity(getEntityById("backgroundNight"));
				removeEntity(getEntityById("foregroundNight"));
				removeEntity(getEntityById("doorDesert"));
				removeEntity(getEntityById("doorPalace"));
				removeEntity(sesameOilInt);
				sesameOilInt=null;
				removeEntity(moonStoneInt);
				moonStoneInt=null;
				removeEntity(wishBoneInt);
				wishBoneInt=null;
				if(!shellApi.checkHasItem(_events.MEDAL)){
					EntityUtils.position(player, 500, 1530);
					CharUtils.setDirection(player, true);
					var sultan:Entity = getEntityById("sultan");
					var thief:Entity = getEntityById("thief");
					var actions:ActionChain = new ActionChain(this);
					actions.lockInput = true;
					actions.addAction(new TalkAction(sultan, "blind"));
					actions.addAction(new TalkAction(thief, "thanks"));
					actions.addAction(new TalkAction(sultan, "giveMedal"));
					actions.addAction(new CallFunctionAction(this.completeIsland));
					actions.execute();
				}
			}
		}
		
		private function completeIsland():void
		{
			shellApi.completedIsland('', onCompletions);
		}
		
		private function onCompletions(response:PopResponse):void
		{
			var islandEndPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer)
			islandEndPopup.closeButtonInclude = true;
			this.addChildGroup( islandEndPopup );
		}
		
		private function setupTraders():void
		{
			jailer = getEntityById("jailer");
			setupTelescope();
			if(shellApi.checkEvent(_events.JAILER_LEFT)){
				removeEntity(jailer);
			}
			var inter:SceneInteraction;
			trader1 = getEntityById("trader1");
			trader2 = getEntityById("trader2");
			// camel man
			trader3 = getEntityById("trader3");
			super.loadFile( "camel.swf", setUpCamel);
			
			if( !shellApi.checkItemEvent( _events.CRYSTALS ))
			{
				Dialog( trader1.get( Dialog )).setCurrentById( "no_items" );
				Dialog( trader2.get( Dialog )).setCurrentById( "no_items" );
				Dialog( trader3.get( Dialog )).setCurrentById( "no_items" );
			}
			
			wishBoneInt = getEntityById("wishboneInteraction");
			if(!shellApi.checkHasItem(_events.WISHBONE) && !shellApi.checkHasItem(_events.BONE_MEAL)){
				inter = wishBoneInt.get(SceneInteraction);
				inter.reached.add(Command.create(comment, trader1));
			}
			else{
				removeEntity(wishBoneInt);
				wishBoneInt = null;
			}
			
			moonStoneInt = getEntityById("moonstoneInteraction");	
			if(!shellApi.checkHasItem(_events.MOONSTONE) && !shellApi.checkHasItem(_events.MOON_DUST)){
				inter = moonStoneInt.get(SceneInteraction);
				inter.reached.add(Command.create(comment, trader2));
			}
			else{
				removeEntity(moonStoneInt);
				moonStoneInt = null;
			}
			
			sesameOilInt = getEntityById("sesame_oilInteraction");	
			if(!shellApi.checkHasItem(_events.SESAME_OIL)){
				inter = sesameOilInt.get(SceneInteraction);
				inter.reached.add(Command.create(comment, trader3));
			}
			else{
				removeEntity(sesameOilInt);
				sesameOilInt = null;
			}
		}
		
		private function comment(player:Entity, item:Entity, trader:Entity):void
		{
			Dialog( trader.get( Dialog )).sayById( "comment" );
		}
		
		private function openTradePopup(traderNumber:uint):void
		{
			if(!tradePopupOpen){
				var trader:Entity = getEntityById(TRADER + traderNumber);
				var look:LookData = SkinUtils.getLook(trader);
				var popup:TradePopup = addChildGroup(new TradePopup(overlayContainer, traderNumber, look)) as TradePopup;
				popup.ready.addOnce(waitForTradeLoad);
				popup.removed.addOnce(setTradeClosed);
				SceneUtil.lockInput(this, true);
			}
		}
		
		private function setTradeClosed(...p):void
		{
			this.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
			tradePopupOpen = false;
		}
		
		private function waitForTradeLoad(...p):void
		{
			tradePopupOpen = true;
			SceneUtil.lockInput(this, false);
		}
		
		private function setUpCamel(camelClip:MovieClip):void
		{
			var camelPlat:Entity = getEntityById("camelPlat");
			// camel hangs out until genie is chased out
			if((!shellApi.checkEvent(_events.GENIE_IN_PALACE) && !shellApi.checkEvent(_events.GENIE_IN_DESERT)) || shellApi.checkEvent(_events.SULTAN_MADE_WISH)){
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					camel = EntityUtils.createSpatialEntity(this, camelClip["avatar"], _hitContainer);
					camel = BitmapTimelineCreator.convertToBitmapTimeline(camel,null,true,null,PerformanceUtils.defaultBitmapQuality + 0.4);
				}
				else{
					camel = EntityUtils.createMovingTimelineEntity(this, camelClip["avatar"], _hitContainer, true);
				}
				var spatial:Spatial = camel.get(Spatial);
				spatial.x = trader3.get(Spatial).x + 200;
				spatial.y = trader3.get(Spatial).y - 60;
				if(shellApi.checkEvent(_events.SULTAN_MADE_WISH))
				{
					spatial.y += 15;
					var camelPlatform:Entity = super.getEntityById("camelPlat");
					Spatial(camelPlatform.get(Spatial)).y += 20;
				}
				trace("CAMEL: "+spatial.x+","+spatial.y)
				spatial.scaleX *= -1;
				Timeline(camel.get(Timeline)).gotoAndPlay("idle");
				var inter:Interaction =	InteractionCreator.addToEntity(camel, [InteractionCreator.CLICK]);
				inter.click.add(camelComment);
				ToolTipCreator.addToEntity(camel);
				var display:Display = camel.get(Display);
				display.enableMouse();
				display.moveToBack();
				camelPlat.get(Display).visible = false;
			}else{
				removeEntity(camelPlat);
			}
		}
		
		private function camelComment(...p):void
		{
			if(shellApi.checkEvent(_events.SULTAN_MADE_WISH)){
				var camelP:Point = EntityUtils.getPosition(camel);
				camelP.x -= 150;
				camelP.y += 50;
				var actions:ActionChain = new ActionChain(this);
				
				actions.lockInput = true;
				
				actions.addAction(new MoveAction(player, camelP, new Point(50,100),NaN, true));
				actions.addAction(new CallFunctionAction(Command.create(EntityUtils.position,player,camelP.x,camelP.y+50)));
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection, player, true)));
				actions.addAction(new TalkAction(player, "camel"));
				actions.addAction(new AnimationAction(player, Score));
				actions.addAction(new WaitAction(0.1));
				actions.addAction(new TimelineAction(camel,"lick"));
				actions.addAction(new TalkAction(player, "ewww"));
				actions.addAction(new TimelineAction(camel,"idle","ending",false)).noWait = true;
				
				actions.execute();
			}
			else{
				Dialog(trader3.get(Dialog)).sayById("returned");
			}
		}
		
		private function setupTelescope():void
		{			
			Display(jailer.get(Display)).moveToBack();
			telescope = getEntityById("spyGlassInteraction");
			var inter:SceneInteraction = telescope.get(SceneInteraction);
			inter.reached.add(useTelescope);
			if(shellApi.checkEvent(_events.USED_SPYGLASS)){
				var prev:String = shellApi.sceneManager.previousScene;
				if(prev == "game.scenes.arab3.desertScope::DesertScope"){
					player.get(Dialog).sayById("spyglass");
				}
				removeEntity(jailer);
			}
		}
		
		private function useTelescope(...p):void
		{
			if(shellApi.checkEvent(_events.JAILER_LEFT)){
				if(shellApi.checkEvent(_events.SULTAN_MADE_WISH)){
					Dialog(player.get(Dialog)).sayById("spyglass2");
				}else{
					shellApi.loadScene(DesertScope);
				}
			}
			else{
				Dialog(jailer.get(Dialog)).sayById("use_spyglass");
			}
		}		
		
		private function setupFire():void
		{
			if(!shellApi.checkEvent(_events.SULTAN_MADE_WISH) && !PlatformUtils.isMobileOS){
				_flameCreator = new FlameCreator();
				_flameCreator.setup( this, _hitContainer[ "fire" + 0 ], null, onFlameLoaded );
			}else{
				for( var i:uint = 0; _hitContainer[ "fire" + i ] != null; i++ )
				{
					_hitContainer.removeChild(_hitContainer[ "fire" + i ]);
				}
				for(i = 1; _hitContainer[ "lantern_" + i ] != null; i++ )
				{
					_hitContainer.removeChild(_hitContainer[ "lantern_" + i ]);
				}
			}
		}
		
		private function onFlameLoaded():void
		{
			var clip:MovieClip;
			var flame:Entity;
			var lantern:Entity;
			for( var i:uint = 0; _hitContainer[ "fire" + i ] != null; i ++ )
			{
				clip = _hitContainer[ "fire" + i ];
				flame = _flameCreator.createFlame( this, clip, true );
				if(_hitContainer[ "lantern_" + i ] != null){
					clip = _hitContainer[ "lantern_" + i ];
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
						BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
					}
					lantern = EntityUtils.createSpatialEntity(this, clip);
					DisplayUtils.moveToBack(EntityUtils.getDisplayObject(lantern));
					DisplayUtils.moveToBack(EntityUtils.getDisplayObject(flame));
				}
			}
		}
		
	}
}