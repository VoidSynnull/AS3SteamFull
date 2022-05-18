package game.systems.specialAbility.character.objects
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	
	import game.components.specialAbility.character.objects.FlowerGrow;
	import game.nodes.specialAbility.character.objects.FlowerGrowNode;
	import game.systems.SystemPriorities;

	public class FlowerGrowSystem extends System
	{
		private var _nodes:NodeList;
		
		override public function addToEngine(systemsManager:Engine):void
		{
			_nodes = systemsManager.getNodeList(FlowerGrowNode);
			_nodes.nodeRemoved.add( nodeRemoved );
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function update( time : Number ) : void
		{
			var node:FlowerGrowNode;
			
			for ( node = _nodes.head; node; node = node.next )
			{
				var flowerGrow:FlowerGrow = node.flowerGrow;
				
				var container:DisplayObjectContainer = node.entity.get(Display).container;
				var display:DisplayObjectContainer = node.entity.get(Display).displayObject;
				var clip:MovieClip = display as MovieClip;
				
				if(!flowerGrow.vine)
				{
					flowerGrow.vine = new Shape();
					flowerGrow.g = flowerGrow.vine.graphics;
				}
				
				if(!container.contains(flowerGrow.vine))
				{
					container.addChildAt(flowerGrow.vine, container.numChildren-1);
					flowerGrow.nx = node.spatial.x;
					flowerGrow.ny = node.spatial.y;
					flowerGrow.g.moveTo(node.spatial.x, node.spatial.y);
				}
				
				if(flowerGrow.wait < flowerGrow.maxWait)
				{
					flowerGrow.g.lineStyle(flowerGrow.lineWidth, 0x45A754);
					flowerGrow.nx += flowerGrow.r*Math.cos(flowerGrow.angle);
					flowerGrow.ny += flowerGrow.r*Math.sin(flowerGrow.angle);
					flowerGrow.g.lineTo(flowerGrow.nx, flowerGrow.ny);
					flowerGrow.angle += flowerGrow.turn;
					
					if (Math.random() < 0.5) {
						flowerGrow.turn = Math.random()*0.4 - 0.2;
					}
					
					// Add petals 
					if (Math.random() < 0.3)
					{
						addLeaf(node, flowerGrow.nx, flowerGrow.ny);
					}
					
					
				} else {
					
					if(!flowerGrow.headAdded)
					{
						addHead(node, flowerGrow.nx, flowerGrow.ny);
						flowerGrow.headAdded = true;
					}
				}
				
				flowerGrow.wait ++;
			}
		}
		
		private function addLeaf(node:FlowerGrowNode, xPos:Number, yPos:Number):void
		{
			node.entity.group.shellApi.loadFile(node.entity.group.shellApi.assetPrefix + "specialAbility/objects/leaf.swf", leafLoadComplete, node, xPos, yPos);
		}	
		
		private function leafLoadComplete(clip:MovieClip, node:FlowerGrowNode, xPos, yPos):void
		{
			var container:DisplayObjectContainer = node.entity.get(Display).container;
			clip.x = xPos;
			clip.y = yPos;
			clip.rotation = 180*node.flowerGrow.angle/Math.PI + Math.random()*120 - 60;
			clip.scaleX = clip.scaleY = (Math.random()*70 + 70) / 100;
			container.addChildAt(clip, container.numChildren - 1);
		}
		
		
		private function addHead(node:FlowerGrowNode, xPos:Number, yPos:Number):void
		{
			var display:DisplayObjectContainer = node.entity.get(Display).displayObject;
			display.x = xPos;
			display.y = yPos;
			display.rotation = Math.random()*45;
			display.scaleX = display.scaleY = (Math.random()*60 + 80) / 100;
			
			var clip:MovieClip = display as MovieClip;
			clip.gotoAndStop(Math.ceil(Math.random()*4) + 1);
		}
		
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(FlowerGrowNode);
			_nodes = null;
		}
		
		private function nodeRemoved(node:FlowerGrowNode):void
		{
		}
	}
}