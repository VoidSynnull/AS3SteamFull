package game.data.character
{
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	/**
	 * Rig data for a particular character variant, contains PartData for all parts.
	 */
	public class SizeData
	{
		public var scale : Number;				
		public var defaultEdgeData : EdgeData;
		public var dialogPositionPercent : Point;	// position of dialog by percentage of width and height
		public var edgeDatas : Dictionary;	// Dictionary of EdgeData
		
		public function SizeData( scale:Number = NaN, edgeData:EdgeData = null, dialogXPercent:Number = NaN, dialogYPercent:Number = NaN )
		{
			this.scale = scale;
			
			edgeDatas = new Dictionary();
			addEdgeData( edgeData );
			
			dialogPositionPercent = new Point();
			if ( !isNaN(dialogXPercent) )
			{
				dialogPositionPercent.x = dialogXPercent;
			}
			if ( !isNaN(dialogYPercent) )
			{
				dialogPositionPercent.y = dialogYPercent;
			}
		}
		
		public function addEdgeData( edgeData:EdgeData ):void
		{
			if ( edgeData )
			{
				edgeDatas[ edgeData.id ] = edgeData;
				if ( edgeData.id == EdgeData.DEFAULT )
				{
					defaultEdgeData = edgeData;
				}
			}
		}
		
		public function getEdgeData( id:EdgeData ):EdgeData
		{
			return edgeDatas[ id ];
		}
		
	}
}