package game.scenes.viking.beach
{
	import com.greensock.easing.Sine;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Skin;
	import game.components.motion.Destination;
	import game.components.motion.TargetEntity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Shovel;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Stomp;
	import game.data.animation.entity.character.Throw;
	import game.data.animation.entity.character.Wave;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.comm.PopResponse;
	import game.data.display.BitmapWrapper;
	import game.data.game.GameEvent;
	import game.scene.template.ItemGroup;
	import game.scenes.viking.VikingScene;
	import game.scenes.viking.beach.particles.SandDiggingParticles;
	import game.scenes.viking.shared.DodoGroup;
	import game.ui.hud.Hud;
	import game.ui.inventory.Inventory;
	import game.ui.popup.IslandEndingPopup;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;
	
	public class Beach extends VikingScene
	{
		private var completionsUpdated:Boolean;
		private var endingPopupWaiting:Boolean;
		private var sand:Entity;
		private var mya:Entity;
		private var oliver:Entity;
		private var jorge:Entity;
		private var octavian:Entity;
		private var sandScale:Number = 1;
		private var candyBar:Entity;
		private var candyBarThrow:Entity;
		private var map:Entity;
		
		private var dodoGroup:DodoGroup;
		private var crab:Entity;
		private var crabStartX:Number;
		
		private var sandOn:Boolean = false;
		
		private var frustration:Boolean = false;
		private var _waitingForCandy:Boolean = false;
		private var pickedItem:String = "nothing"; // states: candybar, other, nothing

		private var savedTargetEntity:TargetEntity;
		private var savedTarget:Spatial;

		public function Beach()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/beach/";
			
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
			
			setupCrab();
			
			if(shellApi.checkEvent(_events.RIVER_COMPLETED)){ 
				mya = this.getEntityById("mya");
				oliver = this.getEntityById("oliver");
				jorge = this.getEntityById("jorge");
				octavian = this.getEntityById("octavian");
				super.getEntityById( "foreground" ).get( Display ).displayObject.addChild(_hitContainer["log"]);
				if(!shellApi.checkEvent(GameEvent.GOT_ITEM + _events.MEDAL_VIKING)){
					if(!shellApi.checkHasItem(_events.CANDYBAR)) {
						shellApi.getItem(_events.CANDYBAR);
					}
					CharUtils.lockControls(player);
					SceneUtil.lockInput(this, true);
					
					player.get(Spatial).x = 2100;
					player.get(Spatial).y = 1020;	
					CharUtils.setDirection(player, false);
					
					//Dialog(player.get(Dialog)).sayById("farEnough");
					dodoGroup = new DodoGroup();
					
					var hand:Entity = Skin( octavian.get( Skin )).getSkinPartEntity( "hand1" );
					var handDisplay:Display = hand.get( Display );
					candyBar = EntityUtils.createSpatialEntity(this, _hitContainer["candyBar"], handDisplay.displayObject);
					candyBar.get(Spatial).x = 0;
					candyBar.get(Spatial).y = 0;
					candyBar.get(Spatial).scaleX = -.4;
					candyBar.get(Spatial).scaleY = .4;
					candyBar.get(Spatial).rotation = -100;
					DisplayObject(candyBar.get(Display).displayObject).parent.setChildIndex(candyBar.get(Display).displayObject, 0);
					candyBar.get(Display).visible = false;
					
					candyBarThrow = EntityUtils.createSpatialEntity(this, _hitContainer["candyBarThrow"], _hitContainer);
					candyBarThrow.get(Display).visible = false;
					
					map = EntityUtils.createSpatialEntity(this, _hitContainer["map"], _hitContainer);
					map.get(Display).visible = false;
					var mapWrapper:BitmapWrapper = DisplayUtils.convertToBitmap(_hitContainer["map"]["map"]);
					if( !AppConfig.mobile ){
						mapWrapper.bitmap.smoothing = true;
					}
					
					DisplayUtils.moveToTop(crab.get(Display).displayObject);
					DisplayUtils.moveToTop(mya.get(Display).displayObject);
					DisplayUtils.moveToTop(jorge.get(Display).displayObject);
					savedTarget = player.get(TargetEntity).target;
					savedTargetEntity = player.get(TargetEntity);
					player.get(TargetEntity).target = null;
					//player.remove(TargetEntity);
					CharUtils.moveToTarget(player, 1826, 1022, true, farEnough, new Point(10, 10));
					CharUtils.moveToTarget(mya, 1992, 1107, false);
					CharUtils.moveToTarget(oliver, 1942, 1080, false);
					CharUtils.moveToTarget(jorge, 1909, 1105, false);
					
					this._hitContainer["dodoTarget1"].x -= 400;
					this._hitContainer["dodoTarget2"].x -= 400;
					this._hitContainer["dodoTarget3"].x -= 400;
					this._hitContainer["dodoTarget4"].x -= 400;
					this._hitContainer["dodoTarget5"].x -= 400;
					setupDodos();
					setupDoorBlock();
					setupDodoClick();
				} else {
					_hitContainer["candyBar"].visible = false;
					_hitContainer["candyBarThrow"].visible = false;
					_hitContainer["map"].visible = false;
					_hitContainer["boat"].visible = false;
					this.removeEntity(octavian);
					this.removeEntity(this.getEntityById("dodo1"));
					this.removeEntity(this.getEntityById("dodo2"));
					this.removeEntity(this.getEntityById("dodo3"));
					this.removeEntity(this.getEntityById("dodo4"));
					//this.removeEntity(this.getEntityById("dodo5"));
					this.removeEntity(this.getEntityById("oliver"));
					this.removeEntity(this.getEntityById("mya"));
					this.removeEntity(this.getEntityById("jorge"));
				}
			} else {
				_hitContainer["candyBar"].visible = false;
				_hitContainer["candyBarThrow"].visible = false;
				_hitContainer["map"].visible = false;
				_hitContainer["boat"].visible = false;
				_hitContainer["log"].visible = false;
			}
			
			setupSand();
			
		}
		
		private function farEnough(entity:Entity):void 
		{
			CharUtils.setDirection( player, false );
			Dialog(player.get(Dialog)).sayById("farEnough");
			
			//CharUtils.lockControls(player, false, false);
			//SceneUtil.lockInput(this, false);
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void 
		{	
			if( _waitingForCandy )
			{
				if(event.indexOf("use") != -1)
				{
					if(event.indexOf(_events.CANDYBAR) != -1)
					{
						pickedItem = _events.CANDYBAR;
					}
					else
					{
						pickedItem = "other";
					}
				}
			}
			else
			{
				var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
				if( event == "get_axe" ) {
					var clip:MovieClip = _hitContainer["axe"];
					clip.visible = false;
					SceneUtil.lockInput(this, false);
					shellApi.getItem(_events.AXE, null, true );
				} else if ( event == "shovel_used" ) {
					if(shellApi.checkItemEvent(_events.AXE)){ 
						Dialog(player.get(Dialog)).sayById("nothing_to_dig");
					}else{
						SceneUtil.lockInput(this, true);
						var destination2:Destination = CharUtils.moveToTarget(player, 1486, 1028, false, prepareToShovel);
						destination2.ignorePlatformTarget = true;
					}
				} else if ( event == "octavian_laugh" ) {
					CharUtils.setAnim(octavian, Laugh, false);
					SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, sayNotMyConcern, true));
				} else if ( event == "inconvenient" ) {
					SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, sayInconvenientLine, true));
					SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, setOctavianLeft, true));
				} else if ( event == "let_player_use_candy" ) {
					(player.get(Dialog) as Dialog).blockTriggerEvents = true; // block player dialog so they don't say default comment connected to item use
					_waitingForCandy = true;
					openInventory();	//auto open inventory
				} else if ( event == "get_away" ) {
					carryOctavianAway();
				} else if ( event == "pick_up_map" ) {
					var targX:Number = map.get(Spatial).x + 60;
					var targY:Number = map.get(Spatial).y;
					CharUtils.moveToTarget(mya, targX, targY, false, pickupMap);
				} else if ( event == "player_turn" ) {
					CharUtils.setDirection(player, true);
					Dialog(jorge.get(Dialog)).sayById("comeWithUs");
				} 
				else if ( event == "give_medal" ) 
				{
					//player.get(TargetEntity).target = savedTarget;
					CharUtils.lockControls(player, false, false);
					SceneUtil.lockInput(this, false);
					shellApi.completedIsland( "", onCompletions);
					
					if( !shellApi.checkEvent( GameEvent.HAS_ITEM + _events.MEDAL_VIKING ))
					{
						shellApi.getItem( _events.MEDAL_VIKING, null, true, takePhoto );
					}
					else
					{
						takePhoto();
					}
				}
			}
		}
		
		private function openInventory(...p):void
		{
			// force open inventory, respond to used_'wrong'item with sultan rejecting it and then reopen inventory
			var hud:Hud = super.getGroupById( Hud.GROUP_ID ) as Hud;
			var inventory:Inventory = hud.openInventory();
			inventory.removed.addOnce(inventoryClosed);
			inventory.pauseParent = true;
			inventory.ready.addOnce(unlock);
			pickedItem = "nothing";
		}
		
		private function inventoryClosed(...p):void
		{
			SceneUtil.lockInput(this, true);
			if(pickedItem == "other"){
				var oliverDial:Dialog = oliver.get(Dialog);
				oliverDial.sayById("wrongItem");
				oliverDial.complete.removeAll();
				oliverDial.complete.addOnce(wrongEndingItem);
			}
			else if(pickedItem == "nothing"){
				var jorgeDial:Dialog = jorge.get(Dialog);
				jorgeDial.sayById("noItem");
				jorgeDial.complete.removeAll();
				jorgeDial.complete.addOnce(wrongEndingItem);
			}
			else if(pickedItem == _events.CANDYBAR){
				_waitingForCandy = false;
				(player.get(Dialog) as Dialog).blockTriggerEvents = false;
				SceneUtil.addTimedEvent(this, new TimedEvent(0.6,1,usedCandyBar));
			}
		}
		
		private function wrongEndingItem(...p):void
		{
			var myaDial:Dialog = mya.get(Dialog);
			myaDial.sayById("tryAgain");
			myaDial.complete.removeAll();
			myaDial.complete.addOnce(openInventory);
		}
		
		private function usedCandyBar():void
		{
			CharUtils.lockControls(player);
			SceneUtil.lockInput(this, true);
			
			//player.get(TargetEntity).target = null;
			//var destination:Destination = CharUtils.moveToTarget(player, 1826, 1022, true, waitToThrowCandy);
			//destination.ignorePlatformTarget = true;
			
			frustration = false;
			setOctavianRight();
			CharUtils.setAnim(octavian, Stand, false);
			
			waitToThrowCandy();
		}

		private function unlock(popup:Inventory):void
		{
			SceneUtil.lockInput(popup, false);
		}

		private function onCompletions(response:PopResponse = null):void
		{
			completionsUpdated = true;
			if (endingPopupWaiting) {
				showEndingPopup();
			}
		}
		
		private function takePhoto(...args):void
		{
			this.shellApi.takePhoto("13481", showEndingPopup);
		}
		
		private function showEndingPopup():void
		{
			if (completionsUpdated) {
				var islandEndPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer)
				islandEndPopup.closeButtonInclude = false;
				this.addChildGroup( islandEndPopup );
				//completeIsland();
			} else {
				endingPopupWaiting = true;
			}
			// guessing that this is not wanted anymore _RAM
			//			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, reloadScene, true));
		}
		
		private function completeIsland( ...args ):void
		{
			DisplayUtils.moveToTop(oliver.get(Display).displayObject);
			DisplayUtils.moveToTop(mya.get(Display).displayObject);
			DisplayUtils.moveToTop(jorge.get(Display).displayObject);
			Dialog(mya.get(Dialog)).setCurrentById("postMedal");
			Dialog(oliver.get(Dialog)).setCurrentById("postMedal");
			Dialog(jorge.get(Dialog)).setCurrentById("postMedal");
			
			Npc(oliver.get(Npc)).ignoreDepth = true;
			Npc(mya.get(Npc)).ignoreDepth = true;
			Npc(jorge.get(Npc)).ignoreDepth = true;
		}
		
		private function waitForFade():void {
			this.screenEffects.fadeToBlack(0.8, Command.create(reloadScene));
		}
		
		private function reloadScene():void {
			this.shellApi.loadScene(Beach, 2100, 1020, "right");
		}
		
		private function sayNotMyConcern():void {
			Dialog(octavian.get(Dialog)).sayById("myConcern");
			this.getEntityById("target1").get(Spatial).x += 400;
			this.getEntityById("target2").get(Spatial).x += 400;
			this.getEntityById("target3").get(Spatial).x += 400;
			this.getEntityById("target4").get(Spatial).x += 400;
			this.getEntityById("target5").get(Spatial).x += 400;
		}
		
		private function pickupMap(entity:Entity):void {
			CharUtils.setDirection(mya, false);
			CharUtils.setAnim(mya, Place, false);
			SceneUtil.addTimedEvent(this, new TimedEvent(.7, 1, removeMap, true));
		}
		
		private function removeMap():void {
			this.removeEntity(map);
			CharUtils.setDirection(mya, true);
		}
		
		private function waitToThrowCandy(entity:Entity=null):void {
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, throwCandy, true));
			//MotionUtils.zeroMotion(super.player);
			//CharUtils.setDirection(player, false);
		}
		
		private function throwCandy():void {
			Dialog(player.get(Dialog)).sayById("catch");
			//MotionUtils.zeroMotion(super.player);
			CharUtils.setDirection(player, false);
			CharUtils.setAnim(player, Throw, false);
			CharUtils.setAnim(octavian, Wave, false);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, sayGross, true));
			dodoGroup.clusterAllDodos(this, octavian, 40, 0, true);
			
			candyBarThrow.get(Display).visible = true;
			TweenUtils.globalTo(this, candyBarThrow.get(Spatial), 1, {x:1593, rotation:100, ease:Sine.easeInOut}, "candy_throw");
			TweenUtils.globalTo(this, candyBarThrow.get(Spatial), 0.5, {y:900, ease:Sine.easeInOut, onComplete:moveCandyDown}, "candy_throw_y");
		}
		
		private function moveCandyDown():void {
			TweenUtils.globalTo(this, candyBarThrow.get(Spatial), 0.5, {y:1000, ease:Sine.easeInOut}, "candy_throw_y");
		}
		
		private function removeCandyBarThrow():void {
			candyBarThrow.get(Display).visible = false;
			shellApi.removeItem(_events.CANDYBAR);
		}
		
		private function setupDodos():void {
			var offsets:Array = [80, 60, 10, 300, 300];
			var offsetChangeTimes:Array = [0.5, 1, 1, 2, 2];
			
			var index:int;
			
			for(index = 5; index > 0; --index) {
				var target:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["dodoTarget" + index]);
				target.add(new Id("target"+index));
				var dodo:Entity = this.getEntityById("dodo" + index);
				
				if(PlatformUtils.isMobileOS) {
					ToolTipCreator.removeFromEntity(dodo);
				}
				
				dodoGroup.clusterDodo(this, dodo, target, offsets[index - 1], offsetChangeTimes[index - 1]);
				if(octavian.get(Display).container.getChildIndex(octavian.get(Display).displayObject) > dodo.get(Display).container.getChildIndex(dodo.get(Display).displayObject)){
					octavian.get(Display).container.swapChildren(octavian.get(Display).displayObject, dodo.get(Display).displayObject);
				}
			}
		}
		
		private function sayGross():void {
			removeCandyBarThrow();
			candyBar.get(Display).visible = true;
			Dialog(octavian.get(Dialog)).sayById("gross");
		}
		
		private function carryOctavianAway():void {
			CharUtils.moveToTarget(octavian, 264, 1027, false, finalDialog);
			Dialog(octavian.get(Dialog)).sayById("aiee");
			Sleep(octavian.get(Sleep)).ignoreOffscreenSleep = true;
			SceneUtil.setCameraTarget(this, octavian);
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, mapFall, true));
		}
		
		private function mapFall():void {
			map.get(Spatial).x = octavian.get(Spatial).x;
			map.get(Spatial).y = octavian.get(Spatial).y;
			map.get(Display).visible = true;
			TweenUtils.globalTo(this,map.get(Spatial),0.6,{x:1602, y:1061, rotation:-12},"map_fall");
			crabStartX -= 100;
			moveCrab();
			crabStartX -= 100;
		}
		
		private function finalDialog(entiti:Entity):void {
			SceneUtil.setCameraTarget(this, player);
			this.removeEntity(octavian);
			Dialog(jorge.get(Dialog)).sayById("lastBit");
			
			var index:int;
			for(index = 5; index > 0; --index) {
				this.removeEntity(this.getEntityById("dodo" + index));
			}
		}
		
		private function setOctavianLeft():void {
			CharUtils.setDirection(octavian, false);
			//var fourDigs:Vector.<Class> = new Vector.<Class>();
			//fourDigs.push(Stomp, BigStomp, Grief);
			//CharUtils.setAnimSequence(octavian, fourDigs);
		}
		
		private function setOctavianRight():void {
			CharUtils.setDirection(octavian, true);
		}
		
		private function startFrustrationSequence():void {
			var delay:Number = Utils.randNumInRange(2, 4);
			SceneUtil.addTimedEvent(this, new TimedEvent(delay, 1, showFrustration, true));
		}
		
		private function showFrustration():void {
			if(frustration) {
				var num:Number = Utils.randInRange(0, 2);
				trace("NUM = "+num);
				switch(num) {
					case 0:
						CharUtils.setAnim(octavian, Stomp, false);
						break;
					case 1:
						CharUtils.setAnim(octavian, Grief, false);
						break;
					case 2:
						octavian.get(Spatial).scaleX *= -1;
						break;
				}
				startFrustrationSequence();
			}
		}
		
		private function sayInconvenientLine():void {
			setOctavianRight();
			Dialog(octavian.get(Dialog)).sayById("inconvenient");
			frustration = true;
			startFrustrationSequence();
		}
		
		private function setupCrab():void {
			crab = EntityUtils.createSpatialEntity(this, _hitContainer["crab"], _hitContainer);
			BitmapTimelineCreator.convertToBitmapTimeline(crab);
			crab.get(Timeline).gotoAndPlay("idle");
			crabStartX = crab.get(Spatial).x;
			getTimeForMoveCrab();
		}
		
		private function getTimeForMoveCrab():void {
			var delay:Number = Utils.randNumInRange(3, 7);
			SceneUtil.addTimedEvent(this, new TimedEvent(delay, 1, moveCrab, true));
		}
		
		private function moveCrab():void {
			crab.get(Timeline).gotoAndPlay("walking");
			getTimeForMoveCrab();
			var minX:Number = crabStartX - 250;
			var maxX:Number = crabStartX + 250;
			var targX:Number = Utils.randNumInRange(minX, maxX);
			TweenUtils.globalTo(this,crab.get(Spatial),1,{x:targX, ease:Sine.easeInOut},"crab_walk");
		}
		
		private function setupSand():void
		{
			var sandClick:MovieClip = _hitContainer["sandClick"];
			if(shellApi.checkHasItem(_events.AXE))
			{
				_hitContainer.removeChild(_hitContainer["sand"]);
				_hitContainer.removeChild(_hitContainer["axe"]);
				_hitContainer.removeChild(sandClick);
			}
			else
			{
				var clip:MovieClip = _hitContainer["sand"];
				
				sand = new Entity();
				
				var spatial:Spatial = new Spatial();
				spatial.x = clip.x;
				spatial.y = clip.y;
				
				sand.add(spatial);
				sand.add(new Display(clip));
				sand.add(new Id("sand"));
				
				super.addEntity(sand);
				
				//click for sandClick
				var sandClickEntity:Entity = ButtonCreator.createButtonEntity(sandClick, this, clickSand);
				sandClickEntity.get(Display).alpha = 0;
				sandClickEntity.add(new Id("sandClick"));
			}
		}
		
		private function clickSand(entity:Entity):void
		{
			SceneUtil.lockInput(this, true);
			var destination:Destination = CharUtils.moveToTarget(player, 1558, 1033, false, sayBareHands);
			destination.ignorePlatformTarget = true;
		}
		
		private function sayBareHands(entity:Entity):void {
			SceneUtil.lockInput(this, false);
			Dialog(player.get(Dialog)).sayById("bareHands");
		}
		
		private function prepareToShovel(entity:Entity):void {
			CharUtils.setDirection(player, true);
			
			var lookData:LookData = new LookData();
			lookData.applyAspect( new LookAspectData( SkinUtils.ITEM, "comic_shovel" ) );
			SkinUtils.applyLook( player, lookData, false );
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, shovelSand, true));
		}
		
		private function shovelSand(entity:Entity=null):void {
			
			var fourDigs:Vector.<Class> = new Vector.<Class>();
			fourDigs.push(Shovel, Shovel, Shovel, Shovel);
			CharUtils.setAnimSequence(player, fourDigs);
			
			Timeline(player.get(Timeline)).handleLabel("shovel", swingShovel, false);
			Timeline(player.get(Timeline)).handleLabel("reset", resetShovel, false);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(6, 1, removeSand, true));
			shellApi.triggerEvent("digging");
		}
		
		private function swingShovel(entity:Entity=null):void {
			var hand:Entity = Skin( shellApi.player.get( Skin )).getSkinPartEntity( "item" );
			var handSpatial:Spatial = hand.get( Spatial );
			TweenUtils.globalTo(this,handSpatial,0.3,{rotation:-20},"shovel_rot");
			if(!sandOn)
			{
				sandOn = true;
				var sandEmitter:SandDiggingParticles = new SandDiggingParticles();
				sandEmitter.init();
				var sandEntity:Entity = EmitterCreator.create(this, super._hitContainer, sandEmitter, 15, 30, player, "sandEntity", player.get(Spatial));
				sandEntity.add(new Id("sandEntity"));
			}
		}
		
		private function resetShovel(entity:Entity=null):void {
			var hand:Entity = Skin( shellApi.player.get( Skin )).getSkinPartEntity( "item" );
			var handSpatial:Spatial = hand.get( Spatial );
			TweenUtils.globalTo(this,handSpatial,0.3,{rotation:50},"shovel_rot2");
			sandScale -= 0.25;
			TweenUtils.globalTo(this,sand.get(Spatial),0.3,{scaleY:sandScale},"sand_scale");
			shellApi.triggerEvent("dig");
		}
		
		private function removeSand():void {
			var lookData:LookData = new LookData();
			lookData.applyAspect( new LookAspectData( SkinUtils.ITEM, "empty" ) );
			SkinUtils.applyLook( player, lookData, false );
			
			this.removeEntity(this.getEntityById("sandClick"));
			
			var sand:Entity = this.getEntityById("sandEntity");
			var emitter:Emitter = sand.get(Emitter);
			emitter.remove = true;
			emitter.emitter.counter.stop();
			
			Dialog(player.get(Dialog)).sayById("whatsThis");
			
			SceneUtil.lockInput(this, false);
		}
		
		private function setupDodoClick():void {
			var i:uint;
			var int:Interaction;
			for(i=1;i<=5;i++) {
				int = this.getEntityById("dodo"+i).get(Interaction);
				int.click = new Signal();
				int.click.add(sayDodo);
			}
			
			int = octavian.get(Interaction);
			int.click = new Signal();
			ToolTipCreator.removeFromEntity(octavian);
		}
		
		private function sayDodo(entity:Entity):void {
			Dialog(player.get(Dialog)).sayById("hungry");
		}
		
		private function setupDoorBlock():void
		{
			var door:Entity = super.getEntityById("doorJungle");
			var scenenteraction:SceneInteraction = door.get(SceneInteraction);
			var interaction:Interaction = door.get(Interaction);
			scenenteraction.offsetX = 0;
			
			interaction.click = new Signal();
			interaction.click.add(moveToJungleDoor);
		}
		
		private function moveToJungleDoor(door:Entity):void {
			Dialog(player.get(Dialog)).sayById("stopOctavian");
		}
	}
}




