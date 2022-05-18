package game.scenes.deepDive1.shared.systems
{
	import flash.display.DisplayObject;
	
	import engine.components.Spatial;
	
	import game.scenes.deepDive1.shared.nodes.BubblesNode;
	import game.systems.GameSystem;
	
	import nape.geom.Vec2;
	import nape.phys.Body;
	
	public class BubblesSystem extends GameSystem
	{
		public function BubblesSystem()
		{
			super(BubblesNode, onUpdate);
		}
		
		private function onUpdate($node:BubblesNode, $time:Number):void{
			if($node.bubbles.debug){
				$node.bubbles.shapeDebug.clear();
			}
			
			$node.bubbles.space.step($time);
			$node.bubbles.space.liveBodies.foreach(updateGraphics);
			
			if($node.bubbles.debug){
				$node.bubbles.shapeDebug.draw($node.bubbles.space);
				$node.bubbles.shapeDebug.flush();
			}
			
			//trace(Spatial($node.bubbles.player.get(Spatial)).x+":"+Spatial($node.bubbles.player.get(Spatial)).y);
			
			$node.bubbles.subBody.position = new Vec2(Spatial($node.bubbles.player.get(Spatial)).x, Spatial($node.bubbles.player.get(Spatial)).y);
		}
		
		private function updateGraphics(b:Body):void {
			// Grab a reference to the visual which we will update
			var graphic:DisplayObject = b.userData.graphic;
			
			// Update position of the graphic to match the simulation
			graphic.x = b.position.x ;
			graphic.y = b.position.y ;
			
			// Update the rotation of the graphic. Note: AS3 uses degrees to express rotation 
			// while Nape uses radians. Also, the modulo (%360) has been put in because AS3 
			// does not like big numbers for rotation (so I've read).
			graphic.rotation = (b.rotation * 180 / Math.PI);
			
		}
	}
}