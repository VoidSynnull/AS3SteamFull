package game.scene.template.topDown.boatScene
{
	import flash.geom.Point;
	
	import engine.ShellApi;
	import engine.components.Spatial;
	
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	import game.util.Utils;
	
	public class WaterWaveSystem extends GameSystem
	{
		public function WaterWaveSystem()
		{
			super(WaterWaveNode, updateNode, nodeAdded);
			super._defaultPriority = SystemPriorities.moveComplete;
		}
		
		private function updateNode(node:WaterWaveNode, time:Number):void
		{
			var timeFactor:Number = Math.min(1, time / _baseTime);
			node.wave.frame += node.wave.step * timeFactor;
			node.spatial.scaleY = node.wave.baseScale * .5 + Math.sin(node.wave.frame) * .5;
			
			var nextAlpha:Number = .5 + .5 * Math.sin(node.wave.frame);
			var appearing:Boolean = false;
			
			if(nextAlpha > node.display.alpha)
			{
				appearing = true;
			}
			
			node.display.alpha = nextAlpha;

			if(appearing)
			{
				if(!node.wave.appearing)
				{
					// when the sine wave switches 'direction', we reposition the wave if it is invisible.
					node.wave.appearing = true;
					setAtRandomLocationInViewport(node.spatial, super.group.shellApi);
				}
			}
			else
			{
				node.wave.appearing = false;
			}
		}
		
		private function nodeAdded(node:WaterWaveNode):void
		{
			setToInitialPosition(node.spatial, node.wave);
		}
		
		private function setToInitialPosition(spatial:Spatial, wave:WaterWave):void
		{
			setAtRandomLocationInViewport(spatial, super.group.shellApi);
			spatial.rotation = 45 + Utils.randNumInRange(-5, 5);
			
			if (Math.random() < 0.5) 
			{
				spatial.scaleY *= -1;
			}
			
			wave.baseScale = spatial.scaleX = spatial.scaleY = Utils.randNumInRange(.5, 1);
			wave.frame = Math.random() * 6;	
		}
		
		private function setAtRandomLocationInViewport(spatial:Spatial, shellApi:ShellApi):void
		{
			var x:Number = -shellApi.camera.x - shellApi.viewportWidth * .5;
			var y:Number = -shellApi.camera.y - shellApi.viewportHeight * .5;
			var position:Point = GeomUtils.getRandomPositionInside(x, y, x + shellApi.viewportWidth, y + shellApi.viewportHeight);
			
			spatial.x = position.x;
			spatial.y = position.y;
		}
		
		private var _baseTime:Number = 1 / 60;
	}
}