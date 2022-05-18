package game.scenes.start.login.data
{
	import flash.utils.Dictionary;
	
	import game.data.character.LookData;
	import game.util.DataUtils;
	import game.util.SkinUtils;
	
	public class CharLookLibrary
	{
		private var parts:Dictionary;
		
		public function get Parts():Dictionary
		{
			return parts;
		}
		
		public function CharLookLibrary(data:* = null)
		{
			if(data != null)
			{
				if(data is String)
					parts = parseJson(data);
				else
					parts = initFromObject(data);
			}
			else
			{
				parts = new Dictionary();
			}
		}
		
		public function initFromObject(data:Object):Dictionary
		{
			var dic:Dictionary = new Dictionary();
			for(var prop:String in data)
			{
				dic[prop] = data[prop];
			}
			return dic;
		}
		
		public function addFromObject(data:Object):void
		{
			for(var prop:String in data)
			{
				if(parts.hasOwnProperty(prop))
				{
					var array:Array = parts[prop];
					var props:Array = data[prop];
					for(var i:int = 0; i <props.length; i++)
					{
						var val:* = props[i];
						if(array.indexOf(val) == -1)
							array.push(val);
					}
					parts[prop] = array;
				}
				else
				{
					parts[prop] = data[prop];
				}
			}
		}
		
		public function randomizeCategory(id:String):void
		{
			if(parts.hasOwnProperty(id))
			{
				var lookParts:Array = parts[id];
				var newPartsOrder:Array = [];
				while(lookParts.length > 0)
				{
					var index:int = int(lookParts.length * Math.random());
					newPartsOrder.push(lookParts.splice(index, 1)[0]);
				}
				parts[id] = newPartsOrder;
			}
		}
		
		public function getValue(id:String):String
		{
			if(parts.hasOwnProperty(id))
			{
				var lookParts:Array = parts[id];
				var part:String = lookParts[int(lookParts.length * Math.random())];
				return part;
			}
			return null;
		}
		
		public function createLook():LookData
		{
			var look:LookData = new LookData();
			
			for (var key:String in parts) 
			{
				var value:String = getValue(key);
				if(key == SkinUtils.EYE_STATE)
				{
					var index:int = value.indexOf("_");
					if(index > 0)
						value = value.substr(0,index);
					
					look.setValue(key, value);
				}
				else
				{
					look.setValue(key, value);
				}
			}
			
			return look;
		}
		
		public static function parseJson(json:String):Dictionary
		{
			var dictionary:Dictionary = new Dictionary();
			//remove brackets
			json = json.substr(1,json.length-2);
			var index:int = json.indexOf(":", index);
			while(index >=0)
			{
				var key:String = json.substr(0,index);
				var arrayStart:int = index+2;//index of : and then skipping : and [
				var arrayEnd:int = json.indexOf("]");
				var partsString:String = json.substr(arrayStart,arrayEnd-arrayStart);
				var parts:Array = DataUtils.getArray(partsString);
				dictionary[key] = parts;
				json = json.substr(arrayEnd+2);//strip the parsed data
				index = json.indexOf(":");
			}
			
			return dictionary;
		}
		
		public static function toJson(dictionary:Dictionary):String
		{
			var s:String = '{';
			var first:Boolean = true;
			for (var key:String in dictionary) 
			{
				if(first)
					first = false;
				else
					s+=',';
				
				s+=key+':[';
				var array:Array = dictionary[key];
				for(var i:int = 0;i < array.length; i++)
				{
					if(i>0)
						s+=',';
					s += array[i];
				}
				s+= ']';
			}
			s+= '}';
			trace(s);
			return s;
		}
	}
}