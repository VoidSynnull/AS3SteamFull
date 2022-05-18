package game.systems.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	
	import game.nodes.specialAbility.SparksNode;
	import game.systems.GameSystem;
	import game.util.Utils;
	
	public class SparksSystem extends GameSystem
	{
		public function SparksSystem()
		{
			super(SparksNode, updateNode, null, nodeRemoved);
		}
		
		private function updateNode(node:SparksNode, time:Number):void
		{
			var index:int;
			var spark:Shape;
			
			node.sparks.elapsedTime += time;
			
			if(node.sparks.elapsedTime >= 0.05)
			{
				node.sparks.elapsedTime = 0;
				
				spark = new Shape();
				
				var container:DisplayObjectContainer = node.display.displayObject;
				container.mouseEnabled = false;
				container.mouseChildren = false;
				
				var x:Number = Utils.randNumInRange(node.sparks.bounds.left, node.sparks.bounds.right);
				var y:Number = Utils.randNumInRange(node.sparks.bounds.top, node.sparks.bounds.bottom);
				spark.graphics.lineStyle(3, 0xFFFFFF);
				spark.graphics.moveTo(x, y);
				
				for(index = 0; index < 3; ++index)
				{
					x += Utils.randNumInRange(-12, 12);
					y += Utils.randNumInRange(-12, 12);
					spark.graphics.lineTo(x, y);
				}
				
				container.addChild(spark);
				node.sparks.sparks.push(spark);
			}
			
			for(index = node.sparks.sparks.length - 1; index > -1; --index)
			{
				spark = node.sparks.sparks[index];
				
				spark.alpha -= 2 * time;
				
				if(spark.alpha <= 0)
				{
					spark.parent.removeChild(spark);
					node.sparks.sparks.splice(index, 1);
				}
			}
		}
		
		private function nodeRemoved(node:SparksNode):void
		{
			for each(var spark:Shape in node.sparks.sparks)
			{
				spark.parent.removeChild(spark);
			}
			node.sparks.sparks.length = 0;
		}
	}
}