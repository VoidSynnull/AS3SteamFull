package game.scenes.deepDive1.deepestOcean
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	
	import game.components.entity.Dialog;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionControl;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.TimedEvent;
	import game.data.comm.PopResponse;
	import game.scene.template.CameraGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.deepDive1.DeepDive1Events;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive1.shared.components.SubCamera;
	import game.scenes.map.map.Map;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.scenes.myth.shared.systems.ElectrifySystem;
	import game.systems.SystemPriorities;
	import game.ui.popup.IslandEndingPopup;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	public class DeepestOcean extends SubScene
	{
		private var jellyFish:Boolean = false;
		private var floorWall:Entity;
		private var _defaultCameraZoom:Number;
		private var _defaultPanRate:Number;
		private var cameraGroup:CameraGroup;
		private var player:Entity;
		private var panTarget:Entity;
		private var whale1:Entity;
		private var whale2:Entity;
		private var savedMotionControl:MotionControl;
		
		private var electrifyEffect:Entity;
		private var electrifySystem:System;
		public var colorFill:GlowFilter = new GlowFilter( 0xFF0000, 1, 20, 20, 10, 1, true );
		public var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1, 1 );
		public var whiteOutline:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 8, 8, 1, 1, true );	
		
		public function DeepestOcean()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive1/deepestOcean/";
			
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
			_events = DeepDive1Events(events);
			super.loaded();
			
			super.shellApi.eventTriggered.add( eventTriggers );
			
			player = shellApi.player;
			electrifyEffect = new Entity;
			electrifySystem = addSystem( new ElectrifySystem(2), SystemPriorities.render );
			setupElectrifyEffect(electrifyEffect, "electrifySub");
			frySub();
			setupPanTarget();
			setupWhales();
			
			cameraGroup = super.getGroupById(CameraGroup.GROUP_ID, this) as CameraGroup;
			// store some defaults for resetting
			_defaultCameraZoom = cameraGroup.zoomTarget;
			_defaultPanRate = cameraGroup.rate;
			cameraGroup.zoomRate = .0075; // .025 is default
			
			SceneUtil.lockInput(this, true);
			savedMotionControl = player.get(MotionControl);
			player.remove(MotionControl);
			CharUtils.setDirection(player, true);
			shellApi.player.get(Tween).to(shellApi.player.get(Spatial), 7, { y:1100, rotation:-390, ease:Linear.easeNone, onComplete:hitBottom });
			
			var subCamera:SubCamera = this.shellApi.player.get(SubCamera);
			subCamera.flashColor = SubCamera.RED;
			subCamera.numberOfFlashes = 4000;
			
			//if( ( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM ) )
			//{
				super.addLight(super.shellApi.player, 300, .9, true, false, 0x000011, 0x000011, .5);
			//}
		}
		
		private function hitBottom():void {		
			super.playMessage("tooDeep");
			super.shellApi.triggerEvent("hitbottom");
			shellApi.player.get(Spatial).rotation = -30;
			shellApi.player.get(Tween).to(shellApi.player.get(Spatial), 2, { y:1000, rotation:-15, ease:Sine.easeOut, onComplete:restBottom });
		}
		
		private function restBottom():void {
			shellApi.player.get(Tween).to(shellApi.player.get(Spatial), 3, { y:1100, rotation:0, ease:Sine.easeInOut, onComplete:returnControl });
		}
		
		private function returnControl():void {
			player.add(savedMotionControl);
			player.get(Motion).maxVelocity.x = 100;
			player.get(Motion).maxVelocity.y = 5;
			SceneUtil.lockInput(this, false);
			this.addSystem(new DeepestOceanSystem());
		}
		
		public function startFinalSequence():void {
			SceneUtil.lockInput(this, true);
			super.playMessage("whatIsThat");
			super.shellApi.triggerEvent("reveal");
			//player.remove(MotionControl);
			player.get(Motion).velocity.x = 0;
			shellApi.player.get(Tween).to(shellApi.player.get(Spatial), 10, { x:1580, y:1100, rotation:0, ease:Sine.easeOut, onUpdate:shakeSub });
			SceneUtil.addTimedEvent(this, new TimedEvent(7, 1, zoomOut, true));
		}
		
		public function shakeSub():void {
			player.get(SpatialAddition).rotation = Utils.randNumInRange(5, 8);
		}
		
		private function zoomOut():void {
			sayFinalLine();
			
			//zoomTarget needs to be different for tablets
			var aspectRatio:Number = super.shellApi.viewportWidth / super.shellApi.viewportHeight;
			if(aspectRatio < 1.5){
				cameraGroup.zoomTarget = .6;
			}else{
				cameraGroup.zoomTarget = .5;
			}

			panTarget.get(Spatial).x = player.get(Spatial).x;
			panTarget.get(Spatial).y = player.get(Spatial).y;
			super.shellApi.camera.target = panTarget.get(Spatial);
			panTarget.get(Tween).to(panTarget.get(Spatial), 10, { delay:0.5, x:1820, ease:Sine.easeInOut });
			
			//moveWhale
			whale1.get(Tween).to(whale1.get(Spatial), 40, { x:1000, ease:Sine.easeOut});
			whale2.get(Tween).to(whale2.get(Spatial), 50, { x:2100, ease:Sine.easeOut});
			
			SceneUtil.addTimedEvent(this, new TimedEvent(12, 1, awardMedallion, true));
			var lightEntity:Entity = super.getEntityById("lightOverlay");
			var tween:Tween = new Tween();
			lightEntity.add(tween);
			tween.to( lightEntity.get(Display), 13, { delay:.5, alpha:0, ease:Sine.easeOut });
			
		}
		
		public function sayFinalLine():void
		{
			var dummy:Entity = getEntityById(SubScene.PLAYER_ID);
			var dialog:Dialog = dummy.get(Dialog);
			dialog.sayById("biggerLens");
		}
		
		private function awardMedallion():void 
		{
			if( !shellApi.checkHasItem( _events.MEDAL_DEEPDIVE1 )) {
				var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
				itemGroup.showAndGetItem( _events.MEDAL_DEEPDIVE1, null, medallionReceived );
			} else {
				medallionReceived();
			}
		}

		private function medallionReceived():void
		{
			shellApi.completedIsland('', onCompletions);
		}

		private function onCompletions(response:PopResponse):void
		{
			SceneUtil.lockInput(this, false);
			this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
		}
		
		private function frySub():void {
			var follow:FollowTarget = new FollowTarget(Spatial(shellApi.player.get(Spatial)));
			follow.properties = new <String>["x","y","rotation"];
			electrifyEffect.add(follow);
			electrifyEffect.get(ElectrifyComponent).on = true;
		}
		
		private function setupWhales():void {
			var container:DisplayObjectContainer = super.getEntityById("backdrop1").get(Display).displayObject;
			
			for(var i:uint=1;i<=2;i++){
				var clip:MovieClip = _hitContainer["whale"+i];
				var w:Entity = new Entity();
				//w = TimelineUtils.convertClip( clip, this, w );
				
				var spatial:Spatial = new Spatial();
				spatial.x = clip.x;
				spatial.y = clip.y;
				
				w.add(spatial);
				w.add(new Display(clip));
				w.add(new Tween());
				//w.get(Display).alpha = .12;
				
				this["whale"+i] = w;
				
				super.addEntity(w);
				BitmapTimelineCreator.convertToBitmapTimeline(w);
				
				container.addChild(w.get(Display).displayObject);
				w.get(Timeline).play();
			}
			
			whale2.get(Spatial).scaleX = -.72;
			
			var sclip:MovieClip = _hitContainer["shimmer"];
			var shimmer:Entity = new Entity();
			shimmer = TimelineUtils.convertClip( sclip, this, shimmer );
			var sspatial:Spatial = new Spatial();
			sspatial.x = sclip.x;
			sspatial.y = sclip.y;
			
			shimmer.add(sspatial);
			shimmer.add(new Display(sclip));
			
			super.addEntity(shimmer);
			
			container.addChild(sclip);
			shimmer.get(Timeline).stop();
		}
		
		private function setupPanTarget():void{
			var clip:MovieClip = _hitContainer["panTarget"];
			panTarget = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			panTarget.add(spatial);
			panTarget.add(new Display(clip));
			panTarget.add(new Tween());
			panTarget.get(Display).alpha = 0;
			
			super.addEntity(panTarget);
		}
		
		private function setupElectrifyEffect(e:Entity, clipName:String):void {
			
			var electrify:ElectrifyComponent;
			var display:Display;
			var number:int;
			var sprite:Sprite;
			var startX:Number;
			var startY:Number;
			
			electrify = new ElectrifyComponent();
			electrify.on = false;
			
			var clip:MovieClip = _hitContainer[clipName];
			
			var container:DisplayObjectContainer = super.getEntityById("foreground").get(Display).displayObject;
			container.addChild(clip);
			
			e.add(new Spatial(clip.x, clip.y));
			e.add(new Display(clip));
			
			e.add( electrify );
			
			super.addEntity(e);
			
			display = e.get( Display );
			
			for( number = 0; number < 10; number ++ )
			{
				sprite = new Sprite();
				startX = Math.random() * 60 - 60;
				startY = Math.random() * 60 - 60;				
				sprite.graphics.lineStyle( 1, 0xFFFFFF );
				sprite.graphics.moveTo( startX, startY );
				electrify.sparks.push( sprite );
				electrify.lastX.push( startX );
				electrify.lastY.push( startY );
				electrify.childNum.push( display.displayObject.numChildren );
				display.displayObject.addChildAt( sprite, display.displayObject.numChildren );
				sprite.filters = new Array( colorFill);
			}	
			e.get(Display).displayObject.filters = new Array(  colorGlow );
		}
		
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if( event == "triggerFadeOut" ){
				SceneUtil.lockInput( this );
				fadeToBlack();
			}
		}
		
		private function fadeToBlack():void
		{
			shellApi.loadScene( Map, NaN, NaN, null, NaN, 1 );
		}
	}
}