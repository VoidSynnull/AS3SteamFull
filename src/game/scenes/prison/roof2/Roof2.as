package game.scenes.prison.roof2
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Hide;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.motion.Mass;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.data.sound.SoundModifier;
	import game.scene.template.AudioGroup;
	import game.scenes.prison.PrisonScene;
	import game.systems.SystemPriorities;
	import game.systems.entity.DetectionSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.PerformanceUtils;
	
	public class Roof2 extends PrisonScene
	{
		public function Roof2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/prison/roof2/";
			
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
			setupPushBox();
			setupLights();
			setupHideZones(4);
		}
		
		private function setupPushBox():void
		{
			var sceneObjectCreator:SceneObjectCreator = new SceneObjectCreator();
			this.addSystem(new SceneObjectHitRectSystem());
			
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));
			
			var clip:MovieClip = _hitContainer["boxBounds"];
			var bounds:Rectangle = new Rectangle(clip.x, clip.y, clip.width, clip.height);
			_hitContainer.removeChild(clip);
			clip = _hitContainer["pushBox"];
			var box:Entity = sceneObjectCreator.createBox(clip,0,super.hitContainer,clip.x,clip.y,null,null,bounds,this,null,null,400);
			box.add(new PlatformCollider());
			
			var audioGroup:AudioGroup = AudioGroup(getGroupById(AudioGroup.GROUP_ID));
			audioGroup.addAudioToEntity(box, "box");
			new HitCreator().addHitSoundsToEntity(box, audioGroup.audioData, shellApi, "box");
			
			var drape:Entity = BitmapTimelineCreator.convertToBitmapTimeline(null, _hitContainer["drape"], true, null, PerformanceUtils.defaultBitmapQuality);
			addEntity(drape);
			drape.get(Timeline).play();
			var audio:Audio = new Audio();
			drape.add(audio);
			drape.add(new AudioRange(700));
			
			audio.play(SoundManager.EFFECTS_PATH + "flag_flapping_quickly_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
		}
		
		private function setupLights():void
		{
			setupRoofLight("light1", 30, 5, 1111, 106);
			setupRoofLight("light2", -30, 5, 1115, 100);
			setupRoofLight("light3", 30, 5, 1005, 102);
			
			player.add(new Hide());
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new DetectionSystem(), SystemPriorities.resolveCollisions);	
		}
		
		override protected function roofCaught(...args):void
		{
			var playerSpatial:Spatial = player.get(Spatial);
			roofCheckPoint = playerSpatial.x < 1380 ? new Point(60, 660) : roofCheckPoint = new Point(1385, 660);		 
			
			super.roofCaught();
		}
	}
}