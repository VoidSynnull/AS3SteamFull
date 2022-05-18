package game.scenes.carnival.shared.popups.duckGame
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.FollowTarget;
	
	public class PoleHookConnectorSystem extends System
	{
		private var nodes:NodeList
		
		public function PoleHookConnectorSystem()
		{
		}
		
		override public function update( time : Number ) : void
		{
			
			for(var node:PoleHookConnectorNode = nodes.head; node; node = node.next)
			{
				var mc:MovieClip = MovieClip ( Display(node.entity.get(Display)).displayObject)
				var wc:PoleHookConnection = node.entity.get(PoleHookConnection)
				var e1:Entity = wc.entity1
				var e2:Entity = wc.entity2
				
				var sp1:Spatial = e1.get(Spatial)
				var sp2:Spatial = e2.get(Spatial)
				
				var ft:FollowTarget = FollowTarget (e2.get (FollowTarget))
				var newOffsetY:Number = ft.offset.y + wc.followOffsetDy
				newOffsetY = Math.min (Math.max (newOffsetY,wc.followOffsetYMin), wc.followOffsetYMax)
				var pctDown:Number = (newOffsetY - wc.followOffsetYMin)/(wc.followOffsetYMax-wc.followOffsetYMin)
				ft.offset.y = newOffsetY
				ft.offset.x = (newOffsetY - wc.followOffsetYMin)/2; // so it sticks out when the line is down
				ft.rate = .05 + (1 - pctDown) * .15
				
				//trace (" ... ft.rate:" + ft.rate)
				var hookPoint:Point = new Point();
				var lineLength:Number = 10 + pctDown * 200
				
				hookPoint.x += (sp1.x - sp2.x)/4;
				hookPoint.y += (sp1.x + lineLength - sp2.y)/4;
				
				mc.graphics.clear();
				mc.graphics.lineStyle(3, 0xCAC1A2);
				mc.graphics.moveTo(sp1.x, sp1.y);
				mc.graphics.curveTo(sp1.x, sp1.y + lineLength/2, sp2.x, sp2.y);
				
				var dx:Number = sp1.x - sp2.x;
				var dy:Number = sp1.y - sp2.y;
				
				var angle:Number = Math.atan2(dy, dx)  / Math.PI * 180 + 90
				sp2.rotation = angle
				
				// Flip the hook
				//mc = MovieClip ( Display(e2.get(Display)).displayObject)
				sp2.scaleX = (sp1.x < sp2.x) ? 1 : -1
				
			}
		}
		
		override public function addToEngine(system:Engine):void
		{
			this.nodes = system.getNodeList(PoleHookConnectorNode);
		}
		
		override public function removeFromEngine(system:Engine):void
		{
			system.releaseNodeList(PoleHookConnectorNode);
			this.nodes = null;
		}
	}
}