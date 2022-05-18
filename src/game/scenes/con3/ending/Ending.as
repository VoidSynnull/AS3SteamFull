package game.scenes.con3.ending
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import engine.components.SpatialAddition;
	import engine.managers.SoundManager;
	
	import game.components.motion.ShakeMotion;
	import game.components.timeline.Timeline;
	import game.data.sound.SoundModifier;
	import game.scene.template.CutScene;
	import game.scenes.con3.expo.Expo;
	import game.systems.motion.ShakeMotionSystem;
	import game.util.AudioUtils;
	
	import org.flintparticles.twoD.zones.EllipseZone;

	public class Ending extends CutScene
	{		
		public function Ending()
		{
			super();
			configData( "scenes/con3/ending/" );
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.init( container );
			addSystem( new ShakeMotionSystem());
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			start();
			var timeline:Timeline = super.sceneEntity.get( Timeline );
			timeline.handleLabel( "shake", shakeScreen );
			timeline.handleLabel( "endShake", endShakeScreen );
			timeline.handleLabel("flashing", playFlashSound);
		}
		
		private function playFlashSound():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "event_02.mp3", 1, false, [SoundModifier.EFFECTS]);
		}
		
		private function shakeScreen():void
		{
			var shakeMotion:ShakeMotion = new ShakeMotion( new EllipseZone( new Point( 0, 0 ), 4, 4 ));
			sceneEntity.add( shakeMotion ).add( new SpatialAddition());
		}
		
		private function endShakeScreen():void
		{
			var spatialAddition:SpatialAddition = sceneEntity.get( SpatialAddition );
			spatialAddition.x = spatialAddition.y = 0;
			
			sceneEntity.remove( ShakeMotion );
		}
		
		override public function end():void
		{
			shellApi.loadScene( Expo );
		}
	}
}