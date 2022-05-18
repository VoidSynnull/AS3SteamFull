package game.systems.ui
{
	import game.data.motion.time.FixedTimestep;
	import game.nodes.ui.SliderNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.Utils;
	
	public class SliderSystem extends GameSystem
	{
		public function SliderSystem()
		{
			super(SliderNode, updateNode);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			this._defaultPriority = SystemPriorities.move;
		}
		
		private function updateNode(node:SliderNode, time:Number):void
		{
			var min:Number;
			var max:Number;
			var temp:Number;
			switch(node.draggable.axis)
			{
				case "x":
					min = node.bounds.box.left;
					max = node.bounds.box.right;
					
					if(node.edge)
					{
						min -= node.edge.rectangle.left;
						max -= node.edge.rectangle.right;
					}
					
					if(node.slider.inverse)
					{
						temp = min;
						min = max;
						max = temp;
					}
					
					if(node.draggable._active)
					{
						node.ratio.decimal = Utils.toDecimal(node.spatial.x, min, max);
					}
					else
					{
						node.spatial.x = Utils.fromDecimal(node.ratio.decimal, min, max);
					}
					break;
				
				case "y":
					min = node.bounds.box.top;
					max = node.bounds.box.bottom;
					
					if(node.edge)
					{
						min -= node.edge.rectangle.top;
						max -= node.edge.rectangle.bottom;
					}
					
					if(node.slider.inverse)
					{
						temp = min;
						min = max;
						max = temp;
					}
					
					if(node.draggable._active)
					{
						node.ratio.decimal = Utils.toDecimal(node.spatial.y, min, max);
					}
					else
					{
						node.spatial.y = Utils.fromDecimal(node.ratio.decimal, min, max);
					}
					break;
			}
		}
	}
}