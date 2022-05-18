package game.scenes.carnival.apothecary.chemicals
{
	import flash.geom.Point;
	
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class X2 extends Chemical implements IChem
	{
		public function X2($molecules:Molecules)
		{	
			rightBondOffset = new Point(-28,-13); // chemicals bonding to the right of this chemical should be offset
			rightBondRotation = -45;
			
			graphicOffsetX = 0;
			graphicOffsetY = 13;
			
			super(ChemicalGraphics.X2_GRAPHIC, $molecules, 2);
		}
	}
}