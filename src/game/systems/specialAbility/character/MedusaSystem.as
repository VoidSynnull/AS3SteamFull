package game.systems.specialAbility.character
{
	import flash.display.MovieClip;
	import flash.display.Shape;
	
	import game.nodes.specialAbility.character.MedusaNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	public class MedusaSystem extends GameSystem
	{
		public function MedusaSystem()
		{
			super( MedusaNode, updateNode );
			super._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode( node:MedusaNode, time : Number ) : void
		{
			for(var i:Number = 0; i < node.display.displayObject.numChildren; i++)
			{
				if(!node.medusa.snakesInit)
				{
					initSnake(node, node.display.displayObject.getChildAt(i) as MovieClip);
				} else {
					updateSnake(node.display.displayObject.getChildAt(i) as MovieClip, i, node);
				}
			}
			
			if(!node.medusa.snakesInit)
			{
				node.medusa.snakesInit = true;
			}	
		}
		
		private function initSnake(node:MedusaNode, clip:MovieClip):void
		{
			var shape:Shape = new Shape();
			clip.addChildAt(shape, 0);
			
			var obj:Object = new Object();
			obj.r = Math.random()*10 + 15;
			obj.mag = 30;
			obj.tOffset = Math.random()*3;
			obj.tSpeed = Math.random()*0.05 + 0.08;
			obj.thickness = Math.round(Math.random()*6) + 24;
			obj.graphics = shape.graphics;
			obj.points = new Array();
			node.medusa.snakes.push(obj);
		}
		
		private function updateSnake(clip:MovieClip, index:Number, node:MedusaNode):void
		{	
			if( clip == null ) 	{ return; }
			
			var data:Object = node.medusa.snakes[index];
			
			// Update points
			var partClip:MovieClip;
			for (var i:Number = 0; i <= 5; i++)
			{	
				partClip = clip.getChildByName("p" + i) as MovieClip;
				if( partClip != null )
				{
					if(data.points.length < 6)
					{
						var pointData:Object = new Object();
						pointData.num = i;
						pointData.t = data.tOffset - i;
						pointData.x = partClip.x;
						pointData.y = partClip.y;
						data.points.push(pointData);
					}
					if (i == 5) {
						partClip.visible = false;
					}
					movePoint(partClip, index, i, node);
				}
			}
			
			// Update Head
			var head:MovieClip = clip.getChildByName("head") as MovieClip;
			var p0:MovieClip = clip.getChildByName("p0") as MovieClip;
			var p4:MovieClip = clip.getChildByName("p4") as MovieClip;
			var p5:MovieClip = clip.getChildByName("p5") as MovieClip;
			head.x = (p4.x + p5.x)/2;
			head.y = (p4.y + p5.y)/2;
			head.rotation = -clip.rotation;
			
			// Draw snake body
			data.graphics.clear();
			
			data.lineWidth = data.thickness;
			data.graphics.lineStyle(data.lineWidth, 0x3C4C33);
			data.graphics.moveTo(p0.x, p0.y);
			for (var j:Number = 0; j <= 4; j++) {
				data.lineWidth -= 1;
				data.graphics.lineStyle(data.lineWidth, 0x3C4C33);
				
				var pa:MovieClip = clip.getChildByName("p" + j) as MovieClip;
				var pb:MovieClip = clip.getChildByName("p" + (j + 1)) as MovieClip;
				var mX:Number = (pa.x + pb.x)/2;
				var mY:Number = (pa.y + pb.y)/2;
				data.graphics.curveTo(pa.x, pb.y, mX, mY);
			}
			
			data.lineWidth = data.thickness - 5;
			data.graphics.lineStyle(data.lineWidth, 0x799766);
			data.graphics.moveTo(p0.x, p0.y);
			for (var k:Number = 0; k <= 4; k++) 
			{
				data.lineWidth -= 1;
				data.graphics.lineStyle(data.lineWidth, 0x799766);
				
				var pak:MovieClip = clip.getChildByName("p" + k) as MovieClip;
				var pbk:MovieClip = clip.getChildByName("p" + (k + 1)) as MovieClip;
				var mXk:Number = (pak.x + pbk.x)/2;
				var mYk:Number = (pak.y + pbk.y)/2;
				data.graphics.curveTo(pak.x, pbk.y, mXk, mYk);
			}
		}
		
		private function movePoint(clip:MovieClip, snakeIndex:Number, pointIndex:Number, node:MedusaNode):void
		{
			var data:Object = node.medusa.snakes[snakeIndex];
			var pointData:Object = data.points[pointIndex];
			
			pointData.t += data.tSpeed;
			pointData.radians = 1*Math.sin(pointData.t);
			if (pointData.num != 0)
			{
				var targdata:Object = node.medusa.snakes[snakeIndex].points[pointIndex-1];
				
				clip.x = targdata.x - data.r*Math.cos(targdata.radians);
				pointData.x = clip.x;
				clip.y = targdata.y - data.r*Math.sin(targdata.radians);
				pointData.y = clip.y;
				pointData.radians += targdata.radians;
			}
		}
	}
}