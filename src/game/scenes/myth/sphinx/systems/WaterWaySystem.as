package game.scenes.myth.sphinx.systems
{
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import game.scenes.myth.sphinx.components.WaterWayComponent;
	import game.scenes.myth.sphinx.nodes.WaterWayNode;
	import game.systems.GameSystem;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	public class WaterWaySystem extends GameSystem
	{
		public function WaterWaySystem()
		{
			super( WaterWayNode, updateNode );
		}
		
		private function updateNode( node:WaterWayNode, time:Number ):void
		{
			var waterWay:WaterWayComponent = node.waterWay;
			var display:Display = node.display;
			var emitterEntity:Entity;
			var emitter:Emitter2D;
			var entity:Entity = node.entity;
			var audio:Audio = node.audio;
			
			if( waterWay.isOn )
			{
				display.visible = true;
				node.timeline.playing = true;
				// TODO :: should wake up children to sleep
								
				if( waterWay.isFall )
				{
					audio.playCurrentAction( TRIGGER );
						
					if( waterWay.feedsInto )
					{
						waterWay.feedsInto.isOn = true;
					}
					
					if( !waterWay.foamOn )
					{
						waterWay.emitter.start = true;
						waterWay.foamOn = true;
					}
				}
				
				else
				{
					audio.playCurrentAction( TRIGGER );
				}
			}
			else
			{
				display.visible = false;
				node.timeline.playing = false;
				// TODO :: should put children to sleep
				
				if( waterWay.isFall )
				{
					audio.stopActionAudio( TRIGGER );
					
					if( waterWay.feedsInto )
					{
						waterWay.feedsInto.isOn = false;
					}
					
					if( waterWay.foamOn )
					{
						waterWay.emitter.stop = true;
						waterWay.foamOn = false;
					}
				}
				
				else
				{
					audio.stopActionAudio( TRIGGER );
				}
			}
		}
		
		private static const TRIGGER:String =	"trigger";
	}
}