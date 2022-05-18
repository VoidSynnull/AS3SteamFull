package game.data.text
{
	import game.data.display.EffectData;
	import game.util.DataUtils;

	public class TextStyleData
	{
		public function TextStyleData(type:String, id:String = null)
		{
			this.type = type;
			this.id = id;
		}

		public var type:String;
		public var id:String;
		public var fontFamily:String;
		public var size:Number;
		public var color:uint;
		public var bold:Boolean;
		public var italic:Boolean;
		public var underline:Boolean;
		public var alignment:String;
		public var leading:Number;
		public var marginLeft:Number;
		public var marginRight:Number;
		public var indent:Number;
		public var letterSpacing:Number;
		public var verticalAlign:Boolean;
		public var hasShadow:Boolean;
		public var shadow:Object = {"alpha":.15, "color":0x000000, "offsetX":-1, "offsetY":2};
		/**  NOTE :: filters cannot be used on mobile unless they are bitmapped */
		public var effectData:EffectData;
		public var yPos:Number = NaN;

		// Types
		public static const DIALOG:String = "dialog";
		public static const CARD:String = "card";
		public static const POPUP:String = "popup";
		public static const UI:String = "ui";

		public function addAttribute(xmlName:String, attrib:String):void
		{
			switch(xmlName)
			{
				case "fontfamily":
					this.fontFamily = DataUtils.getString(attrib);
					break;
				case "align":
					this.alignment = DataUtils.getString(attrib);
					break;
				case "size":
					this.size = DataUtils.getNumber(attrib);
					break;
				case "color":
					this.color = DataUtils.getUint(attrib.replace("#", "0x")); // replace # with 0x if its written that way
					break;
				case "bold":
					this.bold = DataUtils.getBoolean(attrib);
					break;
				case "italic":
					this.italic = DataUtils.getBoolean(attrib);
					break;
				case "underline":
					this.underline = DataUtils.getBoolean(attrib);
					break;
				case "leading":
					this.leading = DataUtils.getNumber(attrib);
					break;
				case "marginleft":
					this.marginLeft = DataUtils.getNumber(attrib);
					break;
				case "marginright":
					this.marginRight = DataUtils.getNumber(attrib);
					break;
				case "indent":
					this.indent = DataUtils.getNumber(attrib);
					break;
				case "letterspacing":
					this.letterSpacing = DataUtils.getNumber(attrib);
					break;
				case "verticalalign":
					this.verticalAlign = DataUtils.getBoolean(attrib);
					break;
				case "shadow":
					this.hasShadow = true;
					break;
				case "y":
					this.yPos = DataUtils.getNumber(attrib);
					break;
			}
		}
	}
}
