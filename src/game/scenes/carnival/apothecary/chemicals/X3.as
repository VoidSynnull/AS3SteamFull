package game.scenes.carnival.apothecary.chemicals
{
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class X3 extends Chemical implements IChem
	{
		public function X3($molecules:Molecules)
		{
			graphicOffsetY = 5;
			
			super(ChemicalGraphics.X3_GRAPHIC, $molecules);
		}
	}
}