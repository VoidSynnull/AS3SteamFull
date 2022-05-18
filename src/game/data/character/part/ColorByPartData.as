package game.data.character.part
{
	public class ColorByPartData
	{	
		/**
		 * Specifies part-to-color relationship, used for both defining applying and receiving colors.
		 * @param	partId
		 * @param	partColorId
		 * @param	colorId
		 */
		public function ColorByPartData( partId:String = "", partColorId:String = "", colorId:String = "" )
		{
			if ( partId != "" )
			{
				this.partId = partId;
			}
			if ( partColorId != "" )
			{
				this.partColorId = partColorId;
			}
			if ( colorId != "" )
			{
				this.colorId = colorId;
			}
		}
		
		public var partId:String;			// part id being referenced
		public var partColorId:String;		// colorId of part being referenced
		public var colorId:String;			// colorId applying/retrieving color
	}
}