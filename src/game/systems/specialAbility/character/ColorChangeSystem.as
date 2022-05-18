package game.systems.specialAbility.character
{
	import flash.geom.ColorTransform;
	
	import game.nodes.specialAbility.ColorChangeNode;
	import game.systems.GameSystem;
	import game.util.ColorUtil;
	
	public class ColorChangeSystem extends GameSystem
	{
		public function ColorChangeSystem()
		{
			super(ColorChangeNode, updateNode);
		}
		
		private function updateNode( node:ColorChangeNode, time:Number):void
		{
			if(node.colorChanger.colors == null || node.colorChanger.colors.length < 1 || node.colorChanger.changeTime == 0)
				return;// break out of invalid configurations
			
			// prepare for next color change
			if(node.colorChanger.time >= node.colorChanger.changeTime || node.colorChanger.index == -1)
			{
				node.colorChanger.index++;
				if(node.colorChanger.index >= node.colorChanger.colors.length)//loop back to start
					node.colorChanger.index = 0;
				
				node.colorChanger.startColor.color = node.colorChanger.colors[node.colorChanger.index];
				var nextIndex:int = node.colorChanger.index + 1;
				if(nextIndex >= node.colorChanger.colors.length)// if start is at the end then the next should loop back to the start
					nextIndex = 0;
				
				node.colorChanger.nextColor.color = node.colorChanger.colors[nextIndex];
				node.colorChanger.time = 0;
				
				ColorUtil.colorize(node.display.displayObject, node.colorChanger.startColor.color);
				return;// initialize then reset for next iteration
			}
			
			node.colorChanger.time += time;
			
			var percent:Number = node.colorChanger.time / node.colorChanger.changeTime;
			var start:ColorTransform = node.colorChanger.startColor
			var end:ColorTransform = node.colorChanger.nextColor;
			
			var currentColor:ColorTransform = new ColorTransform();
			currentColor.redMultiplier = start.redMultiplier + (end.redMultiplier - start.redMultiplier) * percent;
			currentColor.greenMultiplier = start.greenMultiplier + (end.greenMultiplier - start.greenMultiplier) * percent;
			currentColor.blueMultiplier = start.blueMultiplier + (end.blueMultiplier - start.blueMultiplier) * percent;
			currentColor.alphaMultiplier = start.alphaMultiplier + (end.alphaMultiplier - start.alphaMultiplier) * percent;
			currentColor.redOffset = start.redOffset + (end.redOffset - start.redOffset) * percent;
			currentColor.greenOffset = start.greenOffset + (end.greenOffset - start.greenOffset) * percent;
			currentColor.blueOffset = start.blueOffset + (end.blueOffset - start.blueOffset) * percent;
			currentColor.alphaOffset = start.alphaOffset + (end.alphaOffset - start.alphaOffset) * percent;
			ColorUtil.colorize(node.display.displayObject, currentColor.color);
		}
	}
}