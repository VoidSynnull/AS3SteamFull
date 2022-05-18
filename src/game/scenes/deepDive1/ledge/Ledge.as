package game.scenes.deepDive1.ledge
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.Tween;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Radial;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionControl;
	import game.components.motion.Proximity;
	import game.components.motion.WaveMotion;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.scene.template.CameraGroup;
	import game.scenes.deepDive1.DeepDive1Events;
	import game.scenes.deepDive1.deepestOcean.DeepestOcean;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive1.shared.components.Filmable;
	import game.scenes.deepDive1.shared.components.SubCamera;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.scenes.myth.shared.systems.ElectrifySystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.ProximitySystem;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	public class Ledge extends SubScene
	{
		private var jellyFish:Boolean = false;
		private var floorWall:Entity;
		private var electrifyEffect:Entity;
		public var colorFill:GlowFilter = new GlowFilter( 0xFF0000, 1, 20, 20, 10, 1, true );
		public var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1, 1 );
		public var whiteOutline:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 8, 8, 1, 1, true );	
		
		private var _defaultCameraZoom:Number;
		private var _defaultPanRate:Number;
		private var cameraGroup:CameraGroup;
		
		private var player:Entity;
		
		public function Ledge()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive1/ledge/";

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
			
			if(jellyFish){
				floorWall = getEntityById("bottomWall");
				floorWall.remove(Radial);
			}
			super.loaded();
			
			player = shellApi.player;
			
			//test to see if jellies should be present
			if(shellApi.checkEvent(_events.CAPTURED_ALL_FISH) && !this.shellApi.checkItemEvent(_events.MEDAL_DEEPDIVE1))
			{
				setupJellies();
				setupJellyTarget();
				
				electrifyEffect = new Entity;
				
				addSystem( new ElectrifySystem(), SystemPriorities.render );
				
				setupElectrifyEffect(electrifyEffect, "electrifySub");
				this.addSystem(new ProximitySystem());
				
				var proximity:Proximity = new Proximity(400, this.player.get(Spatial));
				proximity.entered.addOnce(frySub);
				//this.getEntityById("jellyTarget").add(proximity);
				
				var proximity2:Proximity = new Proximity(1500, this.player.get(Spatial));
				proximity2.entered.addOnce(zoomIn);
				this.getEntityById("jellyTarget").add(proximity2);
				
				var subCamera:SubCamera = super.shellApi.player.get(SubCamera);
				subCamera.angle = 120;
				subCamera.distanceMax = 400;
				subCamera.distanceMin = 0;
				
				var jelly:Entity = this.getEntityById("j1");
				jelly.get(Spatial).rotation = 26;
				jelly.get(SpatialOffset).x = -1142;
				//jelly.add(new Tween());
				jelly.get(Tween).to(jelly.get(SpatialOffset), 4, { x:0, ease:Sine.easeInOut, onComplete:setFilmable });
				super.makeFilmable( jelly, onFishFilmEvent,230, 10, false ); 
				//jelly.get(Filmable).isFilmable = true;
			}else{
				removeJellies();
				super.playMessage("watch_out_cliff");
			}
			
			//if( ( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM ) )
			//{
				super.addLight(super.shellApi.player, 200, .9, true, true, 0x000022, 0x000022);
			//}
			
			cameraGroup = super.getGroupById(CameraGroup.GROUP_ID, this) as CameraGroup;
			// store some defaults for resetting

			_defaultCameraZoom = cameraGroup.zoomTarget;
			_defaultPanRate = cameraGroup.rate;
			cameraGroup.zoomRate = .025; // .025 is default
		}
		
		private function setFilmable():void {
			var jelly:Entity = this.getEntityById("j1");
			jelly.get(Filmable).isFilmable = true;
		}
		
		private function onFishFilmEvent( entity:Entity ):void
		{
			// Using this for click if we aren't ready to have it be filmable
			var filmable:Filmable = entity.get(Filmable);
			trace ("[ShipUnderside] onFishFilmedEvent.  filmable.state: " +  filmable.state)
			switch( filmable.state )
			{
				case filmable.FILMING_OUT_OF_RANGE:
				{
					// need to get closer
					super.playMessage( "tooFar" );
					break;
				}
				case filmable.FILMING_BLOCK:
				{
					// explain why
					//super.playMessage( "filmBlockSeaHorse" );
					break;
				}
				case filmable.FILMING_START:
				{
					// listen for complete
					SceneUtil.lockInput(this, true);
					var xTarg:Number;
					if(entity.get(Spatial).x < shellApi.player.get(Spatial).x){
						xTarg = entity.get(Spatial).x + 200;
					}else{
						xTarg = entity.get(Spatial).x - 200;
					}
					var yTarg:Number = entity.get(Spatial).y;
					shellApi.player.get(Tween).to(shellApi.player.get(Spatial), 5, { x:xTarg, y:yTarg, rotation:0, ease:Sine.easeOut });
					attack();
					
					super.playMessage( "filmStart" );
					break;
				}
				case filmable.FILMING_STOP:
				{
					// listen for complete
					//super.playMessage( "filmStop" );
					break;
				}
				case filmable.FILMING_COMPLETE:
				{
					// listen for complete
					//super.removeFilmable( _seaDragon)
					//shellApi.triggerEvent(_events.SEADRAGON_CAPTURED, true);
					//super.playMessage( "filmCompleteSeaHorse", onFishCaptured );
					
					break;
				}
				default:
				{
					trace( "invalid state: " + filmable.state );
					break;
				}
			}
		}
		
		private function attack():void {
			for(var i:uint=2;i<=13;i++){
				trace(i);
				var jelly:Entity = super.getEntityById("j"+i);
				var startX:Number;
				var startY:Number;
				
				if(jelly.get(Spatial).x < shellApi.player.get(Spatial).x) {
					startX = shellApi.player.get(Spatial).x + Utils.randNumInRange(-250, 0);
				}else{
					startX = shellApi.player.get(Spatial).x + Utils.randNumInRange(0, 250);
				}
				if(jelly.get(Spatial).y < shellApi.player.get(Spatial).y) {
					startY = shellApi.player.get(Spatial).y + Utils.randNumInRange(-200, -20);
				}else{
					startY = shellApi.player.get(Spatial).y + Utils.randNumInRange(20, 200);
				}
				var startScale:Number = jelly.get(Spatial).scale;
				
				jelly.get(Sleep).ignoreOffscreenSleep = true;
				jelly.get(Sleep).sleeping = false;
			
				jelly.get(Spatial).scale = 0.4;
				jelly.get(Display).alpha = 0;
				jelly.get(Display).visible = true;
				
				jelly.get(Tween).to(jelly.get(Display), 10, { alpha:1, ease:Sine.easeOut });
				jelly.get(Tween).to(jelly.get(Spatial), 10, { x:startX, y:startY, scale:startScale, ease:Sine.easeOut });
			}
			SceneUtil.addTimedEvent(this, new TimedEvent(8, 1, frySub, true));
		}
		
		private function zoomIn(entity:Entity):void {
			cameraGroup.zoomTarget = 1.25;
		}
		
		private function frySub(entity:Entity=null):void {
			var dummy:Entity = getEntityById(SubScene.PLAYER_ID);
			var dialog:Dialog = dummy.get(Dialog);
			dialog.sayById("zap");
			super.shellApi.triggerEvent("zap");
			super.shellApi.triggerEvent("attack");
			var follow:FollowTarget = new FollowTarget(Spatial(shellApi.player.get(Spatial)));
			follow.properties = new <String>["x","y","rotation"];
			SceneUtil.lockInput(this, true);
			electrifyEffect.add(follow);
			electrifyEffect.get(ElectrifyComponent).on = true;
			for(var i:uint=1;i<=13;i++){
				super.getEntityById("j"+i).get(Display).displayObject["shock"].visible = true;
				super.getEntityById("j"+i).get(Display).displayObject["shock"].play();
				super.getEntityById("j"+i).get(Display).displayObject["shock"].scaleX = 1;
				super.getEntityById("j"+i).get(Display).displayObject["shock"].scaleY = 1;
			}
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, sinkSub, true));
		}
		
		private function sinkSub():void {
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, turnOffJellies, true));
			player.remove(WaveMotion);
			player.remove(MotionControl);
			shellApi.player.get(Tween).to(shellApi.player.get(Spatial), 15, { y:3000, rotation:-360, ease:Sine.easeInOut });
			SceneUtil.addTimedEvent(this, new TimedEvent(13, 1, endScene, true));
			
			var subCamera:SubCamera = this.shellApi.player.get(SubCamera);
			subCamera.flashColor = SubCamera.RED;
			subCamera.numberOfFlashes = 40;
			cameraGroup.zoomTarget = 1;
		}
		
		private function endScene():void {
			super.shellApi.loadScene(DeepestOcean, 250, 125, "right");
		}
		
		private function turnOffJellies():void {
			for(var i:uint=1;i<=13;i++){
				super.getEntityById("j"+i).get(Display).displayObject["shock"].visible = false;
				super.getEntityById("j"+i).get(Display).displayObject["shock"].stop();
				super.getEntityById("j"+i).get(Display).displayObject["shock"].scaleX = 0;
				super.getEntityById("j"+i).get(Display).displayObject["shock"].scaleY = 0;
			}
		}
		
		private function setupJellyTarget():void {
			var clip:MovieClip = _hitContainer["jellyTarget"];
			var jt:Entity = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			jt.add(spatial);
			jt.add(new Display(clip));
			jt.add(new Id("jellyTarget"));
			super.addEntity(jt);
			jt.get(Display).alpha = 0;
		}
		
		private function setupJellies():void {			
			for(var i:uint=1;i<=13;i++){
				var clip:MovieClip = _hitContainer["j"+i];
				if(PlatformUtils.isMobileOS)
				{
					this.convertContainer(clip);
				}
				
				var j:Entity = new Entity();
				j = TimelineUtils.convertClip( clip, this, j );
				
				var spatial:Spatial = new Spatial();
				spatial.x = clip.x;
				spatial.y = clip.y;
				spatial.scale = Utils.randNumInRange(0.75, 1.25);
				spatial.rotation = Utils.randNumInRange(-30, 30);
				
				j.add(spatial);
				j.add(new Display(clip));
				j.add(new Id("j"+i));
				j.add(new SpatialOffset());
				j.add(new Tween());
				
				MotionUtils.addWaveMotion(j, new WaveMotionData("y",30,0.02),this);
				
				super.addEntity(j);
				j.get(Display).displayObject["shock"].visible = false;
				j.get(Display).displayObject["shock"].stop();
				j.get(Display).displayObject["shock"].scaleX = 0;
				j.get(Display).displayObject["shock"].scaleY = 0;
				if(i != 1){
					j.get(Display).visible = false;
				}
			}
		}
		
		private function removeJellies():void {			
			for(var i:uint=1;i<=13;i++){
				var clip:MovieClip = _hitContainer["j"+i];
				clip.visible = false;
			}
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
	}
}