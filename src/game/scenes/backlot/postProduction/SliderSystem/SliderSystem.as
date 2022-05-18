package game.scenes.backlot.postProduction.SliderSystem
{
	import flash.geom.Point;
	
	import game.systems.GameSystem;
	
	public class SliderSystem extends GameSystem
	{
		public function SliderSystem()
		{
			super(SliderNode, updateNode);
		}
		
		private function updateNode(node:SliderNode, time:Number):void
		{
			if(!node.slider.enabled)
			{
				node.slider.drag = false;
				node.display.alpha = .5;
			}
			else
				node.display.alpha = 1;
			
			if(!node.slider.drag)
			{
				node.spatial.x = node.slider.origin.x;
				node.spatial.y = node.slider.origin.y;
				node.spatial.rotation = 0;
				return;
			}
			
			var potentialPosition:Point = new Point(node.slider.dragger.x, node.slider.dragger.y);
			potentialPosition.x /= node.slider.scale.x;
			potentialPosition.y /= node.slider.scale.y;
			potentialPosition.x -= node.slider.offset.x;
			potentialPosition.y -= node.slider.offset.y;
			
			if(node.slider.sliderType == node.slider.VERTICAL)
				potentialPosition.x = node.slider.origin.x;
			
			if(node.slider.sliderType == node.slider.HORIZONTAL)
				potentialPosition.y = node.slider.origin.y;
			
			potentialPosition = restrictPosition(node.slider, potentialPosition);
			
			node.slider.value = findCosAndSinOfRotation(findRotationBetween2Points(node.slider.origin, potentialPosition));
			
			var distance:Number = Point.distance(potentialPosition, node.slider.origin);
			
			node.slider.value.x *= distance / node.slider.maxDistance;
			node.slider.value.y *= distance / node.slider.maxDistance;
			
			node.spatial.x = potentialPosition.x;
			node.spatial.y = potentialPosition.y;
			node.spatial.rotation = node.slider.rotation * 180 / Math.PI;
		}
		
		private function restrictPosition(slider:Slider, potentialPosition:Point):Point
		{
			var distance:Number = Point.distance(potentialPosition, slider.origin);
			if(slider.originType == slider.MIN_POINT)
			{
				if(slider.sliderType == slider.HORIZONTAL)
				{
					if(potentialPosition.x < slider.origin.x)
						potentialPosition.x = slider.origin.x;
					if(potentialPosition.x > slider.origin.x + slider.maxDistance)
						potentialPosition.x = slider.origin.x + slider.maxDistance;
				}
				if(slider.sliderType == slider.VERTICAL)
				{
					if(potentialPosition.y > slider.origin.y)
						potentialPosition.y = slider.origin.y;
					if(potentialPosition.y < slider.origin.y - slider.maxDistance)
						potentialPosition.y = slider.origin.y - slider.maxDistance;
				}
			}
			if(slider.originType == slider.MAX_POINT)
			{
				if(slider.sliderType == slider.HORIZONTAL)
				{
					if(potentialPosition.x > slider.origin.x)
						potentialPosition.x = slider.origin.x;
					if(potentialPosition.x < slider.origin.x - slider.maxDistance)
						potentialPosition.x = slider.origin.x - slider.maxDistance;
				}
				if(slider.sliderType == slider.VERTICAL)
				{
					if(potentialPosition.y < slider.origin.y)
						potentialPosition.y = slider.origin.y;
					if(potentialPosition.y > slider.origin.y + slider.maxDistance)
						potentialPosition.y = slider.origin.y + slider.maxDistance;
				}
			}
			if(slider.originType == slider.CENTER)
			{
				if(slider.sliderType == slider.HORIZONTAL)
				{
					if(potentialPosition.x > slider.origin.x + slider.maxDistance)
						potentialPosition.x = slider.origin.x + slider.maxDistance;
					if(potentialPosition.x < slider.origin.x - slider.maxDistance)
						potentialPosition.x = slider.origin.x - slider.maxDistance;
				}
				if(slider.sliderType == slider.VERTICAL)
				{
					if(potentialPosition.y < slider.origin.y - slider.maxDistance)
						potentialPosition.y = slider.origin.y - slider.maxDistance;
					if(potentialPosition.y > slider.origin.y + slider.maxDistance)
						potentialPosition.y = slider.origin.y + slider.maxDistance;
				}
				if(slider.sliderType == slider.RADIAL)
				{
					slider.rotation = findRotationBetween2Points(slider.origin, potentialPosition);
					var cosAndSin:Point = findCosAndSinOfRotation(slider.rotation);
					if(distance > slider.maxDistance)
					{
						potentialPosition.y = slider.origin.y + cosAndSin.y * slider.maxDistance;
						potentialPosition.x = slider.origin.x + cosAndSin.x * slider.maxDistance;
					}
				}
			}
			return potentialPosition;
		}
		
		private function findRotationBetween2Points(origin:Point, point2:Point):Number
		{
			var deltaY:Number = point2.y - origin.y;
			var deltaX:Number = point2.x - origin.x;
			var rotation:Number = Math.atan2(deltaY, deltaX);
			return rotation;
		}
		
		private function findCosAndSinOfRotation(rotation:Number):Point
		{
			return new Point(Math.cos(rotation), Math.sin(rotation));
		}
	}
}