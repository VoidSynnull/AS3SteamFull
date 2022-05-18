package game.systems.animation.procedural
{
	import flash.display.DisplayObjectContainer;
	
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.components.animation.procedural.PerspectiveAnimation;
	import game.data.animation.procedural.PerspectiveAnimationLayerData;
	import game.nodes.animation.procedural.PerspectiveAnimationNode;
	
	public class PerspectiveAnimationSystem extends GameSystem
	{
		public function PerspectiveAnimationSystem()
		{
			super(PerspectiveAnimationNode, updateNode);
			
			super._defaultPriority = SystemPriorities.updateAnim;
		}
		
		private function updateNode(node:PerspectiveAnimationNode, time:Number):void
		{
			var animation:PerspectiveAnimation = node.perspectiveAnimation;
			var layers:Vector.<PerspectiveAnimationLayerData> = animation.layers;
			var layer:PerspectiveAnimationLayerData;
			var displayObject:DisplayObjectContainer;
			var operationResult:Number;
			
			for each(layer in layers)
			{
				operationResult = layer.operation(animation.frame);
				
				if(layer.operationAbs)
				{
					operationResult = Math.abs(operationResult);
				}
				
				layer.displayObject[layer.property] = layer.offset + layer.multiplier * operationResult;
			}
			
			var timeFactor:Number = time / _baseTime;
			animation.frame += animation.step * timeFactor;
		}
		
		private var _baseTime:Number = 1 / 60;
	}
}