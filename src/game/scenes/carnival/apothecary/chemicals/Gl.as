package game.scenes.carnival.apothecary.chemicals
{
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class Gl extends Chemical implements IChem
	{
		public function Gl($molecules:Molecules)
		{
			graphicOffsetY = -5;
			
			super(ChemicalGraphics.GL_GRAPHIC, $molecules);
		}
	}
}