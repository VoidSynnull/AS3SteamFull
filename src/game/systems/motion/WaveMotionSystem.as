package game.systems.motion
{
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	
	import game.components.motion.WaveMotion;
	import game.data.WaveMotionData;
	import game.nodes.motion.WaveMotionNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	public class WaveMotionSystem extends GameSystem
	{
		public function WaveMotionSystem()
		{
			super( WaveMotionNode, updateNode );
			super._defaultPriority = SystemPriorities.move;
		}
		
		// Currently ignoring time as wave motion based components don't need to make up lost time like standard velocity components that move entities around the screen.
		private function updateNode( node:WaveMotionNode, time:Number):void
		{
			var spatial:Spatial = node.spatial;
			var waveMotion:WaveMotion = node.waveMotion;
			var spatialAddition:SpatialAddition = node.spatialAddition;
			var waveMotionData:WaveMotionData;
			
			for(var n:uint = 0; n < waveMotion.data.length; n++)
			{
				waveMotionData = waveMotion.data[n];
				
				if(spatialAddition != null)
				{
					spatialAddition[waveMotionData.property] = Math[waveMotionData.type](waveMotionData.radians) * waveMotionData.magnitude;
				}
				else
				{
					spatial[waveMotionData.property] += Math[waveMotionData.type](waveMotionData.radians) * waveMotionData.magnitude;
				}
				
				waveMotionData.radians += waveMotionData.useTime ? waveMotionData.rate * time : waveMotionData.rate;
				
				if (waveMotion.subside) 
				{
					if (!isNaN(waveMotionData.normalValue)) 
					{
						//trace("subside, cur", spatialAddition[waveMotionData.property], "norm", waveMotion.normalValue);
						if (Math.abs(spatialAddition[waveMotionData.property] - waveMotionData.normalValue) < waveMotionData.rate) 
						{
							waveMotion.subside = false;
							node.entity.remove(WaveMotion);
							(node.entity.get(SpatialAddition) as SpatialAddition).reset();
						}
					}
				}
			}
		}
	}
}
