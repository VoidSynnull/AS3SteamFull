package game.scenes.mocktropica.chasm.systems
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import game.components.motion.Edge;
	
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	
	import game.scenes.mocktropica.chasm.nodes.NpcBlitNode;
	
	public class NpcBlitSystem extends ListIteratingSystem
	{
		public function NpcBlitSystem()
		{
			super(NpcBlitNode, updateNode);
		}
		
		public function updateNode($node:NpcBlitNode, $time:Number):void{
			if($node.npcBlitComponent.ready){
				// update NpcBlit's bitmapdata with a current draw from NpcBlit's sample NPC

				var rect:Rectangle = new Rectangle();
				rect.width = Display($node.npcBlitComponent.sampleNPC.get(Display)).displayObject.width;
				rect.height = Display($node.npcBlitComponent.sampleNPC.get(Display)).displayObject.height;
				
				var matrix:Matrix = new Matrix();
				matrix.tx = ((rect.width / 2) / Display($node.npcBlitComponent.sampleNPC.get(Display)).displayObject.scaleX) + Edge($node.npcBlitComponent.sampleNPC.get(Edge)).left;
				matrix.ty = ((rect.height / 2) / Display($node.npcBlitComponent.sampleNPC.get(Display)).displayObject.scaleY) + Edge($node.npcBlitComponent.sampleNPC.get(Edge)).top;
				matrix.scale(Display($node.npcBlitComponent.sampleNPC.get(Display)).displayObject.scaleX, Display($node.npcBlitComponent.sampleNPC.get(Display)).displayObject.scaleY);
				
				var npcBitmapData:BitmapData = new BitmapData(rect.width, rect.height, true, 0x000000);
				npcBitmapData.draw(Display($node.npcBlitComponent.sampleNPC.get(Display)).displayObject, matrix);
				
				$node.npcBlitComponent.drawnBitmapData = npcBitmapData;
				
				//var point:Point = new Point(Display($node.npcBlitComponent.sampleNPC.get(Display)).displayObject.x, Display($node.npcBlitComponent.sampleNPC.get(Display)).displayObject.y);
				var point:Point = new Point();
				
				$node.npcBlitComponent.bitmapData.copyPixels(npcBitmapData, rect, point);
			}
		}
	}
}