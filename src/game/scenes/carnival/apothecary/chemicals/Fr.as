package game.scenes.carnival.apothecary.chemicals
{
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class Fr extends Chemical implements IChem
	{
		public function Fr($molecules:Molecules)
		{
			graphicOffsetX = 9;
			graphicOffsetY = 27;
			
			super(ChemicalGraphics.FR_GRAPHIC, $molecules);
		}
	}
}