package game.managers
{
	import flash.utils.Dictionary;
	
	import engine.Manager;
	
	import game.data.display.EffectData;
	import game.data.text.TextStyleData;
	import game.util.DataUtils;
	
	/**********************************************
	 * Managing the text from styles.xml. 
	 * 
	 * 
	 * @author Scott Wszalek
	 *  *******************************************/

	public class TextManager extends Manager
	{
		public function TextManager()
		{
			
		}
		
		override protected function construct():void
		{
			super.construct();
		}
		
		/**
		 * Get the style for a text field based on the type and the style id
		 * @param type - The style type, top reference (Dialog, card, popup, ui)
		 * @param id - The style's id as listed in the xml
		 * 
		 */
		public function getStyleData(type:String, id:String):TextStyleData
		{
			var data:TextStyleData = null;
			if( _typeDict[type] != null )
			{
				if( _typeDict[type][id] != null)
				{
					data = _typeDict[type][id];
				}
			}
			else
			{
				trace("");
			}

			return data;
		}
		
		/**
		 * Retrieve Dictionary of TextStyleData associated with type.
		 * @param type - String : The style type, top reference (Dialog, card, popup, ui)
		 * @return - Dictionary of TextStyleData associated with type, key = TextStyleData.id
		 */
		public function getStylesByType(type:String):Dictionary
		{
			if(_typeDict[type] != null)
			{
				return _typeDict[type];
			}

			return null;
		}
		
		public function parse(xml:XML):void
		{
			var typeDict:Dictionary;
			var ids:Array;

			// Every type -- dialog, card, ui, etc.
			for each(var typeXml:XML in xml.children())
			{
				// get/create Dictionary for style type
				var typeName:String = DataUtils.getString( typeXml.attribute("id") );
				typeDict = _typeDict[typeName];
				if( typeDict == null )
				{
					typeDict = new Dictionary();
					_typeDict[typeName] = typeDict;
				}
				
				// every style in that type
				for each(var style:XML in typeXml.children())
				{
					var styleData:TextStyleData = new TextStyleData(typeName); // instantiate the styleData
					
					// fill in the style data
					for each(var child:XML in style.children())
					{
						var name:String = child.name().localName;
						styleData.addAttribute(name, child);
						
						/**
						 * Shadow is used to create a 'shadow' for the text.
						 * Does not use a filter but rather creates a duplicate Textfield offset and layered below original text
						 */
						if(name == this.SHADOW)
						{
							var shadow:Object = new Object();
							for each(var shadowChild:XML in child.children())
							{
								if(shadowChild.name().localName == this.COLOR)
								{
									shadow[shadowChild.name().localName] = DataUtils.getUint(shadowChild.replace("#", "0x"));
								}
								else
									shadow[shadowChild.name().localName] = DataUtils.getNumber(shadowChild);
							}
							styleData.shadow = shadow;
						}
						else if(name == this.EFFECT)
						{
							// NOTE :: filters cannot be used on mobile unless they are bitmapped
							styleData.effectData = new EffectData( child );
						}
					}
					
					// a style can have multiple ids
					ids = DataUtils.getArray( style.attribute("id") );
					for each(var id:String in ids)
					{
						id = id.replace(/[\s\r\n]*/gim, ""); // remove whitespace from id
						styleData.id = id;
						typeDict[id] = styleData;
					}	
				}	
			}
		}
		
		private static const XML_PATH:String = "style/";
		private const SHADOW:String = "shadow";
		private const EFFECT:String = "effect";
		private const COLOR:String = "color";
		
		private var _typeDict:Dictionary = new Dictionary();	// Dictionary (key = type) of Dictionaries (key = style id) of TextStyleData  
		
	}
}