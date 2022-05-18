package game.scenes.carrot.diner.systems 
{
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	
	import engine.components.Spatial;
	
	import game.scenes.carrot.diner.components.Glass;
	import game.scenes.carrot.diner.nodes.GlassNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.ColorUtil;
	
	import org.osflash.signals.Signal;
	
	public class MixerSystem extends GameSystem
	{
		public var complete:Signal = new Signal();
		
		public function MixerSystem()
		{
			super(GlassNode, updateNode);
			
			super._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode(node:GlassNode, time:Number):void
		{
			var glass:Glass = node.glass;
			var spatial:Spatial = node.spatial;
			
			spatial.rotation += (node.targetSpatial.target.x - node.spatial.x) * (time * 1.5);
			spatial.rotation += (-spatial.rotation) * (time * 6);				
			
			if(!glass.isFilling)
			{
				glass.wait = 0;
				return;
			}		
			
			var colorClip:MovieClip = node.display.displayObject["colorClip"];
			
			var maxWait:Number = (50 + (130 * colorClip.scaleY)) * 0.001;
			glass.wait += time;
			if(glass.wait < maxWait) return;
			
			if(colorClip.scaleY < 1) colorClip.scaleY += 0.15 * time;
			else if(!glass.isFull)
			{
				glass.isFull = true;
				complete.dispatch();
				colorClip.scaleY = 1;
			}
			
			switch(glass.machine)
			{
				case 1: addColor(glass, ColorUtil.hexToRgb(0x0075FF)); break;
				case 2: addColor(glass, ColorUtil.hexToRgb(0xFF2100)); break;
				case 3: addColor(glass, ColorUtil.hexToRgb(0xFFF200)); break;
				case 4: addColor(glass, ColorUtil.hexToRgb(0x000000)); break;
				case 5: addColor(glass, ColorUtil.hexToRgb(0xFFFFFF)); break;
			}
			colorClip.transform.colorTransform = glass.color;
		}
		
		private function addColor(glass:Glass, rgb:Vector.<uint>):void
		{
			glass.color.redOffset 	+= (rgb[0] - glass.color.redOffset) 	/ 40;
			glass.color.greenOffset += (rgb[1] - glass.color.greenOffset) 	/ 40;
			glass.color.blueOffset 	+= (rgb[2] - glass.color.blueOffset) 	/ 40;
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			super.removeFromEngine(systemsManager);
			
			complete.removeAll();
			complete = null;
		}
	}
}