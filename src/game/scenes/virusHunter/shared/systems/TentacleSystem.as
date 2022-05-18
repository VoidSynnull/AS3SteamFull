package game.scenes.virusHunter.shared.systems 
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.shared.data.TentacleDisplayData;
	import game.scenes.virusHunter.shared.nodes.TentacleNode;
	import game.systems.GameSystem;
	import game.util.Utils;

	public class TentacleSystem extends GameSystem
	{
		public function TentacleSystem()
		{
			super(TentacleNode, updateNode);
		}
		
		private function updateNode(node:TentacleNode, time:Number):void
		{
			if(node.sleep.sleeping) return;
			
			/**
			 * If the Tentacle is paused, do not update its animation.
			 * This will still draw the Tentacle on every update though,
			 * so other things can be done to its variables elsewhere.
			 */
			if(!node.tentacle.isPaused)
			{
				/**
				 * Calculate the distance of the Tentacle's "Target"
				 * Spatial from the Tentacle's Spatial or its "Reference" Spatial.
				 * Reference is used in case the Tentacle is inside another container,
				 * which would cause Spatial comparisons to be incorrect.
				 */
				var spatial:Spatial;
				if(node.tentacle.reference != null) spatial = node.tentacle.reference;
				else spatial = node.spatial;
				
				/**
				 * If the Tentacle has a target Spatial to flail at, calulate the distance.
				 * If it doesn't, it will flail at its slowest speed.
				 */
				var distance:Number;
				if(node.tentacle.target)
				{
					/**
					 * Tentacles have a min and max distance they will flail at.
					 * MinDistance is how close the target can get and how fast the Tentacle will flail.
					 * MaxDistance is how far the target can get and how slow the Tentacle will flail.
					 */
					distance = Utils.distance(spatial.x, spatial.y, node.tentacle.target.x, node.tentacle.target.y);
					if(distance < node.tentacle.minDistance) distance = node.tentacle.minDistance;
					else if(distance > node.tentacle.maxDistance) distance = node.tentacle.maxDistance;
				}
				else distance = node.tentacle.maxDistance;
				
				/**
				 * MinDistance is subtracted from maxDistance and distance to get a scale of 0 to maxDistance;
				 * Ratio is a 0-1 scale of how close or far the target is from the Tentacle.
				 */
				var max:Number = node.tentacle.maxDistance - node.tentacle.minDistance;
				distance -= node.tentacle.minDistance;
				var ratio:Number = (max - distance) / max;
				
				/**
				 * Calculate how much a Tentacle will curl and how fast it will move.
				 */
				var magnitude:Number = node.tentacle.minMagnitude + (ratio * (node.tentacle.maxMagnitude - node.tentacle.minMagnitude));
				var speed:Number = node.tentacle.minSpeed + (ratio * (node.tentacle.maxSpeed - node.tentacle.minSpeed));
				node.tentacle.time += speed * time;
				
				/**
				 * Calculates all Tentacle segment points based on magnitude.
				 * More mystical math!
				 */
				var radians:Number = magnitude * Math.sin(node.tentacle.time);
				for(var i:uint = 1; i < node.tentacle.segments.size; i++)
				{
					var current:Point = node.tentacle.segments.itemAt(i);
					var previous:Point = node.tentacle.segments.itemAt(i - 1);
					
					radians += magnitude * Math.sin(node.tentacle.time - node.tentacle.delay * i);
					current.x = previous.x + node.tentacle.getSegmentLength() * Math.cos(radians);
					current.y = previous.y + node.tentacle.getSegmentLength() * Math.sin(radians);
				}
			}
			
			/**
			 * Clear the current Tentacle graphics and draw again.
			 * This draws a Tentacle color for every TentacleData
			 * in a Tentacle's colorData arraylist.
			 */
			Sprite(node.display.displayObject).graphics.clear();
			for(var j:uint = 0; j < node.tentacle.displayData.size; j++)
			{
				var data:TentacleDisplayData = node.tentacle.displayData.itemAt(j);
				drawCurve(node, data.color, data.startWidth, data.endWidth);
			}
		}
		
		private function drawCurve(node:TentacleNode, color:uint, startWidth:Number, endWidth:Number):void
		{
			var width:Number = startWidth;
			var decline:Number = (endWidth - startWidth) / node.tentacle.segments.size;
			
			var display:Sprite = Sprite(node.display.displayObject);
			display.graphics.lineStyle(width, color);
			display.graphics.moveTo(0, 0);
			
			for(var i:uint = 0; i < node.tentacle.segments.size - 1; i++)
			{
				width += decline;
				display.graphics.lineStyle(width, color);
				
				var current:Point = node.tentacle.segments.itemAt(i);
				var next:Point = node.tentacle.segments.itemAt(i + 1);
				
				var mX:Number = (current.x + next.x) / 2;
				var mY:Number = (current.y + next.y) / 2;
				display.graphics.curveTo(current.x, current.y, mX, mY);
			}
		}
	}
}