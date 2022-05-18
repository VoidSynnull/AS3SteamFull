package game.scenes.time.greece2.systems
{

	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import game.scenes.time.greece2.components.SmokeWisp;
	import game.scenes.time.greece2.components.smokePoint;
	import game.scenes.time.greece2.nodes.SmokeWispNode;
	import game.systems.GameSystem;
	
	
	public class SmokeWispSystem extends GameSystem
	{
		public function SmokeWispSystem()
		{
			super(SmokeWispNode, updateNode, addNode);
		}
		public override function addToEngine(engine:Engine):void
		{
			super.addToEngine(engine);
		}
		
		private function addNode(node:SmokeWispNode):void
		{
			var smokeWisp:SmokeWisp = node.smokeWisp;
			addWispPoint(smokeWisp);
		}
		
		private function updateNode(node:SmokeWispNode, time:Number):void
		{
			var smokeWisp:SmokeWisp = node.smokeWisp;
			addWispPoint(smokeWisp);
			moveWispPoints(smokeWisp);
			drawline(smokeWisp);
		}
		
		// populates smokeWisp's vector with points to draw lines along
		public function addWispPoint(smokeWisp:SmokeWisp): void
		{	
			wait++;
			if(wait > 5)
			{
				wait = 0;				
				var pt:smokePoint = new smokePoint(0,0,Math.random() * 1 - 0.5,-2)
				smokeWisp.drawPoints.unshift(pt);
				pointCount = smokeWisp.drawPoints.length;
			}
		}
		
		// moves points upwards
		public function moveWispPoints(smokeWisp:SmokeWisp): void
		{
			for (var i:int = 0; i < smokeWisp.drawPoints.length; i++) 
			{
				var point:smokePoint = smokeWisp.drawPoints[i];
				point.x += point.velX;
				point.y += point.velY;
				// accelerate over time
				point.velX += point.velX * 0.001;
				point.velY += point.velY * 0.002;
				if(point.y < -1000)
				{
					smokeWisp.drawPoints.splice(i,1);
				}
				smokeWisp.drawPoints[i] = point;
			}			
		}
		
		// draw smoke line using graphics.curveto
		public function drawline(smokeWisp:SmokeWisp): void
		{		
			var lineClip:MovieClip = smokeWisp.lineMc; 
			var shiftRange:Number = smokeWisp.shiftRange;
			lineClip.graphics.clear();
			lineAlpha = 0.25;
			lineClip.graphics.lineStyle(2, lineColor, lineAlpha, false);
			lineClip.graphics.moveTo(0, 0);
			for (var i:int = 0; i < smokeWisp.drawPoints.length; i++) 
			{
				var currPt:smokePoint = smokeWisp.drawPoints[i];
				if(i+1 < smokeWisp.drawPoints.length){
					var nextPt:Point = smokeWisp.drawPoints[i+1];
					if(nextPt != null){
						var midX:Number = ((nextPt.x + currPt.x)/2);
						var midY:Number = ((nextPt.y + currPt.y)/2);
						lineClip.graphics.curveTo(currPt.x,currPt.y,midX,midY);
					}		
				}
				lineAlpha -= lineAlpha * 0.04;
				lineClip.graphics.lineStyle(2, lineColor, lineAlpha, false, "normal", "none");
			}
		}	
			
		public var lineAlpha:Number = 0.20;
		private var pointCount:Number = 0;
		private var wait:Number = 0;
		private var lineColor:uint = 0xCBC998;
	}
}





















