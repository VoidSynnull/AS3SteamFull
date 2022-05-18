package game.scenes.deepDive3.shared.groups
{
	import ash.core.Entity;
	
	import engine.components.SpatialAddition;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.components.motion.ShakeMotion;
	import game.data.TimedEvent;
	import game.scenes.deepDive3.shared.SubsceneLightingGroup;
	import game.systems.motion.ShakeMotionSystem;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class ShipTakeOffGroup extends Group
	{
		private var _cameraEntity:Entity;
		private var _haveLightSource:Boolean;
		private var _lightOverlay:Entity;
		private var _scene:Scene;
		private var _targetDarkness:Number;
		
		public static const GROUP_ID:String = "shipTakeOffGroup";
		
		public function ShipTakeOffGroup( scene:Scene, lightOverlay:Entity, targetDarkness:Number = .9, haveLightSource:Boolean = true )// scene:Scene, targetDarkness:Number = .9, playerHasLight:Boolean = true )///scene:Scene, lightOverlay:Entity, targetDarkness:Number=0.9, playerHasLight:Boolean=true, shaking:Boolean=true)
		{
			super();
			super.id = GROUP_ID;
			
			this._haveLightSource = haveLightSource;
			this._lightOverlay = lightOverlay;
			this._scene = scene;
			this._targetDarkness = targetDarkness;
			
			init();
		}
		
		public function init():void
		{
			var lightingGroup:SubsceneLightingGroup = _scene.getGroupById( SubsceneLightingGroup.GROUP_ID ) as SubsceneLightingGroup;
			if( lightingGroup )
			{
				lightingGroup.alarmFlash();
			} 
			else 
			{
				SubsceneLightingGroup.startLights( _lightOverlay );
			}
			
			var highQuality:Boolean = ( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST ) ? false : true;
			
			if( highQuality )
			{
				shakeScene();
				_scene.addSystem( new ShakeMotionSystem());
			}
		}
		
		private function shakeScene():void
		{
			if( !_cameraEntity )
			{
				_cameraEntity = _scene.getEntityById( "camera" );
			}
			var shake:ShakeMotion = new ShakeMotion( new RectangleZone( -10, -10, 10, 10 ));//-.5 * _scene.shellApi.viewportWidth, -.5 * _scene.shellApi.viewportHeight, .5 * _scene.shellApi.viewportWidth, .5 * _scene.shellApi.viewportHeight ));
			
			_cameraEntity.add( shake ).add( new SpatialAddition());
			shake.active = true;
			
			var wait:Number = Utils.randInRange( 1, 5 );
			SceneUtil.addTimedEvent( _scene, new TimedEvent( wait, 1, endShake ));
			_scene.shellApi.triggerEvent( "shakeShip" );
		}
		
		private function endShake():void
		{
			if( !_cameraEntity )
			{
				_cameraEntity = _scene.getEntityById( "camera" );
			}
			var shake:ShakeMotion = _cameraEntity.get( ShakeMotion );
			shake.active = false;
			
			var wait:Number = Utils.randInRange( 1, 5 );
			SceneUtil.addTimedEvent( _scene, new TimedEvent( wait, 1, shakeScene ));
		}
	}
}