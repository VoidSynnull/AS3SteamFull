package game.data.text
{
	import flash.text.TextFormat;
	
	import game.data.ConditionalData;
	import game.data.display.EffectData;
	import game.util.DataUtils;

	public class TextData
	{
		public function TextData( xml:XML = null ):void
		{
			if( xml )
			{
				parse(xml);
			}
		}

		public function parse( xml:XML ):void
		{
			value = xml.value;
			size = xml.size;

			if (xml.@id)
			{
				id = xml.@id;
			}
			if ( xml.hasOwnProperty("y") )
			{
				this.yPos = DataUtils.getNumber( xml.y );
			}
			if ( xml.hasOwnProperty("x") )
			{
				this.xPos = DataUtils.getNumber( xml.x );
			}
			if ( xml.hasOwnProperty("width") )
			{
				this.width = DataUtils.getNumber( xml.width );
			}
			if ( xml.hasOwnProperty("height") )
			{
				this.height = DataUtils.getNumber( xml.height );
			}
			if ( xml.hasOwnProperty("textColor") )
			{
				this.textColor = xml.textColor;
			}
			if ( xml.hasOwnProperty("size") )
			{
				this.size = DataUtils.getNumber( xml.size );
			}
			if( xml.hasOwnProperty("styleFamily") )
			{
				this.styleFamily = DataUtils.getString( xml.styleFamily );
			}
			if( xml.hasOwnProperty("styleId") )
			{
				this.styleId = DataUtils.getString( xml.styleId );
			}
			if( xml.hasOwnProperty("effect") )
			{
				this.effectData = new EffectData( XML(xml.effect) );
			}
			if( xml.hasOwnProperty("conditional") )
			{
				this.conditional = new ConditionalData( XML(xml.conditional) );
			}
			if( xml.hasOwnProperty("web") )
			{
				this.web = DataUtils.getString( xml.web );
			}
			if( xml.hasOwnProperty("mobile") )
			{
				this.mobile = DataUtils.getString( xml.mobile );
			}
		}

		public function duplicate():TextData
		{
			var data:TextData = new TextData();
			data.id = id;
			data.value = value;
			data.web = web;
			data.mobile = mobile;
			data.styleFamily = styleFamily;
			data.styleId = styleId;
			data.format = format;
			data.size = size;
			data.width = width;
			data.height = height;
			data.textColor = textColor;
			data.xPos = xPos;
			data.yPos = yPos;
			data.effectData = effectData.duplicate();
			data.conditional = conditional.duplicate();
			return data;
		}

		public var id:String;			// id
		public var value:String;		// string that will be displayed
		public var web:String;			// string displayed on mobile
		public var mobile:String;		// string displayed on web
		public var styleFamily:String;
		public var styleId:String;
		public var format:TextFormat;
		public var size:Number;
		public var width:Number;
		public var textColor:uint;
		public var height:Number;
		public var xPos:Number = NaN;
		public var yPos:Number = NaN;	// if x is not specified, defaults to centering based on text width
		public var effectData : EffectData;
		public var conditional:ConditionalData;
	}
}
