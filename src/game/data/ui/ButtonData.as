package game.data.ui
{


	import flash.geom.Point;
	import flash.text.TextFormat;

	import game.data.display.EffectData;
	import game.util.DataUtils;

	/**
	 * ...
	 * @author Bard
	 */
	public class ButtonData
	{
		public function ButtonData( xml:XML=null )
		{
			this.position = new Point();

			if(xml != null)
			{
				parseXML(xml);
			}
		}

		public static function create( value:*, labelText:String = "", unitWidth:int = 1, unitHeight:int = 1 ):ButtonData
		{
			var buttonData:ButtonData = new ButtonData();

			buttonData.value = value;
			buttonData.labelText = ( labelText == "" ) ? String( value ) : labelText;
			buttonData.unitWidth = unitWidth;
			buttonData.unitHeight = unitHeight;

			return buttonData;
		}

		protected function parseXML(xml:XML):void
		{
			this.id = DataUtils.getString( xml.attribute("id") );

			if ( xml.hasOwnProperty("x") )
			{
				this.position.x = DataUtils.getNumber( xml.x );
			}
			if ( xml.hasOwnProperty("y") )
			{
				this.position.y = DataUtils.getNumber( xml.y );
			}
			if ( xml.hasOwnProperty("label") )
			{
				this.labelText = DataUtils.getString( xml.label );
			}
			if( xml.hasOwnProperty("styleFamily") )
			{
				this.styleFamily = DataUtils.getString( xml.styleFamily );
			}
			if( xml.hasOwnProperty("styleId") )
			{
				this.styleId = DataUtils.getString( xml.styleId );
			}
			if ( xml.hasOwnProperty("asset") )
			{
				this.assetPath = DataUtils.getString( xml.asset );
			}
			if( xml.hasOwnProperty("effect") )
			{
				this.effectData = new EffectData( XML(xml.effect) );
			}

		}

		public var id:String;
		public var assetPath:String;
		public var effectData : EffectData;
		public var position:Point;
		public var styleFamily:String;
		public var styleId:String;
		public var value:*;						// assign the button a value that can be accessed and used differently

		// for button labels
		public var labelAsset:String;			// TODO :: Not sure what this is for, if necessary?
		public var labelText:String;
		public var textFormat:TextFormat;		// if not defined will use default

		// grid info (might want this in an extended data class)
		public var row:int;
		public var column:int;
		public var unitWidth:int = 1;
		public var unitHeight:int = 1;

		public var active:Boolean = true;
		public var state:String = STATE_UP;
		public static const STATE_UP:String 	= "up";
		public static const STATE_OVER:String 	= "over";
		public static const STATE_DOWN:String 	= "down";
	}
}
