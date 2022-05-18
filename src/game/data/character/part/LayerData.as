package game.data.character.part
{
	import game.util.DataUtils;
	public class LayerData
	{	
		/**
		 * specify where this should reside in relation to other parts.  
		 * Can also specify 'top' or 'bottom' without an id to set the layer above or below all others.
		 * @param	partId
		 * @param	position
		 */
		public function LayerData( partId:String = "", position:String="" )
		{
			this.partId = DataUtils.getString(partId);
			this.position = DataUtils.getString(position);
		}
		
		public var partId:String;
		public var position:String;
		
		public static const ABOVE:String 	= "above";	// places part above specified partId
		public static const BELOW:String 	= "below";	// places part below specified partId
		public static const TOP:String 		= "top";	// places part at lowest later
		public static const BOTTOM:String 	= "bottom";	// places part at highest later
	}
}