package game.managers
{
	import flash.utils.Dictionary;
	
	import engine.Manager;
	
	public class CollectionManager extends Manager
	{
		public function CollectionManager()
		{
			
		}
		
		override protected function construct():void
		{
			super.construct();
			
			collections = new Dictionary();
		}
		
		public function addCollection(xml:XML):void
		{
			
		}
		
		public var collections:Dictionary;
	}
}