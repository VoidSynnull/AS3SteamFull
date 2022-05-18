package game.scenes.shrink.avenueA
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.hit.Door;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.data.WaveMotionData;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.shrink.ShrinkEvents;
	import game.components.entity.OriginPoint;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	
	public class AvenueA extends PlatformerGameScene
	{
		public function AvenueA()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/avenueA/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var shrinkRay:ShrinkEvents;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			shrinkRay = events as ShrinkEvents;
			
			setUpCat();
			setUpDoor();

			if(!PlatformUtils.isMobileOS)
			{
				setUpFlies();
			}
		}
		
		private function setUpCat():void
		{
			var cat:Entity = super.getEntityById("cat");
			if( cat != null )
			{
				EntityUtils.removeInteraction( cat );
			}
		}
		
		private function setUpFlies():void
		{
			var basePosition:Rectangle = new Rectangle(425, 875, 25, 25);
			
			var sprite:Sprite = new Sprite();
			sprite.x = basePosition.x + basePosition.width / 2;
			sprite.y = basePosition.y + basePosition.height / 2;
			
			var audioEntity:Entity = EntityUtils.createSpatialEntity(this,sprite, _hitContainer);
			audioEntity.add(new Audio()).add( new AudioRange(1000, 0, 1, Quad.easeOut));
			Audio(audioEntity.get(Audio)).play(SoundManager.EFFECTS_PATH +"insect_flies_02_loop.mp3", true, SoundModifier.POSITION);
			
			for(var i:int = 1; i <= 4; i++)
			{
				var clip:MovieClip = new MovieClip();
				clip.graphics.beginFill(0,1);
				clip.graphics.drawCircle(0,0,2);
				clip.graphics.endFill();
				
				var fly:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				
				var flyPos:Spatial = fly.get(Spatial);
				flyPos.x = basePosition.x + Math.random() * basePosition.width;
				flyPos.y = basePosition.y + Math.random() * basePosition.height;
				
				fly.add(new SpatialAddition());
				fly.add(new WaveMotion());
				fly.add(new OriginPoint(flyPos.x, flyPos.y));
				fly.add(new Tween());
				
				moveFly(fly);
			}
		}
		
		private function moveFly(fly:Entity):void
		{
			var wave:WaveMotion = fly.get(WaveMotion);
			wave.data.length = 0;
			wave.data.push(new WaveMotionData("x", Math.random() * 10, Math.random() / 10));
			wave.data.push(new WaveMotionData("y", Math.random() * 10, Math.random() / 10));
			
			var origin:OriginPoint = fly.get(OriginPoint);
			var targetX:Number = (Math.random() - 0.5) * 250 + origin.x;
			var targetY:Number = (Math.random() - 0.5) * 100 + origin.y;
			
			var time:Number = Math.random() * .25 +.5;
			
			var tween:Tween = fly.get(Tween);
			tween.to(fly.get(Spatial), time, {x:targetX, y:targetY, ease:Linear.easeInOut, onComplete:moveFly, onCompleteParams:[fly]});
		}
		
		private function setUpDoor():void
		{
			var door:Entity = getEntityById("doorApartmentNormal");
			if(!shellApi.checkEvent(shrinkRay.GOT_ADDRESS) || shellApi.checkEvent(shrinkRay.SHRUNK_SILVA))
			{
				removeEntity(door);
				return;
			}
			var interaction:SceneInteraction = door.get(SceneInteraction);
			interaction.reached.add(reachedDoor);
		}
		
		private function reachedDoor(entity:Entity, door:Entity):void
		{
			shellApi.completeEvent(shrinkRay.ENTERED_APARTMENT);
			Door(door.get(Door)).open = true;
		}
	}
}