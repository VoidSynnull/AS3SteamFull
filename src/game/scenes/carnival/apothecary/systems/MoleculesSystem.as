package game.scenes.carnival.apothecary.systems
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.carnival.apothecary.ReactorPopup;
	import game.scenes.carnival.apothecary.nodes.MoleculesNode;
	
	import nape.phys.Body;
	
	public class MoleculesSystem extends ListIteratingSystem
	{
		public function MoleculesSystem($container:DisplayObjectContainer, $group:ReactorPopup)
		{
			super(MoleculesNode, onUpdate);
		}
		
		private function onUpdate($node:MoleculesNode, $time:Number):void{
			
			if($node.molecules.DEBUG){
				$node.molecules.shapeDebug.clear();
			}
			
			$node.molecules.space.step($time);
			$node.molecules.space.liveBodies.foreach(updateGraphics);
			
			if($node.molecules.DEBUG){
				$node.molecules.shapeDebug.draw($node.molecules.space);
				$node.molecules.shapeDebug.flush();
			}
			
			$node.molecules.updateGun();
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