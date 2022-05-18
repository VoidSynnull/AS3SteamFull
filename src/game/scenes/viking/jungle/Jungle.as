package game.scenes.viking.jungle
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Sine;
	
	import flash.display.BitmapData;
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
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Skin;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.components.ui.ToolTipActive;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Sword;
	import game.data.animation.entity.character.Throw;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.ui.ToolTipType;
	import game.scene.template.ItemGroup;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.viking.VikingScene;
	import game.scenes.viking.shared.popups.MapPopup;
	import game.systems.motion.ProximitySystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class Jungle extends VikingScene
	{
		private var tree:Entity;
		private var dialogTarget:Entity;
		private var octavian:Entity;
		private var mapDoorinteraction:Interaction;
		private var proximity:Proximity;
		
		private var map:Entity;
		
		private var woodChipsEmitter:WoodChips;
		private var woodChipsEmitterEntity:Entity;
		private var woodChipsTarget:Entity;
		
		private var octavianInteraction:Interaction;
		private var octavianToolTip:ToolTip;
		private var octavianToolTipActive:ToolTipActive;
		
		private var octavianClick:Entity;
		private var octavianClickInteraction:Interaction;
		private var birdClick:Entity;
		private var birdClickInteraction:Interaction;
		
		private var bird:Entity;
		private var treeClick:Entity;
		private var treeClickInteraction:Interaction;
		
		private var octavianOriginalParent:DisplayObjectContainer;
		
		public function Jungle()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/jungle/";
			
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
			
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);

			super.shellApi.eventTriggered.add(handleEventTriggered);
			this.octavian = this.getEntityById("octavian");
			
			setupMapDoor();
			setupBird();
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(3000,673),"minibillboard/minibillboardMedLegs.swf");	
			
			if(PlatformUtils.isMobileOS){
				if(this.getEntityById("book")){
					this.removeEntity(this.getEntityById("book"));
				}
				if(this.getEntityById("book2")){
					this.removeEntity(this.getEntityById("book2"));
				}
			}
			
			if(!shellApi.checkEvent(_events.OCTAVIAN_FREED)) {
				if(this.getEntityById("rope")){
					this.getEntityById("rope").get(Spatial).y += 500;
				}
				setupTree(false);
			}else{
				setupTree(true);
				if(shellApi.checkEvent(_events.OCTAVIAN_RAN_AWAY)){
					this.removeEntity(octavian);
				}else{
					Dialog(octavian.get(Dialog)).setCurrentById("the_beginning");
				}
			}
			if(!shellApi.checkEvent("gotItem_map")) {
				this.addSystem(new ProximitySystem());
				proximity = new Proximity(300, this.player.get(Spatial));
				this.tree.add(proximity);
				proximity.entered.addOnce(octavianGreet);
				setupMap();
			}else{
				_hitContainer["map"].visible = false;
			}
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( event == "give_map" ) {
				CharUtils.setAnim(octavian, Throw, false);
				var tx:Number = player.get(Spatial).x;
				var ty:Number = player.get(Spatial).y;
				map.get(Display).visible = true;
				map.get(Tween).to(map.get(Spatial), 2, { x:tx, y:ty, rotation: 200, ease:Sine.easeIn, onComplete:catchMap });
				panPlayer();
				this.shellApi.triggerEvent("mapFall");
			}else if(event == "axe_used") {
				if(!this.shellApi.checkEvent(_events.OCTAVIAN_FREED)){
					SceneUtil.lockInput(this, true);
					CharUtils.moveToTarget(player, 2615, 880, false, chopTree);
				} else {
					this.shellApi.triggerEvent("cant_use_axe");
				}
			}else if(event == "pan_octavian") {
				panOctavian();
			}else if(event == "pan_player") {
				panPlayer();
			}else if(event == "octavian_run_off") {
				this.shellApi.triggerEvent(_events.OCTAVIAN_RAN_AWAY, true);
				CharUtils.moveToTarget(octavian, 0, 995, false, removeOctavian);
			}
		}
		
		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}

		private function removeOctavian(entity:Entity):void {
			this.removeEntity(octavian);
		}
		
		private function panOctavian():void {
			SceneUtil.setCameraTarget(this, dialogTarget);
		}
		
		private function panPlayer():void {
			SceneUtil.setCameraTarget(this, player);
		}
		
		private function catchMap():void {
			SceneUtil.lockInput(this, false);
			shellApi.getItem(_events.MAP,null,true );
			mapDoorinteraction.click.add(openMap);			
			mapDoorinteraction.click.remove(showMapUnavailable);	
			map.get(Display).visible = false;
			this.removeEntity(map);
			CharUtils.eyesFollowMouse(player);
			CharUtils.eyesFollowMouse(octavian);
		}
		
		private function setupTree(rotated:Boolean):void {
			var treeClip:MovieClip = _hitContainer["tree"];
			var dialogClip:MovieClip = _hitContainer["dialogTarget"];
			tree = EntityUtils.createSpatialEntity(this, treeClip);
			dialogTarget = EntityUtils.createSpatialEntity(this, dialogClip);
			dialogTarget.get(Display).alpha = 0;
			var treeWrapper:BitmapWrapper = DisplayUtils.convertToBitmap(_hitContainer["tree"]["tree"]);
			var basketWrapper:BitmapWrapper = DisplayUtils.convertToBitmap(_hitContainer["tree"]["basket"]);
			
			treeWrapper.bitmap.smoothing = true;
			basketWrapper.bitmap.smoothing = true;
			
			tree.add(new Id("tree"));
			
			if(rotated){
				tree.get(Spatial).x += 40;
				tree.get(Spatial).y += 50;
				tree.get(Spatial).rotation = 70;
				_hitContainer["octavianClick"].visible = false;
				_hitContainer["treeClick"].visible = false;
			} else {
				_hitContainer["sandCover"].visible = false;
				tree.add(new Tween());
				octavianOriginalParent = octavian.get(Display).container;
				Display(octavian.get(Display)).setContainer( treeClip, 1 );
				
				octavian.get(Spatial).x = 50;
				octavian.get(Spatial).y = -380;
				
				//octavianToolTip = octavian.get(Children).children[0].get(ToolTip);
				//octavianToolTipActive = octavian.get(Children).children[0].get(ToolTipActive);
				//Children(octavian.get(Children)).children[0].remove(ToolTipActive);
				//Children(octavian.get(Children)).children[0].remove(ToolTip);
				var entity:Entity = EntityUtils.getChildById(octavian, "tooltip", false);
				
				if( entity != null ){
					octavianToolTip = entity.get(ToolTip);
					octavianToolTipActive = entity.get(ToolTipActive);
					entity.remove(ToolTipActive);
					entity.remove(ToolTip);
				}
				
				octavianClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["octavianClick"]), this);
				octavianClick.remove(Timeline);
				octavianClickInteraction = octavianClick.get(Interaction);
				octavianClickInteraction.down.add( clickOctavian);
				octavianClick.get(Display).alpha = 0;
				
				//trace(octavianClick.getAll());
				
				var shardAsset:MovieClip = super.getAsset( "chips.swf") as MovieClip; 
				var bitmapData:BitmapData = BitmapUtils.createBitmapData(shardAsset);
				woodChipsEmitter = new WoodChips();
				woodChipsEmitter.init( bitmapData );
				
				woodChipsTarget = new Entity();
				woodChipsTarget.add(new Spatial());
				woodChipsTarget.get(Spatial).x = 2676;
				woodChipsTarget.get(Spatial).y = 933;
				
				woodChipsEmitterEntity = EmitterCreator.create( this, super._hitContainer, woodChipsEmitter, 0, 0, player, "mEmitterEntity", woodChipsTarget.get(Spatial), false );
				
				Dialog(octavian.get(Dialog)).faceSpeaker = false;
				
				treeClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["treeClick"]), this);
				treeClick.remove(Timeline);
				treeClickInteraction = treeClick.get(Interaction);
				treeClickInteraction.down.add( clickTree);
				treeClick.get(Display).alpha = 0;
			}			
		}
		
		private function clickTree(entity:Entity):void {
			Dialog(player.get(Dialog)).sayById("wontBudge");
		}
		
		private function clickOctavian(entity:Entity):void {
			Dialog(octavian.get(Dialog)).sayById("getDown");
			panOctavian();
		}
		
		private function setupMap():void {
			var mapClip:MovieClip = _hitContainer["map"];
			map = EntityUtils.createSpatialEntity(this, mapClip);
			var mapWrapper:BitmapWrapper = DisplayUtils.convertToBitmap(_hitContainer["map"]["map"]);
			mapWrapper.bitmap.smoothing = true;
			
			map.add(new Id("map"));
			
			Display(map.get(Display)).visible = false;
			
			map.add(new Tween());
		}
		
		private function octavianGreet(entity:Entity):void {
			SceneUtil.lockInput(this, true);
			Dialog(octavian.get(Dialog)).sayById("look");
			CharUtils.eyesFollowTarget(player, octavian);
			CharUtils.eyesFollowTarget(octavian, player);
			CharUtils.moveToTarget(player, 2564, 980, false, setPlayerRight);
			panOctavian();
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
		
		private function woodChips():void {
			woodChipsEmitter.start();
			this.shellApi.triggerEvent("chop");
		}
		
		private function swingAxe(entity:Entity=null):void {
			MotionUtils.zeroMotion(super.player, "x");
			MotionUtils.zeroMotion(super.player, "y");
			player.get(Spatial).x = 2615;
			player.get(Spatial).y = 940;
			var hand:Entity = Skin( shellApi.player.get( Skin )).getSkinPartEntity( "item" );
			var handSpatial:Spatial = hand.get( Spatial );
			TweenUtils.globalFrom(this,handSpatial,0.4,{rotation:160},"axe_rot");
		}
		
		private function preTreeFall():void {
			var lookData:LookData = new LookData();
			lookData.applyAspect( new LookAspectData( SkinUtils.ITEM, "empty" ) );
			SkinUtils.applyLook( player, lookData, false );
			tree.get(Tween).to(tree.get(Spatial), 2, { rotation:5, ease:Sine.easeIn, onComplete:snapPhoto });
			CharUtils.moveToTarget(player, 2406, 994, false, setPlayerRight);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, octavianYell, true));
		}
		
		private function octavianYell():void {
			Sleep(octavian.get(Sleep)).ignoreOffscreenSleep = true;
			CharUtils.setAnim(octavian, Grief);
		}
		
		private function setPlayerRight(entity:Entity):void {
			CharUtils.setDirection(player, true);
		}
		
		private function snapPhoto( ...args ):void
		{
			this.shellApi.takePhoto("13478", treeFall);
		}
		
		private function treeFall(entity:Entity=null):void {
			var tx:Number = tree.get(Spatial).x + 40;
			var ty:Number = tree.get(Spatial).y + 50;
			tree.get(Tween).to(tree.get(Spatial), 2, { rotation:70, ease:Bounce.easeOut });
			tree.get(Tween).to(tree.get(Spatial), 2, { x:tx, y:ty, ease:Bounce.easeInOut, onComplete:treeFell });
			CharUtils.setDirection(player, true);
			_hitContainer["sandCover"].visible = true;
			treeClick.remove(ToolTip);
			treeClick.remove(ToolTipActive);
			treeClick.remove(Interaction);
			Dialog(player.get(Dialog)).sayById("timber");
			this.shellApi.triggerEvent("mapFall");
		}
		
		private function treeFell():void {
			CharUtils.setDirection(player, true);
			SceneUtil.lockInput(this, false);
			octavianOriginalParent.addChild(octavian.get(Display).displayObject);
			Display(octavian.get(Display)).setContainer(octavianOriginalParent);
			octavian.add(octavianToolTip);
			octavian.add(octavianToolTipActive);
			octavian.get(Spatial).x = 3476;
			octavian.get(Spatial).y = 995;
			shellApi.completeEvent(_events.OCTAVIAN_FREED);
			if(this.getEntityById("rope")){
				this.getEntityById("rope").get(Spatial).y = 1035;
			}
			Dialog(octavian.get(Dialog)).setCurrentById("the_beginning");
			
			octavianClick.remove(ToolTip);
			octavianClick.remove(ToolTipActive);
			octavianClick.remove(Interaction);			
		}
		
		private function setupBird():void {
			bird = EntityUtils.createSpatialEntity(this, _hitContainer["bird"], _hitContainer);
			BitmapTimelineCreator.convertToBitmapTimeline(bird);
			bird.get(Timeline).gotoAndPlay("breathe");
			
			birdClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["birdClick"]), this);
			birdClick.remove(Timeline);
			birdClickInteraction = birdClick.get(Interaction);
			birdClickInteraction.down.add( clickBird);
			birdClick.get(Display).alpha = 0;
		}
		
		private function clickBird(entity:Entity):void {
			if(Timeline(bird.get(Timeline)).currentIndex < 35){
				bird.get(Timeline).gotoAndPlay("sqwaking");
				this.shellApi.triggerEvent("bird");
			}
		}
		
		private function setupMapDoor():void {
			var door:Entity = super.getEntityById("doorMap");
			var scenenteraction:SceneInteraction = door.get(SceneInteraction);
			mapDoorinteraction = door.get(Interaction);
			scenenteraction.offsetX = 0;
			mapDoorinteraction.click = new Signal();
			if(shellApi.checkEvent("gotItem_map")) {
				mapDoorinteraction.click.add(moveToDoor);			
			} else {
				mapDoorinteraction.click.add(showMapUnavailable);	
			}
		}
		
		private function showMapUnavailable(door:Entity):void {
			Dialog(player.get(Dialog)).sayById("thick");
		}
		
		private function moveToDoor(door:Entity):void {
			var targX:Number = door.get(Spatial).x + 20;
			var targY:Number = door.get(Spatial).y;
			CharUtils.moveToTarget(player, targX, targY, false, openMap);
		}
		
		private function openMap(entity:Entity):void {
			var mapPopup:MapPopup = new MapPopup(overlayContainer);
			addChildGroup(mapPopup);
		}
	}
}