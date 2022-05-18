package game.scenes.shrink.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.motion.RotateToVelocity;
	import game.components.motion.Threshold;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scenes.shrink.carGame.CarGame;
	import game.scenes.shrink.shared.Systems.CarSystem.Car;
	import game.scenes.shrink.shared.Systems.CarSystem.CarSystem;
	import game.scenes.shrink.shared.Systems.PopupCamera.PopupCamera;
	import game.scenes.shrink.shared.Systems.PopupCamera.PopupCameraSystem;
	import game.scenes.shrink.shared.particles.BreakingGlass;
	import game.systems.motion.RotateToVelocitySystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class Jump extends Popup
	{
		private var car:Entity;
		private var camera:Entity;
		
		public function Jump(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/shrink/shared/popups/";
			super.screenAsset = "jump.swf";
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
			
			centerPopupToDevice();
			
			car = setUpCar( screen.content.car );
			
			var camera:Entity = EntityUtils.createSpatialEntity( this, new MovieClip(), container );
			
			var popupCamera:PopupCamera = new PopupCamera( this, container, screen.content.getRect(screen.content), shellApi.camera.viewport );
			camera.add( popupCamera );
			
			popupCamera.setTarget( car.get( Spatial ));
			popupCamera.addLayer( screen.content );
			
			setUpJump();
			
			addSystem(new PopupCameraSystem());
			addSystem(new RotateToVelocitySystem());
			
			open();
		}
		
		private function setUpCar( car:MovieClip ):Entity
		{
			addSystem( new CarSystem());
			var entity:Entity = EntityUtils.createMovingEntity( this, car, screen.content );
			entity.add( new Id( "car" )).add( new Car( car, this ));
			
			return entity;
		}
		
		private function setUpJump():void
		{
			Motion( car.get( Motion )).velocity.x = -275;
			Spatial( car.get( Spatial )).x += 100;
			
			var threshold:Threshold = new Threshold( "x", "<" );
			threshold.threshold = 750;
			threshold.entered.addOnce( jump );
			car.add( threshold ).add( new RotateToVelocity( 180 ));
			
			var brokenGlass:Entity = EntityUtils.createSpatialEntity( this, screen.content[ "brokenClip" ]);
			Display( brokenGlass.get( Display )).visible = false;
			brokenGlass.add( new Id( "brokenGlass" ));
		}
		
		private function jump():void
		{
			var motion:Motion = car.get( Motion );
			motion.velocity.y = -225;
			motion.acceleration.y = 125;
			
			var threshold:Threshold = car.get( Threshold );
			threshold.threshold = 45;
			threshold.entered.addOnce( breakGlass );
		}
		
		private function breakGlass():void
		{
			var brokenGlass:Entity = getEntityById( "brokenGlass" );
			var glassPos:Spatial = brokenGlass.get( Spatial );
			Display( brokenGlass.get( Display )).visible = true;
			
			var breakingGlass:BreakingGlass = new BreakingGlass();
			breakingGlass.init( glassPos.height );
			
			EmitterCreator.create( this, screen.content, breakingGlass, glassPos.x, glassPos.y );
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "glass_break_03.mp3" );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, driveToSchool ));
		}
		
		private function driveToSchool():void
		{
			shellApi.loadScene( CarGame );//will be the top down driving scene
		}
	}
}