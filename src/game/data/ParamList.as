package game.data
{
	/**
	 * Provides functionality of a Dictionary, while maintining th eindex order of an Array
	 */
	public class ParamList
	{
		public var params:Vector.<ParamData>;
		
		public function ParamList( xml:XML = null, tagName:String = "param")
		{
			params = new Vector.<ParamData>();
			if( xml != null )
			{
				parse(xml, tagName )
			}
		}
		
		/**
		 * Parses correctly formatted xml, <param id="idName">value</param>
		 */
		public function parse( xml:XML, tagName:String = "param" ):void
		{
			if( xml.hasOwnProperty( tagName ) )
			{
				var xParams:XMLList = xml.elements(tagName);
				for (var i:int = 0; i < xParams.length(); i++) 
				{
					params.push( new ParamData( XML(xParams[i]) ) );
				}
			}
		}
		
		public function push( paramData:ParamData ):void
		{
			params.push( paramData );
		}
		
		public function addParam( id:String = "", value:*=null ):void
		{
			var param:ParamData = new ParamData();
			param.id = id;
			param.value = value;
			params.push( param );
		}
		
		public function byId( id:String ):*
		{
			for (var i:int = 0; i < params.length; i++) 
			{
				if( params[i].id == id )
				{
					return params[i].value;
				}
			}
			return null;
		}
		
		public function byIndex( index:int ):*
		{
			if( index >= 0 && index < params.length )
			{
				return params[index].value;
			}
			return null;
		}
		
		public function getParamId( id:String ):ParamData
		{
			for (var i:int = 0; i < params.length; i++) 
			{
				if( params[i].id == id )
				{
					return params[i];
				}
			}
			return null;
		}

		public function getParamByIndex( index:int ):ParamData
		{
			if( index >= 0 && index < params.length )
			{
				return params[index];
			}
			return null;
		}
		
		public function removeParamId( id:String ):void
		{
			for (var i:int = 0; i < params.length; i++) 
			{
				if( params[i].id == id )
				{
					params.splice(i, 1);
				}
			}
		}
		
		public function removeParamByIndex( index:int ):void
		{
			if( index >= 0 && index < params.length )
			{
				params.splice(index, 1);
			}
		}
		
		public function removeParam( param:ParamData ):void
		{
			var index:int = params.indexOf( param )
			if( index != -1 )
			{
				params.splice(index, 1);
			}
		}
		
		public function addArray( array:Array ):void
		{
			var param:ParamData;
			for (var i:int = 0; i < array.length; i++) 
			{
				param = new ParamData();
				param.value = array[i];
			}
		}
		
		public function convertToArray():Array
		{
			var array:Array = new Array();
			for (var i:int = 0; i < params.length; i++) 
			{
				array.push( params[i].value );
			}
			return array;
		}
		
		public function get length():int	{ return params.length; }
		
		public function duplicate():ParamList
		{
			var list:ParamList = new ParamList(null);
			list.params = params.concat();
			return list;
		}
		
		public function clone():ParamList
		{
			var list:ParamList = new ParamList(null);
			
			for each(var data:ParamData in params)
			{
				var newData:ParamData = data.clone();				
				list.params.push(newData);
			}
			
			return list;
		}
	}
}