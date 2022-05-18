package game.data.character.part
{
	import game.components.entity.character.ColorSet;
	import game.util.ColorUtil;
	public class ColorAspectData
	{	
		/**
		 * Contains information about color and where that color comes from or is applied to.
		 * If parentColor is specified then color is taken from a parent ColorAspectData.
		 * If children are specified then they receive their color from this ColorAspectData.
		 * @param	skinPartId
		 * @param	id
		 * @param	value
		 */
		public function ColorAspectData( skinPartId:SkinPartId, id:String = "", value:Number = NaN )
		{
			this.skinPartId = skinPartId;
			this.id = id;
			if( !isNaN( value ) )
			{
				_value = value;
			}

			childrenColors = new Vector.<ColorAspectData>();
		}

		public var skinPartId:SkinPartId;	// specifies what part color is associated with, used for removal
		public var id:String;				// identifier
		public var _colorSet:ColorSet;		// parent ColorSet this is within
		
		private var _value:Number;	// color value 0x000000
		public function get value():Number	{ return _value; }
		public function set value( val:Number ):void
		{
			_previousValue = _value;
			_value = val;
		}
		
		private var _previousValue:Number;	// color value 0x000000
		public function get previousValue():Number	{ return _previousValue; }
		
		private var _invalidate:Boolean = false;	// flag denoting the need to apply/reapply
		public function get invalidate():Boolean	{ return _invalidate; }
		public function set invalidate( bool:Boolean ):void
		{
			_invalidate = bool;
			if ( bool )
			{
				if ( _colorSet )
				{
					_colorSet.invalidate = true;
				}
			}
		}
		
		private var _parentColor:ColorAspectData;			// a parent ColorAspectData that defines value
		public function get parentColor():ColorAspectData	{ return _parentColor; }
		public function set parentColor( parentAspect:ColorAspectData ):void
		{
			_parentColor = parentAspect;
			if( parentAspect != null )
			{
				if ( parentAspect.childrenColors == null )
				{
					parentAspect.childrenColors = new Vector.<ColorAspectData>();
				}
				parentAspect.childrenColors.push( this );
			}
		}
		
		public var childrenColors:Vector.<ColorAspectData>;	// children ColorAspectDatas who receive value
		public function addChildColor( colorAspect:ColorAspectData ):ColorAspectData	
		{ 
			colorAspect.parentColor = this;
			return colorAspect; 
		}
		
		/**
		 * Returns color value accounting for any darkening defined within ColorSet
		 * @return
		 */
		public function getAdjustedColor( darkenPercent:Number = NaN ):Number
		{
			// if a darkenPercent is not given, use colorSet's darkenPercent value
			if ( isNaN( darkenPercent ) )
			{
				if ( !isNaN( _colorSet.darkenPercent ) )
				{
					return ColorUtil.darkenColor( this.value, _colorSet.darkenPercent );
				}
			}
			else
			{
				return ColorUtil.darkenColor( this.value, darkenPercent );
			}
			
			return this.value;
		}
			
		
		/**
		 * Removes ColorAspectData and any references to it.
		 * Removes itself from parent and/or children colorAspects.
		 * Removes itself from ColorSet.
		 */
		public function remove():void
		{
			var childColorAspect:ColorAspectData;
			var j:int;
			
			// remove this ColorAspect from parent
			if ( _parentColor )
			{
				var index:int = _parentColor.childrenColors.indexOf( this )
				if( index != -1 )
				{
					_parentColor.childrenColors.splice(index, 1)
				}
			}
			
			// remove children ColorAspect
			if( childrenColors )
			{
				// RLH: use reverse order so don't have to change j when removing childColorAspect
				// for ( j=0; j < childrenColors.length; j++ )
				for ( j = childrenColors.length - 1; j != -1; j-- )
				{
					childColorAspect = childrenColors[j];
					childColorAspect.invalidate = true;		// invalidates colorSet parent as well
					if ( childColorAspect.skinPartId.equals( this.skinPartId ) )
					{
						childColorAspect.remove();
						//j--; // RLH: this was causing an infinite loop when two parts both modify the same part (bug #24616)
					}
					else
					{
						// TODO :: May need more here. - bard
						childColorAspect.parentColor = null;
						childColorAspect.revertValue();		// return value to previous value
					}
				}
			}
			
			_colorSet.invalidate = true;
			_colorSet.removeColorAspect( this );
			childrenColors = null;
		}
		
		// Returns color value ot previous value.
		public function revertValue():void
		{
			if( !isNaN( _previousValue ) )
			{
				_value = _previousValue;
			}
		}
	}
}