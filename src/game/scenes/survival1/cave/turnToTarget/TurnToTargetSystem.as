package game.scenes.survival1.cave.turnToTarget
{
	import engine.components.Spatial;
	
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class TurnToTargetSystem extends GameSystem
	{
		public function TurnToTargetSystem()
		{
			super(TurnToTargetNode, updateNode);
			
			this._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode(node:TurnToTargetNode, time:Number):void
		{
			var spatial:Spatial = node.spatial;
			var target:Spatial 	= node.turn.target;
			
			switch(node.turn.axis)
			{
				case "x":
					this.checkScaleX(spatial, target, node.turn.offsetX, node.turn.reverseX);
					break;
				
				case "y":
					this.checkScaleY(spatial, target, node.turn.offsetY, node.turn.reverseY);
					break;
				
				default:
					this.checkScaleX(spatial, target, node.turn.offsetX, node.turn.reverseX);
					this.checkScaleY(spatial, target, node.turn.offsetY, node.turn.reverseY);
					break;
			}		
		}
		
		private function checkScaleX(spatial:Spatial, target:Spatial, offset:Number, reverse:Boolean):void
		{
			if(target.x > spatial.x + offset)
			{
				if(!reverse && spatial.scaleX < 0) 	spatial.scaleX *= -1;
				if(reverse && spatial.scaleX > 0) 	spatial.scaleX *= -1;
			}
			else
			{
				if(!reverse && spatial.scaleX > 0) 	spatial.scaleX *= -1;
				if(reverse && spatial.scaleX < 0) 	spatial.scaleX *= -1;
			}
		}
		
		private function checkScaleY(spatial:Spatial, target:Spatial, offset:Number, reverse:Boolean):void
		{
			if(target.y > spatial.y + offset)
			{
				if(!reverse && spatial.scaleY < 0) 	spatial.scaleY *= -1;
				if(reverse && spatial.scaleY > 0) 	spatial.scaleY *= -1;
			}
			else
			{
				if(!reverse && spatial.scaleY > 0) 	spatial.scaleY *= -1;
				if(reverse && spatial.scaleY < 0) 	spatial.scaleY *= -1;
			}
		}
	}
}