package game.systems.entity
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.motion.Edge;
	import game.nodes.entity.SleepNode;
	
	public class SleepSystem extends System
	{
		public function SleepSystem()
		{
			super.fixedTimestep = 1/15;
			super.onlyApplyLastUpdateOnCatchup = true;
		}

		override public function addToEngine( gameSystems : Engine ) : void
		{
			_nodes = gameSystems.getNodeList(SleepNode);
			
			_nodes.nodeRemoved.add( nodeRemoved );
			_nodes.nodeAdded.add( nodeAdded );
			
			var node:SleepNode;
			
			for( node = _nodes.head; node; node = node.next )
			{
				nodeAdded(node);
			}
		}
				
		private function nodeRemoved(node:SleepNode) : void
		{			
			setSleep(node.entity, false, false);
		}
		
		private function nodeAdded(node:SleepNode):void
		{
			setSleep(node.entity, false, true);
		}
				
		override public function update(time:Number) : void
		{
			if (_awakeArea != null || _visibleArea != null)
			{
				var node:SleepNode;
				
				for( node = _nodes.head; node; node = node.next )
				{
					updateNode(node, time);
				}
			}
		}

		private function updateNode(node:SleepNode, time:Number):void
		{
			var entity:Entity = node.entity;
			var sleep:Sleep = node.sleep;
			
			if(entity.group.paused && !entity.ignoreGroupPause)
			{
				setSleep(entity, true, true, true);
			}
			else
			{
				if(!node.sleep.ignoreOffscreenSleep)
				{
					checkVisibility(node);
				}
				else
				{
					setSleep(entity, node.sleep.sleeping);
				}
			}
		}
		
		private function checkVisibility(node:SleepNode):void
		{
			var spatial:Spatial = node.spatial;
			var display:Display = node.display;
			var edge:Edge = node.edge;
			var top:Number = 0;
			var bottom:Number = 0;
			var left:Number = 0;
			var right:Number = 0;
			var x:Number = spatial.x;
			var y:Number = spatial.y;
			
			// If a sleep component has a zone rectangle use that to define its 'awake' area.
			if(node.sleep.zone != null)
			{
				x = node.sleep.zone.x;
				y = node.sleep.zone.y;
				top = 0;
				bottom = node.sleep.zone.height;
				left = 0;
				right = node.sleep.zone.width;
			}
			else if (display != null && !node.sleep.useEdgeForBounds)
			{				
				if(display.displayObject != null)
				{
					// In cases where a display object has an area of zero, check it's spatial against the visible area rather than a bounds check.
					//   This allows entities with an area of zero (like particle systems before they start emitting) to still get their sleep flag
					//   updated.
					if(display.displayObject.width > 0 && display.displayObject.height > 0)
					{
						if (_visibleArea.hitTestObject(display.displayObject))
						{
							node.sleep.sleeping = false;
							setSleep(node.entity, node.sleep.sleeping);
							return;
						}
						else
						{
							node.sleep.sleeping = true;
						}
					}
				}
			}
			else if(edge != null)
			{
				top = edge.rectangle.top;
				bottom = edge.rectangle.bottom;
				left = edge.rectangle.left;
				right = edge.rectangle.right;
			}
			
			if(_awakeArea != null)
			{
				if (x + right >= _awakeArea.x && 
					x + left <= _awakeArea.x + _awakeArea.width &&
					y + bottom >= _awakeArea.y && 
					y + top <= _awakeArea.y + _awakeArea.height)
				{
					node.sleep.sleeping = false;
				}
				else
				{
					node.sleep.sleeping = true;
				}
			}

			setSleep(node.entity, node.sleep.sleeping);
		}
		
		override public function removeFromEngine( gameSystems : Engine ) : void
		{
			var node:SleepNode;
			if( _nodes != null )
			{
				for( node = _nodes.head; node; node = node.next )
				{
					nodeRemoved(node);
				}
				
				gameSystems.releaseNodeList( SleepNode );
			}
			_nodes = null;
		}

		private function setSleep(entity:Entity, sleeping:Boolean, managedSleep:Boolean = true, paused:Boolean = false):void
		{
			if(sleeping != entity.sleeping)
			{
				entity.sleeping = sleeping;
				entity.managedSleep = managedSleep;
				entity.paused = paused;
				
				var children:Children = entity.get(Children);
				
				if(children)
				{
					var allChildren:Vector.<Entity> = children.children;
					var nextChild:Entity;
					
					for(var n:uint = 0; n < allChildren.length; n++)
					{
						nextChild = allChildren[n];
						
						if(!Entity(nextChild).get(Sleep))
						{
							setSleep(nextChild, sleeping, managedSleep, paused);
						}
					}
				}
			}
		}
		
		private var _nodes : NodeList;
		private var _visibleArea:DisplayObjectContainer;
		private var _invalidateCurrentPause:Boolean = false;
		private var _awakeArea:Rectangle;
		
		public function set awakeArea(awakeArea:Rectangle):void
		{
			_awakeArea = awakeArea;//.clone();
			//awakeArea.x += awakeArea.width * .1;
			//awakeArea.width = awakeArea.width * .8;
		}
		
		public function set visibleArea(visibleArea:DisplayObjectContainer):void
		{
			_visibleArea = visibleArea;
			//visibleArea.width = visibleArea.width * .8;
		}
	}
}
