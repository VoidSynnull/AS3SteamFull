package game.systems.specialAbility.character
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.specialAbility.character.Balloon;
	import game.nodes.specialAbility.character.BallonNode;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.PointUtils;
	
	
	public class BalloonSystem extends System
	{
		private var _nodes:NodeList;
		private var _balloonColors:Array = [ 0xFF3E3E, 0xFF9900, 0xFBF404, 0x66FF00, 0x0D91F2, 0xA476D1 ];
		
		override public function addToEngine(systemsManager:Engine):void
		{
			_nodes = systemsManager.getNodeList(BallonNode);
			_nodes.nodeRemoved.add( nodeRemoved );
		}
		
		override public function update( time : Number ) : void
		{
			var node:BallonNode;
			
			for ( node = _nodes.head; node; node = node.next )
			{
				var balloon:Balloon = node.balloon;
				var spatial:Spatial = balloon.player.get(Spatial);
				var handspatial:Spatial = CharUtils.getJoint(balloon.player, CharUtils.HAND_FRONT).get(Spatial);
				
				var direction:Number = 1;
				if(spatial.scaleX <0)
					direction *= -1;
				node.followTarget.offset = new Point(handspatial.x*spatial.scaleX + balloon.restingPosition.x * direction, handspatial.y * spatial.scaleY + balloon.restingPosition.y);
				
				var xPos:Number = spatial.x + (handspatial.x * spatial.scaleX);
				var yPos:Number = spatial.y + (handspatial.y * spatial.scale);
				var radians:Number = PointUtils.getRadiansBetweenPoints(new Point(xPos, yPos), new Point(node.spatial.x, node.spatial.y)) + Math.PI / 2;
				node.spatial.rotation = radians * 180 / Math.PI;
				
				// Dynamically draw the line
				var container:DisplayObjectContainer = node.entity.get(Display).container;
				var display:DisplayObjectContainer = node.entity.get(Display).displayObject;
				
				if(!balloon.string)
				{
					balloon.string = new Sprite();
					container.addChild(balloon.string);
					container.swapChildrenAt(container.numChildren-1, container.numChildren-2);
				}
				// make knot position based off rotation
				var knotOffset:Point = balloon.knotPosition;
				knotOffset = new Point(Math.cos(radians) * knotOffset.x - Math.sin(radians) * knotOffset.y, Math.cos(radians) * knotOffset.y + Math.sin(radians) * knotOffset.x);
				
				balloon.string.graphics.clear();
				balloon.string.graphics.lineStyle(balloon.stringThickness, balloon.stringColor);
				balloon.string.graphics.moveTo(node.spatial.x + knotOffset.x, node.spatial.y + knotOffset.y);
				
				balloon.string.graphics.lineTo(xPos, yPos);
				
				if(balloon.directional)
				{
					if(spatial.scaleX > 0)
						node.spatial.scaleX = Math.abs(node.spatial.scaleX);
					else
						node.spatial.scaleX = -Math.abs(node.spatial.scaleX);
				}
				// Set the color of the balloon
				if(balloon.colorCounter > 3)
				{
					setColor(node);
					balloon.colorIndex == _balloonColors.length-1 ? balloon.colorIndex = 0 : balloon.colorIndex++;
					balloon.colorCounter -= 3
				}
				
				balloon.colorCounter+= time;
			}
		}
		
		private function setColor(node:BallonNode):void
		{
			var display:DisplayObjectContainer = node.entity.get(Display).displayObject;
			var colorclip:DisplayObject = display.getChildByName("colorTarget");
			
			if(colorclip)
			{
				ColorUtil.colorize(colorclip, _balloonColors[node.balloon.colorIndex]);
			}
		}	
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(BallonNode);
			_nodes = null;
		}
		
		private function nodeRemoved(node:BallonNode):void
		{
			node.balloon.string.graphics.clear();
		}
	}
}