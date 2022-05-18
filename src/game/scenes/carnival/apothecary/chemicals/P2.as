package game.scenes.carnival.apothecary.chemicals
{
	import flash.geom.Point;
	
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class P2 extends Chemical implements IChem
	{
		public function P2($molecules:Molecules)
		{
			graphicOffsetY = 5;
			
			rightBondOffset = new Point(0,-24); // chemicals bonding to the right of this chemical should be offset
			
			super(ChemicalGraphics.P2_GRAPHIC, $molecules, 2);
		}
	}
}