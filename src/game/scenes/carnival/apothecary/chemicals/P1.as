package game.scenes.carnival.apothecary.chemicals
{
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class P1 extends Chemical implements IChem
	{
		public function P1($molecules:Molecules)
		{
			graphicOffsetX = 4;
			graphicOffsetY = 10;
			
			super(ChemicalGraphics.P1_GRAPHIC, $molecules);
		}
	}
}