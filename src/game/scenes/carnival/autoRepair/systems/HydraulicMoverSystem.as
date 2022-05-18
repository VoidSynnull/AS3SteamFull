package game.scenes.carnival.autoRepair.systems
{
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.scenes.carnival.autoRepair.components.HydraulicDirection;
	import game.scenes.carnival.autoRepair.nodes.HydraulicDirectionNode;
	
	public class HydraulicMoverSystem extends System
	{
		private var nodes:NodeList
		
		public function HydraulicMoverSystem()
		{
			
		}
		
		override public function update( time : Number ) : void
		{
			var sp:Spatial
			var dir:HydraulicDirection
			var e:Entity
			var mc:MovieClip
			
			var newY:Number
			
			for(var node:HydraulicDirectionNode = nodes.head; node; node = node.next)
			{
				e =  node.entity
				mc = MovieClip (Display(e.get(Display)).displayObject)
				dir = node.hydraulicDirection
				sp = Spatial (e.get(Spatial))
				newY = sp.y + dir.direction * 3
				newY = Math.min (dir.max,newY)
				newY = Math.max (dir.min,newY)
				if (sp.y != newY) {
					sp.y = newY
				}
				else {
					//trace ("HydraulicMoverSystem: stop sound!" + sp.y + "," + newY);
					var a:Audio = e.get(Audio)
					a.stop(SoundManager.EFFECTS_PATH +"gears_05b_L.mp3")
				}
				mc.pole0.height = dir.max - sp.y + 62;
				mc.pole1.y = dir.max - sp.y + 119;
				mc.pole1.height = (dir.max - sp.y) * .3 + 40;
			} 
		}
		
		override public function addToEngine(system:Engine):void
		{
			this.nodes = system.getNodeList(HydraulicDirectionNode);
		}
		
		override public function removeFromEngine(system:Engine):void
		{
			system.releaseNodeList(HydraulicDirectionNode);
			this.nodes = null;
		}
	}
}