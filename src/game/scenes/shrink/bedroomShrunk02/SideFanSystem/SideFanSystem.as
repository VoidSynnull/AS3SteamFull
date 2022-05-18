package game.scenes.shrink.bedroomShrunk02.SideFanSystem
{
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.systems.GameSystem;
	
	public class SideFanSystem extends GameSystem
	{
		public function SideFanSystem()
		{
			super(SideFanNode, updateNode);
		}
		
		public function updateNode(node:SideFanNode, time:Number):void
		{
			if(node.fan.sideViewOfBlades.length == 0 || node.fan.topViewOfBlades.length == 0)
				return;
			
			node.fan.speed *= node.fan.dampening;
			node.fan.rotation += time * node.fan.speed * Math.PI / 180;
			
			if(node.fan.rotation > Math.PI * 2)
				node.fan.rotation -= Math.PI * 2;
			
			var angleDifference:Number = Math.PI * 2 / node.fan.sideViewOfBlades.length;
			
			for(var i:int = 0; i < node.fan.sideViewOfBlades.length; i++)
			{
				var bladeRotation:Number = node.fan.rotation + angleDifference * i;
				
				if(bladeRotation > Math.PI * 2)
					bladeRotation -= Math.PI * 2;
				
				var sideDisplay:Display = node.fan.sideViewOfBlades[i].display
				var topDisplay:Display = node.fan.topViewOfBlades[i].display
				
				if(bladeRotation <= Math.PI)
				{
					sideDisplay.moveToBack();
					topDisplay.moveToBack();
				}
				else
				{
					sideDisplay.moveToFront();
					topDisplay.moveToFront();
				}
				
				var sideSpatial:Spatial = node.fan.sideViewOfBlades[i].spatial;
				var topSpatial:Spatial = node.fan.topViewOfBlades[i].spatial;
				sideSpatial.y = node.spatial.y - Math.cos(bladeRotation) * node.fan.focalRadius;
				sideSpatial.scaleY = Math.cos(bladeRotation);
				topSpatial.y = node.spatial.y - Math.cos(bladeRotation) * node.fan.focalRadius - Math.cos(bladeRotation) * node.fan.bladeLength;
				topSpatial.scaleY = Math.sin(bladeRotation);
				sideDisplay.alpha = Math.abs(Math.cos(bladeRotation));
				topDisplay.alpha = -Math.sin(bladeRotation);
			}
			
			if(!node.fan.on)
				return;
			
			node.fan.speed += node.fan.acc;
			
			if(node.fan.speed > node.fan.maxFanSpeed)
				node.fan.speed = node.fan.maxFanSpeed;
		}
	}
}