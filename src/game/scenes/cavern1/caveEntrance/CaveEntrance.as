package game.scenes.cavern1.caveEntrance
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.SpatialAddition;
	
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.data.WaveMotionData;
	import game.scenes.cavern1.shared.Cavern1Scene;
	import game.systems.motion.WaveMotionSystem;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class CaveEntrance extends Cavern1Scene
	{
		public function CaveEntrance()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/cavern1/caveEntrance/";
			
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			if(!shellApi.checkEvent(cavern1.STANLEY_IN_CAVE))
			{
				var interaction:SceneInteraction = getEntityById("door2").get(SceneInteraction);
				interaction.reached.removeAll();
				interaction.reached.addOnce(goInCave);
			}
			
			setUpGeysers(1,5,3);
		}
		
		private function setUpGeysers(startNumber:int, upTime:Number, downTime:Number):void
		{
			addSystem(new WaterGeyserSystem());
			addSystem(new WaveMotionSystem());
			var geyserNumber:int = startNumber;
			var geyser:Entity = getEntityById("geyser"+geyserNumber);
			var platform:Entity = getEntityById("geyserPlatform"+geyserNumber);
			var waterGeyser:WaterGeyser;
			var clip:MovieClip;
			var waveMotion:WaveMotion;
			while(geyser || platform)
			{
				waterGeyser = new WaterGeyser(geyser, platform, upTime, downTime, Math.random() > .5);
				geyser.add(waterGeyser);
				if(platform)
				{
					EntityUtils.getDisplay(platform).isStatic = false;
					waveMotion = new WaveMotion();
					waveMotion.add(new WaveMotionData("y", 10, 5,"sin",Math.PI * 2 * Math.random(),true)); 
					platform.add(new SpatialAddition()).add(waveMotion);
				}
				
				clip = _hitContainer["geyserAnimation"+geyserNumber];
				if(clip)
					TimelineUtils.convertClip(clip, this, null, geyser);
				//next
				geyserNumber++;
				geyser = getEntityById("geyser"+geyserNumber);
				platform = getEntityById("geyserPlatform"+geyserNumber);
			}
		}
		
		private function goInCave(...args):void
		{
			SceneUtil.lockInput(this);
			SceneInteraction(getEntityById("stanley").get(SceneInteraction)).activated = true;
		}
	}
}