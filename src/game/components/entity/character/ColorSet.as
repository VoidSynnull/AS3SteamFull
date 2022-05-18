package game.components.entity.character
{	
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.data.character.part.ColorAspectData;
	import game.data.character.part.ColorableData;
	import game.data.character.part.SkinPartId;
	import game.util.DataUtils;
	
	import org.osflash.signals.Signal;

	public class ColorSet extends Component
	{
		public function ColorSet()
		{
			colorAspects = new Vector.<ColorAspectData>();
			colorableClips = new Vector.<ColorableData>();
			updateComplete = new Signal( Entity );
		}
		
		public var updateComplete:Signal;
		public var invalidate:Boolean;						
		public var colorableClips:Vector.<ColorableData>;	// clips that will be colored within owning entity's display
		public var colorAspects:Vector.<ColorAspectData>;	// color information
		public var darkenPercent:Number	= NaN;	// will darken color by specified percent, value range 0 to 1.
		
		public static const DEFAULT_ID:String = "default";
		
		/**
		 * Add a ColorAspectData.
		 * @param	skinPartId - needed for removal
		 * @param	id - unique id for color aspect ( skincolor, hairColor, pantsColor, etc. )
		 * @param	value
		 * @return
		 */
		public function addColorAspect( skinPartId:SkinPartId, id:String = "", value:Number = NaN ):ColorAspectData
		{
			if( !DataUtils.validString( id ) )	{ id = DEFAULT_ID; }

			var colorAspect:ColorAspectData = getColorAspect( id );
			if ( colorAspect == null )
			{
				colorAspect = new ColorAspectData( skinPartId, id, value );
				colorAspect._colorSet = this;
				colorAspect.invalidate = true;
				colorAspects.push( colorAspect );
			}
			else if( colorAspect.value != value )
			{
				if( !isNaN(value) )	{ colorAspect.value = value; };
				colorAspect.invalidate = true;
			}
			return colorAspect;
		}
		
		/**
		 * Get ColorAspectData by id, if not specified return last
		 * @param	id
		 * @return
		 */
		public function getColorAspect( id:String = "" ):ColorAspectData
		{
			id = ( DataUtils.validString( id ) ) ? id : DEFAULT_ID;
			
			var colorAspect:ColorAspectData;
			for ( var i:int = 0; i < colorAspects.length; i++ )
			{
				colorAspect = colorAspects[i];
				if ( colorAspect.id == id )
				{
					return colorAspect;
				}
			}
			return null;
		}
		
		/**
		 * Get ColorAspectData by id, if not specified return last
		 * @param	id
		 * @return
		 */
		public function setColorAspect( colorValue:Number, id:String = "" ):ColorAspectData
		{
			id = ( DataUtils.validString( id ) ) ? id : DEFAULT_ID;

			var colorAspect:ColorAspectData = getColorAspect( id );
			if ( colorAspect )
			{
				colorAspect.value = colorValue;
				colorAspect.invalidate = true;
			}
			
			return colorAspect;
		}
		
		/**
		 * Get the most recently applied ColorAspectData
		 * @return
		 */
		public function getColorAspectLast():ColorAspectData
		{
			if( colorAspects.length > 0 )
			{
				return colorAspects[ colorAspects.length - 1 ];
			}
			return null;
		}
		
		/**
		 * Remove referene to specified ColorAspectData
		 * @param	colorAspect
		 */
		public function removeColorAspect( colorAspect:ColorAspectData ):void
		{
			if( colorAspects.length > 0 )
			{
				for ( var i:int = 0; i < colorAspects.length; i++ )
				{
					if ( colorAspects[i] == colorAspect )
					{
						colorAspects.splice( i, 1 );
						return;
					}
				}
			}
		}
	}
}