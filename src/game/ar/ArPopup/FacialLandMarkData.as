package game.ar.ArPopup
{
	import flash.display.Sprite;

	public class FacialLandMarkData
	{
		public var node:int;
		public var sprite:Sprite;
		
		public function FacialLandMarkData(node:int)
		{
			this.node = node;
			sprite = new Sprite();
		}
	}
}