package game.data
{
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import engine.group.Group;
	
	import game.util.ClassUtils;
	import game.util.DataUtils;

	public class ParamDataTypes
	{
		public static const CLASS:String		= "class"; // full class path
		public static const ENTITY:String 		= "entity"; // id
		public static const STRING:String		= "string";
		public static const INT:String			= "int";
		public static const UINT:String			= "uint";
		public static const NUMBER:String		= "number";
		public static const BOOLEAN:String 		= "boolean";
		public static const POINT:String		= "point"; // x,y
		public static const COMPONENT:String	= "component"; // entityId,componentClass
		public static const ARRAY:String		= "array";
		public static const FUNCTION:String		= "function";
		public static const SHELLAPI:String		= "shellapi"; // doesn't matter what the string is
		public static const OBJECT:String		= "*";
		
		public static function convertParams(params:ParamList, group:Group, dictonary:Dictionary = null):ParamList
		{
			var newParams:ParamList = params.clone();
			for(var i:int = 0; i < newParams.length; i++)
			{
				var param:ParamData = newParams.getParamByIndex(i);
				
				if(param.type)
				{
					var valueString:String = DataUtils.getString(param.value);
					if(valueString.indexOf("[") == 0 && valueString.indexOf("]") == valueString.length-1)
					{
						valueString = valueString.substr(1, valueString.length-2);
						if(dictonary && dictonary[valueString])
						{
							param.value = dictonary[valueString];
							continue;
						}						
					}
					
					switch(param.type)
					{
						case CLASS:
							param.value = ClassUtils.getClassByName(param.value);
							break;
						case ENTITY:
							param.value = group.getEntityById(valueString);
							break;
						case STRING:
							param.value = DataUtils.getString(param.value);
							break;
						case INT:
							param.value = int(DataUtils.getNumber(param.value));							
							break;
						case UINT:
							param.value = DataUtils.getUint(param.value);
							break;
						case NUMBER:
							param.value = DataUtils.getNumber(param.value);
							break;
						case BOOLEAN:
							param.value = DataUtils.getBoolean(param.value);
							break;
						case POINT:
							var pointArray:Array = DataUtils.getArray(param.value);						
							param.value = new Point(DataUtils.getNumber(pointArray[0]), DataUtils.getNumber(pointArray[1]));
							break;
						case ARRAY:
							param.value = DataUtils.getArray(param.value);
							break;
						case COMPONENT:
							var compArray:Array = DataUtils.getArray(param.value);
							param.value = group.getEntityById(compArray[0]).get(ClassUtils.getClassByName(compArray[1]));
							break;
						case SHELLAPI:
							param.value = group.shellApi;
							break;
						case OBJECT: // Not sure if we do anything here. If its a star we should hope there is a dictionary element with it
							break;
						default:
							trace("TYPE: " + param.type);
							break;
					}
				}
			}
			
			return newParams;
		}
	}
}