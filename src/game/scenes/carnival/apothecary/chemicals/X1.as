package game.scenes.carnival.apothecary.chemicals
{
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class X1 extends Chemical implements IChem
	{
		public function X1($molecules:Molecules)
		{	
			graphicOffsetX = 5;
			graphicOffsetY = 0;
			
			super(ChemicalGraphics.X1_GRAPHIC, $molecules);
		}
	}
}