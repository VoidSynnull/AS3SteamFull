package game.components.entity.character.part
{	
	import ash.core.Component;
	import game.util.DataUtils;
	
	public class PartLayer extends Component
	{
		public var invalidate:Boolean;		// for system use only, invalidated when insert or layer is set
		
		/** SYSTEM USE ONLY - determine if inserted above or below */
		public var isAbove:Boolean;
		
		private var _insertPartTarget:String;	// name of part to insert above or below
		public function get insertPartTarget():String 	{ return _insertPartTarget; }
		/**
		 * Set to change part layer.
		 * Define part you are using as reference and whether you want to be above or below it's layer.
		 * @param partName - part whose layer you are referencing
		 * @param above - flag determining if you want your part to be above or below the reference part
		 */
		public function setInsert( partName:String, above:Boolean = true ):void
		{
			if ( DataUtils.validString( partName ) )
			{
				invalidate = true;
				_insertPartTarget = partName;
				isAbove = above;
			}
		}
		public function clearInsert():void	{ _insertPartTarget = ""; }
		
		/** Layer index of part  */
		private var _layer:int;
		public function get layer():int { return _layer; }
		public function set layer( nextLayer:int ):void
		{
			invalidate = true;
			_layer = nextLayer;
		}
	}
}
