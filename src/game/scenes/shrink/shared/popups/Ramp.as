package game.scenes.shrink.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.RotateToVelocity;
	import game.components.motion.Threshold;
	import game.data.TimedEvent;
	import game.scenes.shrink.shared.Systems.CarSystem.Car;
	import game.scenes.shrink.shared.Systems.CarSystem.CarSystem;
	import game.scenes.shrink.shared.Systems.PopupCamera.PopupCamera;
	import game.scenes.shrink.shared.Systems.PopupCamera.PopupCameraSystem;
	import game.scenes.shrink.silvaOfficeShrunk02.SilvaOfficeShrunk02;
	import game.systems.motion.RotateToVelocitySystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class Ramp extends Popup
	{
		private var car:Entity;
		private var camera:Entity;
		
		private var _viewportRatioX:Number;
		private var _viewportRatioY:Number;
		
		public function Ramp( container:DisplayObjectContainer = null )
		{
			super( container );
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.groupPrefix = "scenes/shrink/shared/popups/";
			super.screenAsset = "ramp.swf";
			
			if( !super.systemManager.getSystem( ThresholdSystem ))
			{
				super.addSystem( new ThresholdSystem());
			}
			
			super.darkenBackground = true;
			super.autoOpen = false;
			super.pauseParent = false;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			car = setUpCar( screen.content.car );
			
			var popupCamera:PopupCamera = new PopupCamera( this, container, screen.content.getRect( screen.content ), shellApi.camera.viewport );
			popupCamera.setTarget( car.get( Spatial ), 0 );
			popupCamera.addLayer( screen.content );
			
			centerPopupToDevice();
			var camera:Entity = EntityUtils.createSpatialEntity( this, new MovieClip(), container );
			camera.add( popupCamera );
			
			setUpRamp();
			
			addSystem( new PopupCameraSystem());
			addSystem( new RotateToVelocitySystem());
			
			open();
		}
		
		private function setUpCar( car:MovieClip ):Entity
		{
			addSystem( new CarSystem());
			var entity:Entity = EntityUtils.createMovingEntity( this, car, screen.content );
			entity.add( new Id( "car" )).add( new Car( car, this ));
			
			return entity;
		}
		
		private function setUpRamp():void
		{
			Motion(car.get(Motion)).velocity.x = 250;
			
			var spatial:Spatial = car.get( Spatial );
			spatial.scaleX *= -1;
			spatial.x -= 100;
			
			var threshold:Threshold = new Threshold("x",">");
			threshold.threshold = 240;
			threshold.entered.addOnce(goUpRamp);
			car.add(threshold).add(new RotateToVelocity());
		}
		
		private function goUpRamp():void
		{
			var motion:Motion = car.get(Motion);
			motion.velocity.y = -250;
			
			var threshold:Threshold = car.get(Threshold);
			threshold.threshold = 400;
			threshold.entered.addOnce(goToLanding);
		}
		
		private function goToLanding():void
		{
			var motion:Motion = car.get(Motion);
			motion.velocity.y = 0;
			motion.y = 260;
			motion.friction = new Point(500, 0);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1,1,goInOffice));
		}
		
		private function goInOffice():void
		{
			shellApi.loadScene(SilvaOfficeShrunk02);
		}
	}
}