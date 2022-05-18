package game.item
{
	public class ItemClassFactory
	{
		public function ItemClassFactory()
		{
		}
		
		public static function make (s:String): Class {
			var c:Class
			switch (s) {
				case "Item": c = Item 
					break
				case "UseableItem": c = UseableItem
					break
			}
			return c
		}
	}
}