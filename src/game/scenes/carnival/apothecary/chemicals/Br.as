package game.scenes.carnival.apothecary.chemicals
{
	import flash.geom.Point;
	
	import game.scenes.carnival.apothecary.chemicals.data.ChemicalGraphics;
	import game.scenes.carnival.apothecary.components.Molecules;
	
	public class Br extends Chemical implements IChem
	{
		public function Br($molecules:Molecules)
		{
			super(ChemicalGraphics.BR_GRAPHIC, $molecules);
			bondPoint = new Point((graphicSprite.width / 2), (graphicSprite.width / 2));
		}
	}
}