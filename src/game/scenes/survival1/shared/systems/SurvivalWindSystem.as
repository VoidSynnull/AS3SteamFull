package game.scenes.survival1.shared.systems
{
	
	import engine.managers.SoundManager;
	
	import game.data.motion.time.FixedTimestep;
	import game.data.sound.SoundModifier;
	import game.scenes.survival1.shared.nodes.SurvivalWindNode;
	import game.systems.GameSystem;
	import game.util.PerformanceUtils;
	import game.util.Utils;
	
	public class SurvivalWindSystem extends GameSystem
	{
		private static const MP3:String = 		".mp3";
		private static const WINDS:String = 	"winter_wind_gust_0";
		
		public static var updateRatio:int = 1;
		
		public function SurvivalWindSystem(ratio:int = -1)
		{
			if(ratio == -1)
				ratio = (100 - PerformanceUtils.qualityLevel);
			else
				ratio = 100 - ratio;
			updateRatio = 1 + ratio / 10;
			
			super(SurvivalWindNode, updateNode);
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
		}
		
		private var frame:int = 0;
		
		public function updateNode(node:SurvivalWindNode, time:Number):void
		{
			node.wind.changeTime += time / node.wind.windChangeTime * Math.PI;
			
			if(node.wind.changeTime > Math.PI * 2)
				node.wind.changeTime = 0;
			
			var direction:int = 1;
			
			var val:Number = Math.sin(node.wind.changeTime);
			
			var power:Number = node.wind.windSwingPower;
			
			if(val < 0 && power % 2 == 0)
				direction = -1;
			
			++frame;
			if(frame < updateRatio)
				return;
			
			frame = 0;
			
			node.wind.changeWindDirection( Math.pow( val, power) * direction);
			//return;
			// wind sounds
			var winds:int = 0;
			if( node.wind.strongWinds )
			{
				for( var number:int = 1; number < 4; number ++ )
				{
					if( !node.audio.isPlaying( SoundManager.EFFECTS_PATH + WINDS + number + MP3 ))
					{
						winds ++;
					}	
				}
				
				if( winds == 3 )
				{
					number = Utils.randInRange( 1, 3 );
					node.audio.play( SoundManager.EFFECTS_PATH + WINDS + number + MP3, SoundModifier.FADE );
				}
			}
			
			else
			{
				for( number = 1; number < 4; number ++ )
				{
					if( node.audio.isPlaying( SoundManager.EFFECTS_PATH + WINDS + number + MP3 ))
					{
						node.audio.stop( SoundManager.EFFECTS_PATH + WINDS + number + MP3 );
					}
				}
			}
		}
	}
}