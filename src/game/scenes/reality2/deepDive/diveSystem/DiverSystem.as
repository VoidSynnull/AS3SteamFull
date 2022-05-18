package game.scenes.reality2.deepDive.diveSystem
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.group.Scene;
	
	public class DiverSystem extends System
	{
		protected var nodeList : NodeList;
		
		public function DiverSystem()
		{
			//super(DiverNode, updateNode);
		}
		private const PADDING:Number = 10;
		
		override public function addToEngine(systemManager:Engine):void
		{
			nodeList = systemManager.getNodeList( DiverNode );
		}
		
		override public function removeFromEngine( systemManager : Engine ) : void
		{
			nodeList = null;
			
			systemManager.releaseNodeList( DiverNode );
		}
		
		override public function update(time:Number):void
		{
			var contestants:Array = [];
			for( var node : DiverNode = nodeList.head; node; node = node.next )
			{
				var obj:Object = new Object();
				obj.node = node;
				obj.y = node.diver.depth;
				contestants.push(obj);
			}
			contestants.sortOn("y", Array.NUMERIC);
			//trace("After");
			for(var i:int = 0; i < contestants.length; i++)
			{
				updatePlace(contestants[i].node,contestants.length-i, time);
			}
		}
		
		private function updatePlace(node:DiverNode, place:int, time:Number):void
		{
			node.diver.place = place;
			updateNode(node, time);
		}
		
		private function updateNode(node:DiverNode, time:Number):void
		{
			if(node.diver.air > 0)
			{
				node.diver.air -= time;
				node.diver.signaled = false;
				
			}
			else
			{
				node.diver.air = 0;
				if(!node.diver.signaled)
				{
					node.diver.signaled = true;
					node.diver.ranOutOfAir.dispatch(node.entity);
				}
			}
			if(node.diver.ui)
			{
				updateUI(node);
			}
		}
		
		private function updateUI(node:DiverNode):void
		{
			//oxygen
			var bar:MovieClip = node.diver.ui["oxygenBar"];
			if(bar)
			{
				var property:String = bar.width > bar.height?"width":"height";
				var max:Number = bar[property];
				bar["bar"][property] = max * (node.diver.air / node.diver.maxAir);
			}
			// depth
			var tf:TextField = node.diver.ui["score"];
			if(tf)
			{
				var feet:Number = Math.round(node.spatial.y / 50) * 100 / 100;//arbitrary
				if(node.diver.depth < feet)// don't detract from best distance
					node.diver.depth = feet;
				tf.text = ""+ node.diver.depth + "ft";
			}
			// place
			tf = node.diver.ui["place"];
			if(tf)
			{
				tf.text = ""+node.diver.place;
			}
			// darkness
			var darkness:MovieClip = node.diver.ui["darkness"];
			if(darkness)
			{
				var scene:Scene = node.entity.group as Scene;
				var percent:Number = node.spatial.y / scene.sceneData.bounds.bottom;
				darkness.alpha = percent;
			}
		}
	}
}