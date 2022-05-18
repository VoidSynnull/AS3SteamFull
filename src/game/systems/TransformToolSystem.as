package game.systems
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.util.PointUtils;
	import game.data.photobooth.TransformData;
	import game.nodes.TransformToolNode;
	
	public class TransformToolSystem extends GameSystem
	{
		public function TransformToolSystem()
		{
			super(TransformToolNode, updateNode, nodeAdded, nodeRemoved);
		}
		
		private function updateNode(node:TransformToolNode, time:Number):void
		{
			if(node.target.target == null || !node.tool.updateTarget)
				return;
			
			node.tool.currentPoint = new Point(node.display.displayObject.mouseX, node.display.displayObject.mouseY);
			
			for each( var data:TransformData in node.tool.transformDatas)
			{
				updateProperty(node, data);
			}
		}
		
		private function updateProperty(node:TransformToolNode, data:TransformData):void
		{
			var val:Number;
			var currentPoint:Point = node.tool.currentPoint;
			var initPoint:Point = node.tool.initPoint;
			
			switch(data.property)
			{
				case "scale":
				{
					val = ((initPoint.y - currentPoint.y) + (currentPoint.x - initPoint.x)) * data.scale;
					break;
				}
				case "scaleX":
				{
					val = (currentPoint.x - initPoint.x) * data.scale;
					break;
				}
				case "scaleY":
				{
					val = (initPoint.y - currentPoint.y) * data.scale;
					break;
				}
				case "rotation":
				{
					val = PointUtils.getRadiansBetweenPoints(initPoint, currentPoint) * 180 / Math.PI;
					break;
				}
			}
			
			if(isNaN(val))
				return;
			
			val += data.initVal;
			
			if(data.property == "scale")
			{
				if(val <= 0)
					val = data.scale;
			}
			
			if(!isNaN( data.valueIncrement))
			{
				val = Math.ceil(  val / data.valueIncrement) * data.valueIncrement
			}
			
			node.target.target[data.property] = val;
		}
		
		private function startTool(entity:Entity, node:TransformToolNode):void
		{
			if(node.target.target == null)
				return;
			
			node.tool.updateTarget = true;
			
			node.tool.currentPoint = new Point(node.display.displayObject.mouseX, node.display.displayObject.mouseY);
			
			node.tool.initPoint = new Point(-node.spatial.x,- node.spatial.y); // set initPoint to center of tool
			
			var currentPoint:Point = node.tool.currentPoint;
			var initPoint:Point = node.tool.initPoint;
			
			//get initial value of property and then offset it based off current point 
			//(so it doesnt snap to that value) but starts at actual initial value
			
			for each( var data:TransformData in node.tool.transformDatas)
			{
				data.initVal = node.target.target[data.property];
				
				switch(data.property)
				{
					case "scale":
					{
						data.initVal -= ((initPoint.y - currentPoint.y) + (currentPoint.x - initPoint.x)) * data.scale;
						break;
					}
					case "scaleX":
					{
						data.initVal -= (currentPoint.x - initPoint.x) * data.scale;
						break;
					}
					case "scaleY":
					{
						data.initVal -= (initPoint.y - currentPoint.y) * data.scale;
						break;
					}
					case "rotation":
					{
						data.initVal -= PointUtils.getRadiansBetweenPoints(new Point(),currentPoint.subtract(initPoint)) * 180 / Math.PI;
						break;
					}
				}
			}
			
			node.tool.transformStart.dispatch(entity);
		}
		
		private function stopTool(entity:Entity, node:TransformToolNode):void
		{
			node.tool.transformComplete.dispatch(entity);
			node.tool.updateTarget = false;
			node.tool.initPoint = node.tool.currentPoint = null;
		}
		
		private function nodeAdded(node:TransformToolNode):void
		{
			node.interaction.down.add(Command.create(startTool, node));
			node.interaction.up.add(Command.create(stopTool, node));
			node.interaction.releaseOutside.add(Command.create(stopTool, node));
		}
		
		private function nodeRemoved(node:TransformToolNode):void
		{
			node.interaction.down.remove(startTool);
			node.interaction.up.remove(stopTool);
			node.interaction.releaseOutside.remove(stopTool);
		}
	}
}